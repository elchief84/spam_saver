# Call Guard — Test Plan

**Document ID:** CG-TP-001
**Version:** 0.1.0
**Status:** Draft
**Service:** `call-guard`
**Last Updated:** 2026-10-10
**Trace Parents:** CG-SRS-001 · CG-RSK-001 · CG-UC-001

---

## Document Control

| Role | Name | Date | Signature |
|---|---|---|---|
| Author | Onofrio (TA) | 2026-10-10 | Onofrio |
| Reviewer | — | — | — |
| Approver (QA/RA) | — | — | — |

### Change Log

| Version | Date | Author | Summary of Change |
|---|---|---|---|
| 0.1.0 | 2026-10-10 | Onofrio (TA) | Initial draft — piano di test compilato per Call Guard da CG-SRS-001 e CG-RSK-001 |

---

## 1. Scope & Objectives

Questo Test Plan definisce strategia, livelli, casi di test e criteri di pass/fail per **Call Guard**, app Android-only (modulo nativo Kotlin `CallScreeningService` + ruolo `ROLE_CALL_SCREENING`, Android 10+; UI Flutter + platform channel; persistenza solo on-device). Copre la verifica di tutti i 38 requisiti di CG-SRS-001 e di tutti i controlli di mitigazione di CG-RSK-001 (RSK-101…RSK-109).

**Testing objectives:**
- Verificare che tutti i requisiti SRS-101…SRS-1005 siano soddisfatti dall'implementazione.
- Verificare che i controlli di mitigazione RSK-101…RSK-109 siano operativi e osservabili.
- Verificare che il servizio fallisca in modo sicuro (fail-open sulle chiamate, fail-explicit sulla UI) in tutti gli unhappy path documentati.
- Verificare che nessun PII (numeri, nomi, corpi SMS) compaia nei log e che nessun dato lasci il dispositivo.
- Verificare che whitelist/blacklist non perdano mai decisioni e che ogni decisione sia effettiva dalla chiamata successiva (RF-10).
- Verificare che l'invio SMS sia esattamente-uno per evento, mai verso target non composti, con default entro 1 segmento GSM-7.

> **Nota sulle specificità implementative:** la SRS è implementation-agnostic. Questo Test Plan riporta intenzionalmente dettagli esecutivi — nomi di classi/metodi (`CallScreeningService.onScreenCall`, `SmsManager.sendTextMessage`), route UI Flutter (`/history`, `/triage`, `/lists`, `/settings/sms-text`), nomi di tabelle Room (`rejected_calls`, `allowlist`, `blocklist`, `prefs`) — perché i test richiedono criteri precisi ed eseguibili. Tali dettagli saranno consolidati in CG-ARCH-001/CG-SDS-001; in caso di conflitto prevale la SRS.

**Out of scope:**
- Backend/cloud, sincronizzazione multi-dispositivo (fuori perimetro da brief).
- Chiamate in uscita.
- iOS e Android < 10 (solo verifica del messaggio di incompatibilità, SRS-1005).
- Componenti di rete operatore/carrier oltre il comportamento osservabile (segnale, credito): coperti solo come stimoli/fault injection.
- Penetration test di piattaforma Android OS / Play Store review process (verificata solo la readiness documentale, RSK-105).

---

## 2. Test Levels

| Level | Tool / Framework | Scope |
|---|---|---|
| **Unit (UT)** | JUnit5 + MockK (Kotlin); `flutter test` (Dart, logica pura: normalizzazione, precedenza, validazione) | Decision function di screening, normalizzazione E.164/nazionale, validazione testo SMS, mutua esclusione liste — nessun I/O |
| **Integration (IT)** | Robolectric + AndroidX Test (JVM); Room in-memory; `FakeSmsManager`; `FakeContactsProvider`; `FakeCallScreeningCall` | Modulo nativo + repository Room + platform channel; stati invio SMS; CRUD liste; persistenza prefs |
| **End-to-End / Manual (E2E)** | `integration_test` Flutter + Espresso; device fisici + emulatori (API 29–35); 2 SIM reali dove indicato | Intercettazione prima dello squillo, rifiuto/pass reale, invio SMS reale su rete di test, triage all'apertura, usabilità CTA |
| **Performance (PERF)** | Misurazione on-device (`SystemClock.elapsedRealtime`, `Trace`) | Decisione `onScreenCall` entro timeout di piattaforma; nessun I/O di rete nel path |
| **Security (SEC)** | Ispezione statica (lint/grep), cattura traffico (proxy/emulatore senza rete), review manifest/provider | Nessuna trasmissione off-device, nessuno storage esportato, nessun backup in chiaro |
| **Compliance (COMP)** | Assert automatici + ispezione log (logcat, file log, crash report) | Assenza PII nei log, informativa privacy, cancellazione esplicita, ritenzione locale |
| **Compatibility (CMPT)** | Matrice emulatori + device fisici (Pixel + 1 OEM con battery-optimizer aggressivo) | Android 10–15, revoca ruolo/permessi, reboot/update, dual-SIM best-effort |

