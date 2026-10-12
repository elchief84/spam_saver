# Call Guard — Risk Analysis (ISO 14971)

**Document ID:** CG-RSK-001
**Version:** 0.1.0
**Status:** Draft
**Service:** `call-guard`
**Standard:** ISO 14971:2019 (applicazione proporzionata ad app non-medicale)
**Last Updated:** 2026-10-10
**Trace Parents:** RF-1 · RF-2 · RF-3 · RF-4 · RF-5 · RF-6 · RF-7 · RF-8 · RF-9 · RF-10

---

## Document Control

| Role | Name | Date | Signature |
|---|---|---|---|
| Author | Aldo (PM) | 2026-10-10 | Aldo |
| Reviewer | TBD (Tech Lead) | — | — |
| Approver (QA/RA) | TBD | — | — |

### Change Log

| Version | Date | Author | Summary of Change |
|---|---|---|---|
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft compilato per Call Guard (RF-1…RF-10, vincoli Android 10+ / ROLE_CALL_SCREENING) |

---

## 1. Overview

Call Guard è un'app Android-only che intercetta le chiamate in ingresso prima della suoneria tramite modulo nativo Kotlin (`CallScreeningService`, ruolo `ROLE_CALL_SCREENING`, Android 10+), rifiuta automaticamente i numeri visibili non in rubrica/whitelist (RF-2), registra ogni tentativo (RF-3), invia un SMS automatico configurabile (RF-4, RF-9), non blocca i numeri in whitelist (RF-5), rifiuta sempre i numeri in blacklist (RF-6), e all'apertura mostra gli SMS ricevuti con CTA Accetta/Rifiuta (RF-7). Whitelist/blacklist sono gestibili con profilo modificabile (RF-8) e le decisioni aggiornano subito il comportamento (RF-10). Nessun backend/cloud, persistenza solo locale, nessun dato lascia il dispositivo.

## 2. User needs e contesto d'uso (sintesi)

- Utente proprietario del dispositivo vuole: zero squilli da sconosciuti, traccia consultabile, risposta automatica che chiede identificazione, classificazione rapida alla riapertura.
- Beneficio misurabile: riduzione interruzioni indesiderate, tempo di triage < 30 s per numero, nessuna chiamata nota bloccata.
- Contesto: Android 10–15, OEM eterogenei, ruolo call screening assegnato dall'utente, permessi sensibili `SEND_SMS` / `RECEIVE_SMS` / `READ_PHONE_STATE` / `READ_CONTACTS`.

## 3. Nota di adattamento ISO 14971 (app non-medicale)

La matrice sotto è quella del framework H.Core SaMD e viene mantenuta invariata per coerenza. Call Guard **non è un dispositivo medico**: non ci sono rischi di morte/disabilità diretta. La scala di Severity è quindi interpretata in modo proporzionato:

- Catastrophic (4) = danno grave indiretto (es. mancata ricezione di una chiamata urgente con conseguenze serie) oppure breach GDPR su larga scala / blocco pubblicazione.
- Critical (3) = perdita/divulgazione PII, blocco sistematico di chiamate legittime, rigetto Play Store.
- Marginal (2) = disservizio limitato, costi SMS indebiti, perdita cronologia, errore di classificazione reversibile.
- Negligible (1) = fastidio minore senza perdita di dati.

## 4. Perimetro e non-applicabilità

- **Cross-tenant data leakage: N/A.** Nessun backend, nessun multi-tenant, nessun account: tutti i dati restano nel profilo locale del dispositivo. Il rischio analogo (accesso di altre app ai dati locali) è coperto da RSK-104.
- **Malicious file upload: N/A.** Nessun upload di file, nessun campo file, nessuna WebView con upload in scope.
- **Premature data exposure (clinica): N/A.** Nessun contenuto sanitario; il rischio analogo (screening che lascia squillare / rifiuto prima del consenso) è coperto da RSK-102.
- **iOS: fuori perimetro** per limiti di piattaforma (nessuna intercettazione runtime né invio/lettura SMS automatica).

---

## Evaluation Matrix