Strategia: UT per tutta la logica decisionale (precedenza, normalizzazione, validazione); IT per persistenza e stati; E2E/manuale obbligatorio per tutto ciò che tocca telefonia/SMS reali (non mockabile con fedeltà sufficiente). Nessun test automatico deve inviare SMS a numeri reali fuori dalla numerazione di test dedicata.

---

## 3. Test Environment

| Component | Configuration |
|---|---|
| **Runtime** | Android 10 (API 29) … Android 15 (API 35); Kotlin + Flutter stabile corrente; Room per `rejected_calls` / `allowlist` / `blocklist`; `SharedPreferences`/DataStore per testo SMS e flag blacklist |
| **Device matrix** | Minimo: 1 Pixel (riferimento AOSP) + 1 device OEM con ottimizzazione batteria aggressiva; emulatori API 29, 31, 33, 35; 1 device dual-SIM per AMB-05 best-effort |
| **Telefonia/SMS** | Numeri di test dedicati (2 SIM di laboratorio); SIM con credito assente per fault injection; modalità aereo per test offline; nessun SMS verso numerazioni reali di terzi |
| **Stub nativi (UT/IT)** | `FakeCallScreeningCall` (numero visibile / hidden / vuoto / short code / alfanumerico); `FakeContactsProvider`; `FakeSmsManager` (success / `RESULT_ERROR_NO_SERVICE` / `RESULT_ERROR_NULL_PDU`); Room in-memory; orologio fake per ordinamenti |
| **Contatti fixture** | Rubrica di test: `+39 333 000 0001` (contatto noto), `+39 333 000 0002` (noto + in blacklist per AMB-04), short code `40400`, sender alfanumerico `BANCA`, numero hidden (`PRESENTATION_RESTRICTED`) |
| **Liste fixture** | Whitelist: `+39 333 000 0010`; blacklist: `+39 333 000 0020`; sconosciuto: `+39 333 000 0030` |
| **Log capture** | `adb logcat` completo + file log app + output `flutter test`/`connectedAndroidTest`; dataset PII-canarino (numeri fixture) cercato negli output |
| **Network capture** | Proxy/emulatore con logging DNS/HTTP durante E2E per dimostrare zero-egress (SRS-1002); run dedicato con rete disabilitata per SRS-1001 |

Dati di test: usare esclusivamente le numerazioni fixture sopra. Vietato inserire numeri personali reali nei test.

---

## 4. Test Cases

### 4.1 Configurazione e bootstrap

#### TP-101 — Primo avvio pre-popola il default SMS
**Type:** Integration
**SRS:** SRS-101
**Description:** Installazione pulita (storage cancellato). Avviare l'app e aprire `/settings/sms-text`. Verificare il campo precompilato.
**Expected Result:** Il campo contiene esattamente `La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione.`; conteggio segmenti = 1 GSM-7.
**Pass Criteria:** Testo identico al default carattere-per-carattere; mai vuoto al primo avvio.

#### TP-102 — Testo SMS personalizzato persiste a kill/riavvio/update
**Type:** Integration
**SRS:** SRS-102
**Risk:** RSK-106
**Description:** Modificare il testo in `TESTO-CUSTOM-102`, kill del processo + reboot emulato (ricreazione Activity/DB), quindi simulare una chiamata rifiutata e ispezionare il payload passato a `FakeSmsManager`.
**Expected Result:** Dopo il reboot il campo mostra `TESTO-CUSTOM-102`; l'SMS simulato usa `TESTO-CUSTOM-102`.
**Pass Criteria:** Nessun ritorno al default; payload SMS = testo persistito.

#### TP-103 — Flag "Invia SMS ai blacklist" default OFF e persistito
**Type:** Unit + Integration
**SRS:** SRS-103
**Risk:** RSK-105, RSK-107
**Description:** Su installazione pulita leggere il flag (default), impostarlo a true, kill + riavvio, rileggerlo; ripeterlo rimettendolo a false.
**Expected Result:** Default `false`; ogni modifica sopravvive al riavvio.
**Pass Criteria:** Default false dimostrato su install pulita; persistenza in entrambe le direzioni.

---

### 4.2 Contesto piattaforma, ruoli e permessi

#### TP-201 — Screening solo nel nativo Kotlin, mai in Flutter
**Type:** Integration (statica + runtime)
**SRS:** SRS-201
**Description:** (a) Ispezione statica: nessun import `telecom`/`CallScreeningService` nel codice Dart; (b) runtime: disabilitare il channel Flutter e verificare che la decisione nativa avvenga comunque su `FakeCallScreeningCall` sconosciuto.
**Expected Result:** (a) Zero riferimenti nativi in Dart; (b) rifiuto nativo senza Flutter attivo.
**Pass Criteria:** Entrambe le condizioni vere; documentato il percorso `CallScreeningService.onScreenCall` come unico decisore.