| **Probability \ Severity** | **Catastrophic (4)** | **Critical (3)** | **Marginal (2)** | **Negligible (1)** |
|---|---|---|---|---|
| **Frequent (6)** | [ALTO] 24 | [ALTO] 18 | [ALTO] 12 | [MEDIO] 6 |
| **Probable (5)** | [ALTO] 20 | [ALTO] 15 | [MEDIO] 10 | [MEDIO] 5 |
| **Occasional (4)** | [ALTO] 16 | [ALTO] 12 | [MEDIO] 8 | [BASSO] 4 |
| **Remote (3)** | [ALTO] 12 | [MEDIO] 9 | [MEDIO] 6 | [BASSO] 3 |
| **Unlikely (2)** | [MEDIO] 8 | [MEDIO] 6 | [BASSO] 4 | [BASSO] 2 |
| **Unbelievable (1)** | [BASSO] 4 | [BASSO] 3 | [BASSO] 2 | [BASSO] 1 |

**Severity Scale:**
| Level | Label | Description |
|---|---|---|
| 4 | Catastrophic | Risk of death or permanent disability |
| 3 | Critical | Risk of serious consequences that may involve hospitalisation or prolonged hospitalisation |
| 2 | Marginal | Risk of mild consequences that may involve minor care (bandages, minor medications, non-invasive diagnostic investigations) |
| 1 | Negligible | Discomfort to the patient or consequences that do not involve the need for medical and/or nursing care |

**Probability Scale:**
| Level | Label | Description |
|---|---|---|
| 6 | Frequent | Could happen immediately or within a short period |
| 5 | Probable | Likely to happen; could happen several times in 1 or 2 years |
| 4 | Occasional | Is likely to happen; could happen a few times over a period of 2 to 5 years |
| 3 | Remote | Not expected to happen; could happen in a period between 5 and 30 years |
| 2 | Unlikely | It would arouse amazement that the problem would occur |
| 1 | Unbelievable | It would arouse great amazement that the problem would occur |

**Risk Score = Probability × Severity**

**Acceptability:**
| Colour | Region | Score Range | Action Required |
|---|---|---|---|
| [ALTO] Red | Intolerable | ≥ 12 | Risk reduction measures mandatory before release |
| [MEDIO] Yellow | Conditionally Tolerable | 5 – 11 | ALARP review required; benefit–risk comparison; accepted with justification |
| [BASSO] Green | Broadly Tolerable | ≤ 4 | Residual risk acceptable; no further action required |

> **ALARP note:** Conditionally Tolerable risks that cannot be further reduced must be compared against clinical benefit. If benefit exceeds risk, the risk is accepted as tolerable. If risk exceeds benefit, it escalates to Intolerable.
> Residual risk must NOT remain [ALTO] Intolerable. If it does, additional mitigations are required before this document can be approved.

---

## RSK-101

**Category:** Functional Safety — False-positive rejection (legitimate/urgent call blocked)
**Hazard:** Chiamata legittima e potenzialmente urgente trattata come sconosciuta e disconnessa prima della suoneria
**Source of Hazard:** Regola RF-2 troppo aggressiva: numero visibile non in rubrica/whitelist (es. medico, corriere, callback emergenza, nuovo contatto lavorativo) rifiutato senza distinzione di urgenza
**Hazardous Situation:** L'utente non vede né sente la chiamata; se ne accorge solo a posteriori dalla lista (RF-3), con ritardo
**Potential Harm:** Comunicazione urgente persa o ritardata (danno operativo serio; nel caso peggiore conseguenze su salute/sicurezza se callback sanitaria); perdita di opportunità; sfiducia nell'app e disattivazione

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **4 — Occasional** · Score: **12** → [ALTO] **Intolerable**

**Risk Reduction Measures:**
- Precedenza rigorosa: rubrica + whitelist sempre passanti (RF-5); blacklist mai auto-alimentata; solo rifiuto esplicito dell'utente promuove in blacklist (RF-8, RF-10)
- Notifica immediata + entry in cronologia con numero, data/ora, esito e stato SMS (RF-3) per recupero rapido e richiamata in 1 tap
- Onboarding che spiega il trade-off e invita a mettere in whitelist contatti critici (medico, famiglia, lavoro); numeri anonimi/non visibili mai auto-rifiutati senza consenso
- Test di accettazione: numero in rubrica/whitelist squilla sempre; numero sconosciuto squilla mai (quando il ruolo è attivo)

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **2 — Unlikely** · Score: **6** → [MEDIO] **Conditionally Tolerable**

**Benefit–Risk Justification:**
Il beneficio (eliminazione sistematica di spam/chiamate ambigue, traccia completa e richiamata in 1 tap) supera il rischio residuo, ridotto a casi limite (chiamante legittimo da numero mai salvato). Il rischio è reversibile (richiamata immediata) e l'utente è informato in onboarding. Accettato in ALARP; monitoraggio reclami "ho perso una chiamata importante" come KPI post-rilascio.

**Traceability:** RF-1, RF-2, RF-3, RF-5, RF-8

---

## RSK-102

**Category:** Availability — Screening failure / timeout / role missing
**Hazard:** Il servizio di screening non risponde entro il timeout di piattaforma o non è attivo
**Source of Hazard:** Ruolo `ROLE_CALL_SCREENING` non assegnato/revocato, risposta oltre il timeout, OEM/battery-optimizer che uccide il servizio, frammentazione Android 10–15, permessi telefono revocati
**Hazardous Situation:** Due modi di guasto: (a) fail-open — lo spam squilla normalmente; (b) fail-closed/stallo — ritardo suoneria per chiamate legittime; l'utente crede di essere protetto ma non lo è (o viceversa)
**Potential Harm:** Protezione inefficace, spam che passa, ritardo suoneria, percezione di inaffidabilità; nel caso (b) ritardo su chiamate legittime

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **5 — Probable** · Score: **10** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- Gate all'avvio: verifica ruolo + permessi, banner bloccante se screening non attivo con deep-link alle impostazioni di sistema (test RF-1)
- Path nativo minimale e sincrono in `onScreenCall`: solo lookup rubrica/whitelist/blacklist in memoria, nessuna I/O di rete, nessun blocco; default fail-open documentato (meglio uno squillo spam che una legittima persa)
- Test su matrice OEM/API 29–35, test di timeout, test revoca ruolo/permessi; guida "disattiva ottimizzazione batteria per Call Guard"
- Diagnostica senza PII: contatore "screening OK / ruolo mancante / timeout" senza numeri

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **2 — Unlikely** · Score: **4** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-1, RF-2, RF-5, RF-6

---

## RSK-103

**Category:** Privacy — PII Exposure in Logs
**Hazard:** Numeri di telefono (PII) scritti in log generali, crash report o diagnostica
**Source of Hazard:** Log di debug del modulo nativo/channel Flutter che includono numero chiamante, contenuto SMS o nome contatto senza pseudonimizzazione
**Hazardous Situation:** PII accessibile a chiunque legga logcat, bug report condivisi o infrastruttura di logging
**Potential Harm:** Violazione GDPR/privacy, sanzioni, perdita di fiducia; i numeri sono dati personali e non devono mai lasciare il dispositivo

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **4 — Occasional** · Score: **12** → [ALTO] **Intolerable**

**Risk Reduction Measures:**
- Divieto di PII nei log: nei log solo hash troncato o placeholder `<redacted>`; mai numero, nome, contenuto SMS; regola enforced in code review + lint/test che fallisce se un numero di test appare in output log
- Nessun analytics/crash-reporting con PII; se attivo, scrubber + opt-in; nessun invio rete in assoluto (app offline-by-design)
- Informativa privacy in-app: dati solo locali, base giuridica consenso, conservazione locale, cancellazione su rimozione entry/disinstallazione

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **1 — Unbelievable** · Score: **3** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-3, RF-7, RF-8

---

## RSK-104