#### TP-202 — Ruolo mancante: stato bloccante con azione singola
**Type:** E2E (manuale)
**SRS:** SRS-202
**Risk:** RSK-102
**Description:** Revocare `ROLE_CALL_SCREENING` (o non assegnarlo). Aprire l'app. Tentare di attivare la protezione.
**Expected Result:** Banner/stato `Protezione non attiva — tocca per assegnare il ruolo`; un solo pulsante apre la system role request; nessuna dicitura che dichiara protezione attiva; le chiamate passano normalmente.
**Pass Criteria:** Stato bloccante visibile; deep-link apre le impostazioni di sistema; nessun rifiuto eseguito senza ruolo.

#### TP-203 — Permessi negati: feature-gate con messaggio esplicito
**Type:** Integration + E2E
**SRS:** SRS-203
**Risk:** RSK-105
**Description:** Negare singolarmente `READ_CONTACTS`, poi `SEND_SMS`, poi `READ_SMS`/`RECEIVE_SMS`. Per ogni caso verificare messaggio e degrado: (a) senza `READ_CONTACTS` nessun confronto rubrica; (b) senza `SEND_SMS` nessun invio; (c) senza SMS-read la vista triage mostra `accesso SMS mancante`.
**Expected Result:** Tre messaggi distinti con azione correttiva (apri impostazioni); nessuna eccezione non gestita; nessuna pretesa di funzionamento della feature disabilitata.
**Pass Criteria:** Ogni feature dipendente è disabilitata con messaggio dedicato; log senza PII.

---

### 4.3 Screening e rifiuto chiamate

#### TP-301 — Intercettazione prima dello squillo entro il timeout
**Type:** Performance (on-device)
**SRS:** SRS-301
**Risk:** RSK-102
**Description:** Su device fisico, generare 20 chiamate da numero sconosciuto fixture con rubrica popolata (10k contatti sintetici) e liste popolate (1k entry). Misurare il tempo `onScreenCall → decisione`.
**Expected Result:** Nessuno squillo udibile; decisione sempre emessa; `p99 < timeout di piattaforma` con margine (target interno < 500 ms); nessuna chiamata di rete nel path (verifica con rete disabilitata in 5/20 run).
**Pass Criteria:** 20/20 decisioni entro timeout; 0 squilli per sconosciuti; 0 accessi rete osservati.

#### TP-302 — Rifiuto sse visibile E non in rubrica E non in whitelist (con ruolo)
**Type:** Unit + Integration
**SRS:** SRS-302
**Risk:** RSK-102
**Description:** Matrice parametrica sulla decision function: {visibile sconosciuto / in rubrica / in whitelist / hidden / vuoto} × {ruolo sì/no}. Eseguire su `FakeCallScreeningCall`.
**Expected Result:** Rifiuto solo per (visibile, non rubrica, non whitelist, ruolo sì). Tutti gli altri passano.
**Pass Criteria:** 10/10 combinazioni conformi; nessun rifiuto senza ruolo.

#### TP-303 — Contatti passano senza log né SMS
**Type:** Integration
**SRS:** SRS-303
**Risk:** RSK-101
**Description:** Chiamata da `+39 333 000 0001` (in rubrica). Verificare esito, tabella `rejected_calls`, chiamate a `FakeSmsManager`.
**Expected Result:** Chiamata passa; zero nuove righe in `rejected_calls`; zero invii SMS.
**Pass Criteria:** Nessuna registrazione e nessun SMS per contatti.

#### TP-304 — Numeri hidden/vuoti passano, mai SMS
**Type:** Unit + Integration
**SRS:** SRS-304
**Description:** Chiamate con `PRESENTATION_RESTRICTED`, `PRESENTATION_UNKNOWN`, numero vuoto/nullo. Verificare decisione e `FakeSmsManager`.
**Expected Result:** Tutte passano; nessun tentativo di invio SMS; nessuna riga in cronologia come "rifiutata".
**Pass Criteria:** 4/4 pass-through; zero SMS tentati.

#### TP-305 — Mai SMS a short code / alfanumerici / non composti
**Type:** Unit
**SRS:** SRS-305
**Risk:** RSK-107
**Description:** Validare `isSmsDialable()`: `40400`, `BANCA`, `+39 ABC`, stringa vuota, `+393330000030` (valido). Per i non composti simulare comunque un rifiuto e verificare che l'invio sia inibito.
**Expected Result:** Solo `+393330000030` giudicato componibile; per gli altri `skipped/non-dialable`, nessun invio.
**Pass Criteria:** Classificazione corretta su tutti i 5 input; zero invii verso non composti.

#### TP-306 — Blacklist rifiuta sempre, anche se in rubrica
**Type:** Unit + Integration
**SRS:** SRS-306, SRS-703
**Description:** Chiamata da `+39 333 000 0002` (in rubrica E in blacklist). Verificare decisione.
**Expected Result:** Rifiuto (`disconnect+s silence`); origine decisione = blacklist.
**Pass Criteria:** Blacklist prevale su rubrica; comportamento SMS secondo SRS-502 (vedi TP-502).

#### TP-307 — Decisione effettiva dalla chiamata successiva, senza restart
**Type:** Integration
**SRS:** SRS-307
**Description:** Chiamata 1 da sconosciuto → rifiutata. Classificare il numero in whitelist via repository. Chiamata 2 dallo stesso numero senza restart → deve passare. Spostarlo in blacklist. Chiamata 3 → deve essere rifiutata.
**Expected Result:** Sequenza osservata reject → pass → reject senza restart.
**Pass Criteria:** Comportamento aggiornato immediatamente a ogni mossa; nessuna cache stale.

---

### 4.4 Registrazione tentativi

#### TP-401 — Un record per rifiuto con tutti i campi
**Type:** Integration
**SRS:** SRS-401
**Risk:** RSK-106
**Description:** Rifiutare 2 chiamate dallo stesso sconosciuto a distanza di 60 s (orologio fake). Ispezionare `rejected_calls`.
**Expected Result:** 2 righe distinte con: numero normalizzato, timestamp corretto, `outcome=rejected`, `sms_status ∈ {sent, failed, skipped:<reason>}`, `notes=''`, origine decisione.
**Pass Criteria:** Nessuna aggregazione/sovrascrittura; tutti i campi presenti; note vuote di default.

#### TP-402 — Stato SMS aggiornato a invio completato/fallito
**Type:** Integration
**SRS:** SRS-402
**Description:** (a) Rifiuto con `FakeSmsManager=success`; (b) rifiuto con `FakeSmsManager=RESULT_ERROR_NO_SERVICE`. Verificare `sms_status` e assenza del corpo messaggio nel record oltre il riferimento al template.
**Expected Result:** (a) `sent`; (b) `failed/no-service` con reason machine-readable; mai corpo SMS duplicato nel record.
**Pass Criteria:** Transizione di stato corretta in entrambi i casi; reason registrato senza PII aggiuntiva.

#### TP-403 — Cronologia persiste e ordina discendente
**Type:** Integration
**SRS:** SRS-403
**Risk:** RSK-106
**Description:** Inserire 3 record con timestamp T1<T2<T3>. Kill + riavvio (Room persistente su disco, non in-memory). Aprire `/history`.
**Expected Result:** 3 record presenti dopo riavvio in ordine T3,T2,T1.
**Pass Criteria:** Zero perdite; ordinamento data/ora discendente.

---

### 4.5 SMS automatico di risposta

#### TP-501 — Esattamente un SMS per rifiuto (idempotenza)
**Type:** Integration
**SRS:** SRS-501
**Risk:** RSK-107
**Description:** Rifiuto singolo con doppio evento di screening sullo stesso id (retry di piattaforma simulato). Contare le chiamate a `FakeSmsManager`.
**Expected Result:** 1 solo invio con testo persistito; secondo evento marcato `duplicate-suppressed`, nessun secondo SMS.
**Pass Criteria:** Conteggio invii = 1; chiave idempotenza = id evento.

#### TP-502 — Skip SMS per blacklist quando il flag è OFF (default)
**Type:** Integration
**SRS:** SRS-502, SRS-103
**Description:** Chiamata da numero blacklist con flag=false, poi con flag=true.
**Expected Result:** flag=false → nessun invio, `sms_status=skipped/blacklisted`; flag=true → 1 invio.
**Pass Criteria:** Default OFF dimostrato; toggle rispettato; stato registrato correttamente.

#### TP-503 — Editor testo SMS: validazione non-vuoto e limite
**Type:** Unit + E2E (UI)
**SRS:** SRS-503
**Description:** Tentare salvataggi: vuoto, solo spazi, 1 carattere, testo oltre il limite dichiarato in-app (es. > 480 caratteri), testo valido. Verificare errore esplicito e conservazione del testo precedente nei casi invalidi.
**Expected Result:** Vuoto/spazi/oltre-limite rifiutati con messaggio di campo; valido salvato e usato dall'invio successivo; contatore segmenti visibile.
**Pass Criteria:** Nessun salvataggio vuoto o oltre-limite; testo precedente intatto dopo rifiuti.

---

### 4.6 Intercettazione SMS e classificazione rapida

#### TP-601 — All'apertura: vista triage solo da numeri rifiutati non classificati
**Type:** Integration + E2E
**SRS:** SRS-601
**Risk:** RSK-105
**Description:** Cronologia con numero A rifiutato; SMS in arrivo da A (corpo `Sono il dott. Rossi`), da B mai rifiutato, da C già in whitelist. Aprire l'app (foreground).
**Expected Result:** Vista dedicata mostra solo A con numero, data/ora, corpo, record chiamata collegato; B mostrato al più come `non collegato` senza CTA distruttive; C non in coda di classificazione.
**Pass Criteria:** Filtro corretto; collegamento 1:1 chiamata→SMS; nessun background claim oltre i permessi dichiarati.