**Category:** Data Security — Unauthorised Data Access (local store)
**Hazard:** Cronologia chiamate, SMS di risposta, whitelist/blacklist leggibili da altri soggetti oltre all'utente proprietario
**Source of Hazard:** Database/file in storage condiviso, backup automatico non cifrato, `ContentProvider` esportato, schermo triage senza blocco dispositivo, dispositivo condiviso
**Hazardous Situation:** Altra app, backup cloud o persona con accesso fisico legge l'elenco dei numeri, note e categorie
**Potential Harm:** Divulgazione PII e abitudini di contatto; profilazione; violazione GDPR

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **3 — Remote** · Score: **9** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- Storage solo interno app (Room/SQLite + prefs interne), nessun provider esportato, `allowBackup=false` o backup cifrato senza PII in chiaro; nessuna esportazione/condivisione
- Nessuna rete: nessuna sincronizzazione multi-dispositivo (fuori perimetro) → superficie ridotta al dispositivo
- Cancellazione esplicita per entry e "cancella tutto"; disinstallazione rimuove i dati; raccomandazione blocco schermo in onboarding

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **1 — Unbelievable** · Score: **3** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-3, RF-7, RF-8

---

## RSK-105

**Category:** Compliance — Play Store rejection (restricted SMS permissions)
**Hazard:** App rifiutata o rimossa da Google Play per uso di permessi restricted
**Source of Hazard:** `SEND_SMS` e `RECEIVE_SMS` sono permessi restricted: richiedono core-functionality dichiarata e giustificazione; il ruolo call screening + SMS automatico è scrutinato; valutazione d'impatto non fatta
**Hazardous Situation:** Al submit: declaration respinta → impossibile pubblicare/aggiornare; oppure enforcement retroattivo → rimozione dallo Store
**Potential Harm:** Danno business: mancato rilascio, rilavorazione, distribuzione solo via sideload/APK con adozione crollata

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **5 — Probable** · Score: **10** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- Permission-declaration preparata prima dello sviluppo UI: core functionality = "call screening + auto-reply SMS" con video demo, informativa e giustificazione "nessuna alternativa senza SEND_SMS"
- Design con degrado: modalità "solo rifiuto + notifica" senza SMS se permessi negati/revocati o policy rifiutata; flag configurabile per invio su blacklist (RF-6)
- Valutazione alternativa `SMS User Consent / Retriever API` per lettura senza `RECEIVE_SMS` full; richiesta minima di permessi (niente `READ_SMS` bulk se non necessario)
- Gate di release: checklist policy Play + prova su traccia interna prima della production

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **3 — Remote** · Score: **6** → [MEDIO] **Conditionally Tolerable**

**Benefit–Risk Justification:**
L'SMS automatico è il valore differenziante chiesto dal brief (RF-4); senza di esso il prodotto perde metà della proposta. Il rischio residuo è di natura business/processo, non sicurezza utente, ed è gestito con fallback operativo (l'app resta utile anche senza SMS). Accettato in ALARP con owner (PM) e piano B pronto prima del submit.

**Traceability:** RF-4, RF-6, RF-7, RF-9

---

## RSK-106

**Category:** Data Integrity — Persistence loss (history / lists)
**Hazard:** Cronologia, whitelist/blacklist o testo SMS configurato persi al riavvio, aggiornamento o crash
**Source of Hazard:** Scrittura best-effort senza transazione, migrazione DB Room senza test, cancellazione cache/OEM cleaner, salvataggio testo SMS solo in memoria
**Hazardous Situation:** Dopo reboot/update l'utente ritrova liste vuote: spam già classificato torna a comportarsi come sconosciuto, decisioni RF-10 non applicate
**Potential Harm:** Riclassificazione ripetuta, spam che torna a essere rifiutato+SMS (costi/rumore), perdita note/categorie; sfiducia

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **3 — Remote** · Score: **6** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- Persistenza transazionale Room (storia + liste + profilo numero: nome, note, categoria, data aggiunta) + prefs per testo SMS (RF-8, RF-9); scrittura sincrona sul path decisionale, lettura in memoria per screening
- Test di migrazione + test reboot/update; versione schema esplicita; nessun dato solo-in-memoria per decisioni
- Stato invio SMS persistito per entry (inviato/fallito) per evitare reinvii (RF-3)

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **1 — Unbelievable** · Score: **2** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-3, RF-8, RF-9, RF-10

---

## RSK-107

**Category:** Operational — Uncontrolled SMS sending (cost / loops / wrong target)
**Hazard:** Invio SMS multiplo, a target sbagliato o con costi inattesi
**Source of Hazard:** Reinoltro su ogni evento senza idempotenza, invio a blacklist senza consenso (RF-6 ambiguo), testo default >1 segmento, roaming/tariffa a pagamento, retry aggressivo su fallimento invio
**Hazardous Situation:** Utente addebitato per decine di SMS, destinatario spammato, SMS inviato a numero in blacklist contro configurazione
**Potential Harm:** Costi diretti, reclami, percezione di app "spam"; contenzioso operatore

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **4 — Occasional** · Score: **8** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- Idempotenza: al massimo 1 SMS per chiamata rifiutata (chiave = id evento); stato persistito; nessun retry automatico oltre 1 tentativo + stato "fallito" visibile (RF-3)
- Default testo precompilato entro 1 segmento GSM-7 (quello del brief, verificato in build) + contatore segmenti nell'editor (RF-9); flag "invia anche per blacklist: default OFF" (RF-6)
- Mai invio a numeri anonimi/sconosciuti-formato-invalido; preview + conferma prima del primo invio dopo installazione

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **2 — Unlikely** · Score: **4** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-3, RF-4, RF-6, RF-9

---

## RSK-108

**Category:** Usability — Misclassification from SMS triage view
**Hazard:** L'utente promuove spam in whitelist o relega un legittimo in blacklist con 1 tap
**Source of Hazard:** Vista RF-7 che mostra SMS solo all'apertura (contesto parziale), CTA affiancate senza conferma, mittente spoofabile, fretta di smaltire la coda
**Hazardous Situation:** Decisione errata applicata immediatamente (RF-10): spam futuro squilla, oppure legittimo futuro sempre rifiutato
**Potential Harm:** Danno reversibile ma fastidioso: spam sbloccato o contatto utile bloccato fino a correzione manuale

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **4 — Occasional** · Score: **8** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- CTA con conferma e undo immediato; dettaglio con numero, data/ora chiamata originaria, testo SMS completo, match con cronologia (RF-3 + RF-7 collegati)
- Decisioni reversibili in 2 tap da gestione liste; profilo numero modificabile (nome, note, categoria) per ricontrollare prima di decidere (RF-8)
- Test usabilità: tempo di triage < 30 s e tasso errore < 5% su 10 casi simulati; CTA con label esplicite "Accetta (whitelist)" / "Rifiuta (blacklist)"

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **2 — Unlikely** · Score: **4** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-7, RF-8, RF-10

---

## RSK-109

**Category:** Availability — Delayed SMS triage (interception only on open)
**Hazard:** Le risposte SMS dei chiamanti restano non lette finché l'utente non apre l'app
**Source of Hazard:** Scelta architetturale RF-7 (intercettazione alla sola apertura, per minimizzare permessi/background) + assenza di push/background listener continuo
**Hazardous Situation:** Risposta identificativa (es. "sono il dott. Rossi per la visita") attesa per ore/giorni; il numero resta non classificato e le richiamate continuano a essere rifiutate
**Potential Harm:** Ritardo di classificazione, chiamate legittime ripetutamente rifiutate nel frattempo, frustrazione di entrambe le parti

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **5 — Probable** · Score: **10** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- Notifica locale alla chiamata rifiutata ("SMS di risposta apparirà qui all'apertura") + badge contatore + deep-link alla vista triage
- Vista triage ordinata per recenza con stato (in attesa/classificato) e promemoria; collegamento 1:1 chiamata→SMS atteso
- Documentato come limite noto in onboarding e Store listing; Future: valutazione listener `RECEIVE_SMS` in background con notifica (pesato contro RSK-105 policy)

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **3 — Remote** · Score: **6** → [MEDIO] **Conditionally Tolerable**