#### TP-602 — Esattamente due CTA primarie per SMS non classificato
**Type:** E2E (Espresso)
**SRS:** SRS-602
**Description:** Aprire la vista triage con 1 SMS pendente. Ispezionare la gerarchia UI senza aprire menu.
**Expected Result:** Bottoni `Accetta (whitelist)` e `Rifiuta (blacklist)` entrambi visibili e abilitati senza navigazione annidata.
**Pass Criteria:** Label esatte; nessuna CTA terza primaria; accessibilità (content-description) presente.

#### TP-603 — Accetta → whitelist con source e timestamp, pendenza rimossa
**Type:** Integration
**SRS:** SRS-603
**Description:** Toccare `Accetta (whitelist)` sull'SMS di A. Ispezionare `allowlist` e coda pendenze; richiamare da A.
**Expected Result:** Entry in whitelist con `source=sms-classification` + timestamp; pendenza rimossa; richiamata passa (SRS-307).
**Pass Criteria:** Tutte e tre le condizioni vere.

#### TP-604 — Rifiuta → blacklist con source e timestamp, pendenza rimossa
**Type:** Integration
**SRS:** SRS-604
**Description:** Simmetrico a TP-603 sul numero D: toccare `Rifiuta (blacklist)`.
**Expected Result:** Entry in blacklist con `source=sms-classification` + timestamp; pendenza rimossa; richiamata rifiutata.
**Pass Criteria:** Tutte e tre le condizioni vere.

---

### 4.7 Whitelist, blacklist e profilo numero

#### TP-701 — CRUD liste + profilo (nome, note, categoria, data)
**Type:** Integration
**SRS:** SRS-701
**Description:** Aggiunta manuale di `+39 333 000 0099` in whitelist con nome/note/categoria; modifica note+categoria; rimozione; re-inserimento in blacklist. Verificare unicità su numero normalizzato (`+39 3330000099` vs `333 000 0099` = stessa entry).
**Expected Result:** CRUD completi; normalizzazione unica; `date-added`/`last-modified` registrati; `source=manual`.
**Pass Criteria:** Nessuna voce parziale; formati equivalenti collassano in un'unica entry.

#### TP-702 — Mutua esclusione whitelist/blacklist con move registrato
**Type:** Unit + Integration
**SRS:** SRS-702
**Description:** Numero in whitelist; aggiungerlo alla blacklist (con conferma UI in E2E). Verificare appartenenza.
**Expected Result:** Presente solo in blacklist; rimozione automatica dalla whitelist; move registrato (timestamp + source).
**Pass Criteria:** Mai doppia appartenenza; nessuna duplicazione.

#### TP-703 — Precedenza blacklist > pass(contatti/whitelist) > reject
**Type:** Unit (parametrica)
**SRS:** SRS-703, SRS-306
**Description:** 6 combinazioni: blacklist+rubrica, blacklist+whitelist, rubrica sola, whitelist sola, sconosciuto, anonimo. Verificare decisione attesa.
**Expected Result:** Rifiuto per i 2 casi blacklist; pass per rubrica/whitelist/anonimo; reject per sconosciuto.
**Pass Criteria:** 6/6 conformi alla precedenza dichiarata.

#### TP-704 — Promozione diretta dalla cronologia con singola azione
**Type:** E2E
**SRS:** SRS-704
**Description:** Da `/history`, su voce rifiutata senza SMS di risposta, toccare una volta `whitelist` (su fixture E) e una volta `blacklist` (su fixture F). Verificare liste e comportamento successivo.
**Expected Result:** 1 tap per scelta; E in whitelist (passa), F in blacklist (rifiutato).
**Pass Criteria:** Nessun passaggio intermedio obbligatorio; decisioni immediate.

#### TP-705 — Liste persistenti a restart e update
**Type:** Integration
**SRS:** SRS-705
**Risk:** RSK-106
**Description:** Popolare whitelist/blacklist con profili completi; kill + reboot; simulare upgrade schema Room (migrazione). Verificare contenuto.
**Expected Result:** Liste integre dopo reboot e dopo migrazione; profili (nome/note/categoria/date/source) intatti.
**Pass Criteria:** Zero perdite; migrazione senza fallback distruttivo.

---

### 4.8 Ricerca, liste e dettaglio

#### TP-801 — Tre liste con filtro per sottostringa e sort discendente
**Type:** Integration + E2E (UI)
**SRS:** SRS-801
**Description:** Popolare cronologia/whitelist/blacklist con 5 entry ciascuna. Per ogni lista: filtrare per sottostringa numerica (`000 001`), verificare ordinamento, tentare filtro su campo non dichiarato (deve essere ignorato o rifiutato senza crash).
**Expected Result:** Filtro numero-sottostringa corretto; ordinamento data discendente; filtro su campo inesistente senza crash né risultati spuri.
**Pass Criteria:** Comportamento identico sulle 3 liste; leggibilità (nessun troncamento del numero).

#### TP-802 — Dettaglio profilo: storico collegato + edit nome/note/categoria
**Type:** E2E
**SRS:** SRS-802
**Description:** Aprire il dettaglio di un numero con 2 chiamate rifiutate + 1 SMS. Modificare nome, note, categoria. Riaprire dopo restart.
**Expected Result:** Vista con membership, storico collegato, nome/note/categoria/date; modifiche salvate e persistite; numero non editabile come chiave (solo profilo).
**Pass Criteria:** Edit limitato ai 3 campi; storico completo; persistenza verificata.