**Benefit–Risk Justification:**
Il polling all'apertura minimizza batteria, complessità e superficie privacy/policy (mitiga RSK-102/105). Il ritardo è trasparente e reversibile; il beneficio (semplicità, approvabilità Store, consumo zero in background) supera il disagio di un triage differito per un'app consumer non critica. Accettato in ALARP; metrica: tempo mediano apertura post-rifiuto.

**Traceability:** RF-3, RF-4, RF-7

---

## Risk Summary Table

| RSK ID | Category | Hazard | Potential Harm | Initial Region | Mitigations | Residual Region |
|---|---|---|---|---|---|---|
| RSK-101 | Functional Safety — False-positive | Legittimo/urgente rifiutato come sconosciuto | Comunicazione urgente persa/ritardata; sfiducia | [ALTO] Intolerable (12) | Precedenza rubrica/whitelist; notifica + cronologia richiamabile; onboarding whitelist critici | [MEDIO] Conditionally Tolerable (6) |
| RSK-102 | Availability — Screening failure | Screening oltre timeout / ruolo mancante | Spam che passa o ritardo suoneria | [MEDIO] Conditionally Tolerable (10) | Gate ruolo all'avvio; path nativo minimale fail-open; test OEM/API 29–35 | [BASSO] Broadly Tolerable (4) |
| RSK-103 | Privacy — PII in Logs | Numeri/SMS nei log | Breach GDPR; sanzioni | [ALTO] Intolerable (12) | Divieto PII nei log + test; offline-by-design; informativa | [BASSO] Broadly Tolerable (3) |
| RSK-104 | Data Security — Local access | Storia/liste leggibili da terzi | Divulgazione PII | [MEDIO] Conditionally Tolerable (9) | Storage interno; no provider esportato; no backup in chiaro; cancellazione esplicita | [BASSO] Broadly Tolerable (3) |
| RSK-105 | Compliance — Store policy | Rigetto Play per SEND/RECEIVE_SMS | Mancato rilascio; sideload only | [MEDIO] Conditionally Tolerable (10) | Declaration anticipata; fallback solo-rifiuto; valutazione Consent/Retriever API | [MEDIO] Conditionally Tolerable (6) |
| RSK-106 | Data Integrity — Persistence loss | Liste/cronologia perse a reboot/update | Riclassificazione; decisioni non applicate | [MEDIO] Conditionally Tolerable (6) | Room transazionale + test migrazione/reboot; stato SMS persistito | [BASSO] Broadly Tolerable (2) |
| RSK-107 | Operational — SMS incontrollato | SMS multipli/costi/violazione config blacklist | Costi; destinatario spammato | [MEDIO] Conditionally Tolerable (8) | Idempotenza 1 SMS/evento; default 1 segmento; flag blacklist default OFF | [BASSO] Broadly Tolerable (4) |
| RSK-108 | Usability — Misclassification | Whitelist a spam / blacklist a legittimo | Sblocco spam o blocco utile (reversibile) | [MEDIO] Conditionally Tolerable (8) | Conferma + undo; dettaglio collegato a cronologia; test usabilità | [BASSO] Broadly Tolerable (4) |
| RSK-109 | Availability — Triage differito | SMS visibili solo all'apertura | Classificazione ritardata; rifiuti ripetuti | [MEDIO] Conditionally Tolerable (10) | Notifica + badge + deep-link; limite documentato; future background listener | [MEDIO] Conditionally Tolerable (6) |

Nessun rischio residuo [ALTO] Intolerable. I tre rischi residui [MEDIO] (RSK-101, RSK-105, RSK-109) sono accettati in ALARP con giustificazione beneficio–rischio sopra e owner di monitoraggio (PM). Gate di release: checklist ruolo/timeout (RSK-102), test assenza PII nei log (RSK-103), permission declaration Play (RSK-105) e test persistenza/migrazione (RSK-106) devono essere verdi prima dell'approvazione.

---

*End of Document — CG-RSK-001 v0.1.0*
*Next in package: CG-SRS-001 — Software Requirements Specifications*