---

### 4.9 Error handling

#### TP-901 — Errori con azione correttiva, senza PII extra né stack trace
**Type:** E2E (UI) + Compliance
**SRS:** SRS-901
**Risk:** RSK-103
**Description:** Provocare: ruolo mancante, `SEND_SMS` negato con invio atteso, SMS fallito per assenza rete. Per ogni caso catturare screenshot + logcat.
**Expected Result:** Messaggio leggibile + azione (`Apri impostazioni` / `Riprova`); nessun numero completo fuori dal contesto lista già nota, nessun corpo SMS, nessuno stack trace visibile.
**Pass Criteria:** 3/3 messaggi con azione; zero PII aggiuntiva nelle superfici di errore.

#### TP-902 — SMS fallito: un solo retry manuale, mai auto-retry in background
**Type:** Integration
**SRS:** SRS-902
**Risk:** RSK-107
**Description:** Rifiuto con `FakeSmsManager=fail`. Tentare retry manuale dalla voce cronologia (1° retry success → `sent`; in run separato 1° retry fail → resta `failed`, nessun 2° automatico). Monitorare invii in background per 5 min.
**Expected Result:** Al massimo 1 retry manuale per record; zero invii background spontanei; conteggio totale ≤ 2 (originale + 1 retry).
**Pass Criteria:** Nessun auto-retry; nessun invio multiplo.

---

### 4.10 Piattaforma / Cross-cutting (NFR)

#### TP-1001 — Screening solo on-device, nessuna chiamata di rete
**Type:** Security + Performance
**SRS:** SRS-1001
**Risk:** RSK-102
**Description:** Eseguire 10 screening con rete disabilitata (aereo) e 10 con proxy di cattura attivo. Verificare decisioni e traffico.
**Expected Result:** 20/20 decisioni corrette senza rete; zero pacchetti DNS/HTTP generati dall'app durante `onScreenCall`.
**Pass Criteria:** Parità di comportamento on/offline; zero-egress nel path dimostrato dai log proxy.

#### TP-1002 — Nessun dato lascia il dispositivo
**Type:** Security
**SRS:** SRS-1002
**Risk:** RSK-103, RSK-104
**Description:** E2E completo (rifiuto + SMS + triage + CRUD) con cattura traffico + ispezione manifest (`INTERNET` assente o ingiustificata → fail), nessun SDK analytics/crash con PII, backup `allowBackup=false` o cifrato.
**Expected Result:** Zero trasmissioni di numeri/corpi SMS; manifest senza provider esportati; nessun endpoint remoto configurato.
**Pass Criteria:** Traffico PII = 0 byte; checklist manifest/backup verde.

#### TP-1003 — Nessun PII nei log
**Type:** Compliance (automatico)
**SRS:** SRS-1003
**Risk:** RSK-103
**Description:** Eseguire l'intera suite IT+E2E con numeri-canarino fixture. Grep su logcat + file log + report crash: numeri completi, nomi contatto, corpi SMS. Ammessi solo hash troncati o `<redacted>`.
**Expected Result:** Zero match di PII in chiaro; ogni riga diagnostica usa placeholder/hash.
**Pass Criteria:** Suite rossa se un solo canarino appare in chiaro (gate di release).

#### TP-1004 — Degrado graceful: fail-open chiamate, nessun stato parziale
**Type:** Integration
**SRS:** SRS-1004
**Risk:** RSK-102, RSK-104
**Description:** (a) Ruolo revocato a caldo; (b) `SEND_SMS` revocato con rifiuto in corso; (c) storage pieno simulato. Per ogni caso verificare esito chiamata, notifica in-app, integrità DB.
**Expected Result:** (a/b) chiamate passano normalmente + notifica esplicita; (c) errore leggibile senza record fantasma (o record marcato `failed` completo, mai semi-scritto).
**Pass Criteria:** Mai blocco totale; mai stati parziali non marcati; DB integro.

#### TP-1005 — Solo Android 10+: messaggio di incompatibilità sotto API 29
**Type:** Compatibility
**SRS:** SRS-1005
**Description:** Avviare l'app su emulatore API 28. Tentare l'attivazione.
**Expected Result:** Messaggio `Dispositivo non compatibile — richiesta Android 10+`; protezione non attivabile; nessuna chiamata a `CallScreeningService`.
**Pass Criteria:** Blocco esplicito; nessun crash su API 28.

---

### 4.11 Rischi residui mirati (sicurezza funzionale, costi, usabilità)

#### TP-1101 — Falso positivo: noto/whitelist squilla sempre, sconosciuto mai
**Type:** E2E (manuale, gate RSK-101)
**SRS:** SRS-302, SRS-303
**Risk:** RSK-101
**Description:** 10 chiamate di controllo: 5 da numeri in rubrica/whitelist (devono squillare), 5 da sconosciuti (mai squillo, con ruolo attivo). Registrare esiti + cronologia richiamabile in 1 tap.
**Expected Result:** 5/5 pass con squillo; 5/5 reject senza squillo; ogni rifiuto con entry richiamabile e notifica immediata.
**Pass Criteria:** 10/10 conformi; onboarding whitelist-contatti-critici verificato presente.

#### TP-1102 — Niente invii incontrollati: costi e segmenti sotto controllo
**Type:** Integration + E2E (gate RSK-107)
**SRS:** SRS-501, SRS-503
**Risk:** RSK-107
**Description:** (a) 5 rifiuti rapidi dallo stesso numero → 5 SMS (uno per evento distinto), mai di più; (b) default entro 1 segmento GSM-7; (c) editor mostra contatore segmenti; (d) preview + conferma prima del primo invio post-installazione.
**Expected Result:** Rapporto eventi:invii = 1:1; default 1 segmento; conferma iniziale presente.
**Pass Criteria:** Zero doppi invii; zero invii oltre configurazione blacklist.

#### TP-1103 — Errore di classificazione reversibile con undo
**Type:** E2E usabilità (gate RSK-108)
**SRS:** SRS-602, SRS-603, SRS-604
**Risk:** RSK-108
**Description:** 10 casi simulati di triage; misurare tempo mediano e indurre 2 errori (CTA sbagliata). Verificare conferma + undo immediato e spostamento in 2 tap dall'altra lista.
**Expected Result:** Triage mediano < 30 s; tasso errore < 5% atteso; ogni errore annullabile senza perdita di cronologia.
**Pass Criteria:** Undo disponibile e funzionante; label CTA esplicite verificate.

#### TP-1104 — Triage differito dichiarato + notifica con deep-link
**Type:** E2E (gate RSK-109)
**SRS:** SRS-601
**Risk:** RSK-109
**Description:** Rifiuto a schermo spento; verificare notifica locale (`La risposta apparirà qui all'apertura`), badge contatore, deep-link alla vista triage; verificare che onboarding/Store listing dichiarino il limite.
**Expected Result:** Notifica + badge + deep-link funzionanti; limite documentato in-app.
**Pass Criteria:** Collegamento notifica→triage diretto; nessuna attesa di push realtime.

---

### 4.12 Persistenza, OEM e policy (gate di release)

#### TP-1201 — Migrazione e reboot senza perdite (storia + liste + testo)
**Type:** Integration (gate RSK-106)
**SRS:** SRS-102, SRS-403, SRS-705
**Risk:** RSK-106
**Description:** Dataset completo (cronologia + liste + testo custom + flag blacklist). Eseguire: reboot, upgrade versione DB Room, kill durante scrittura (fault injection). Verificare integrità.
**Expected Result:** Dataset identico dopo ogni scenario; scrittura interrotta = transazione rollback, mai mezza riga.
**Pass Criteria:** Zero perdite; versionamento schema esplicito; nessun dato decisionale solo-in-memoria.

#### TP-1202 — OEM aggressivo e revoca a caldo senza stallo suoneria
**Type:** Compatibility + Performance (gate RSK-102)
**SRS:** SRS-301, SRS-1004
**Risk:** RSK-102
**Description:** Su OEM con battery-optimizer: abilitare ottimizzazione, revocare ruolo/permessi a caldo, generare chiamate note e sconosciute. Misurare ritardo suoneria per chiamate legittime.
**Expected Result:** Legittime senza ritardo percepibile; sconosciute fail-open (squillano) quando il ruolo manca; banner `Protezione non attiva` alla riapertura.
**Pass Criteria:** Nessuno stallo; default fail-open documentato rispettato.

#### TP-1203 — Readiness policy Play: declaration + fallback solo-rifiuto
**Type:** Compliance (manuale, gate RSK-105)
**SRS:** SRS-203, SRS-501
**Risk:** RSK-105
**Description:** Checklist: core-functionality declaration (call screening + auto-reply), video demo, informativa in-app, giustificazione `SEND_SMS`/`RECEIVE_SMS`, valutazione alternativa Consent/Retriever API documentata. Poi disabilitare `SEND_SMS`: l'app deve restare utile in modalità solo-rifiuto + notifica.
**Expected Result:** Pacchetto declaration completo; fallback solo-rifiuto funzionante senza SMS.
**Pass Criteria:** Gate verde prima di qualsiasi submit in traccia production; piano B pronto.

---

## 5. Requirements Coverage Matrix

Ogni SRS di CG-SRS-001 è coperto da almeno un test case. Nessun gap.

| SRS ID | Requirement Summary | Mapped Test Case(s) | Coverage |
|---|---|---|---|
| SRS-101 | Default SMS precompilato | TP-101, TP-1102 | OK |
| SRS-102 | Persistenza testo SMS | TP-102, TP-1201 | OK |
| SRS-103 | Toggle SMS blacklist default OFF | TP-103, TP-502 | OK |
| SRS-201 | Screening nel nativo Kotlin, Android 10+ | TP-201 | OK |
| SRS-202 | Stato bloccante se ruolo mancante | TP-202, TP-1004 | OK |
| SRS-203 | Permessi sensibili con feature-gate | TP-203, TP-1203 | OK |
| SRS-301 | Intercettazione prima dello squillo entro timeout | TP-301, TP-1202 | OK |
| SRS-302 | Rifiuto sse visibile e non rubrica/whitelist | TP-302, TP-1101 | OK |
| SRS-303 | Contatti passano senza log/SMS | TP-303, TP-1101 | OK |
| SRS-304 | Anonimi passano, mai SMS | TP-304 | OK |
| SRS-305 | Mai SMS a short code / non composti | TP-305 | OK |
| SRS-306 | Blacklist prevale sempre | TP-306, TP-703 | OK |
| SRS-307 | Decisioni effettive dalla chiamata successiva | TP-307, TP-603, TP-604, TP-704 | OK |
| SRS-401 | Record per chiamata rifiutata | TP-401 | OK |
| SRS-402 | Stato invio SMS nel record | TP-402 | OK |
| SRS-403 | Cronologia persiste, ordinata discendente | TP-403, TP-1201 | OK |
| SRS-501 | Un solo SMS automatico per rifiuto | TP-501, TP-1102 | OK |
| SRS-502 | Skip SMS per blacklist se toggle OFF | TP-502 | OK |
| SRS-503 | Modifica testo SMS validata | TP-503, TP-1102 | OK |
| SRS-601 | Vista SMS in ingresso all'apertura | TP-601, TP-1104 | OK |
| SRS-602 | Due CTA: Accetta / Rifiuta | TP-602, TP-1103 | OK |
| SRS-603 | Accetta → whitelist | TP-603 | OK |
| SRS-604 | Rifiuta → blacklist | TP-604 | OK |
| SRS-701 | CRUD liste + profilo numero | TP-701 | OK |
| SRS-702 | Mutua esclusione whitelist/blacklist | TP-702 | OK |
| SRS-703 | Precedenza blacklist > pass > reject | TP-703, TP-306 | OK |
| SRS-704 | Promozione diretta dalla cronologia | TP-704 | OK |
| SRS-705 | Liste persistenti | TP-705, TP-1201 | OK |
| SRS-801 | Tre liste con filtro e ordinamento | TP-801 | OK |
| SRS-802 | Dettaglio profilo numero modificabile | TP-802 | OK |
| SRS-901 | Errori con azione correttiva, no PII extra | TP-901 | OK |
| SRS-902 | Un solo retry manuale per SMS fallito | TP-902 | OK |
| SRS-1001 | Screening solo on-device, no rete | TP-1001 | OK |
| SRS-1002 | Nessun dato lascia il dispositivo | TP-1002 | OK |
| SRS-1003 | No PII nei log | TP-1003, TP-901 | OK |
| SRS-1004 | Degrado graceful (fail-open chiamate) | TP-1004, TP-1202 | OK |
| SRS-1005 | Solo Android 10+, messaggio se incompatibile | TP-1005 | OK |

---

## 6. Risk Coverage Matrix

Ogni mitigazione di CG-RSK-001 è verificata da almeno un test case.

| RSK ID | Risk Summary | Mapped Test Case(s) | Coverage |
|---|---|---|---|
| RSK-101 | Falso positivo: legittima/urgente rifiutata | TP-1101, TP-303, TP-302 | OK |
| RSK-102 | Screening oltre timeout / ruolo mancante / OEM | TP-301, TP-202, TP-1001, TP-1004, TP-1202 | OK |
| RSK-103 | PII nei log | TP-1003, TP-901, TP-1002 | OK |
| RSK-104 | Accesso non autorizzato allo store locale | TP-1002, TP-1004 | OK |
| RSK-105 | Rigetto Play per permessi SMS restricted | TP-203, TP-103, TP-601, TP-1203 | OK |
| RSK-106 | Perdita persistenza a reboot/update | TP-102, TP-401, TP-403, TP-705, TP-1201 | OK |
| RSK-107 | Invio SMS incontrollato (costi/loop/target) | TP-305, TP-501, TP-502, TP-902, TP-1102 | OK |
| RSK-108 | Misclassification dalla vista triage | TP-602, TP-603, TP-604, TP-1103 | OK |
| RSK-109 | Triage differito (solo all'apertura) | TP-601, TP-1104 | OK |

Gate di release (vincolanti): TP-1003 (zero PII nei log), TP-301/TP-1202 (timeout/ruolo), TP-1201 (persistenza/migrazione), TP-1203 (policy Play), TP-1101 (falso positivo) devono essere verdi prima dell'approvazione. I rischi residui MEDIO RSK-101, RSK-105, RSK-109 restano accettati in ALARP come da CG-RSK-001 e sono monitorati dai KPI post-rilascio (reclami chiamata persa, esito declaration Play, tempo mediano di apertura post-rifiuto).

---

*End of Document — CG-TP-001 v0.1.0*
*Next in package: CG-ARCH-001 — Software Architecture*
