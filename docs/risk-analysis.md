# Call Guard — Risk Analysis (ISO 14971)

**Document ID:** CG-RSK-001
**Version:** 0.1.0
**Status:** Draft
**Service:** `call-guard`
**Standard:** ISO 14971:2019 (applicazione proporzionata ad app consumer non medicale)
**Last Updated:** 2026-10-10
**Trace Parents:** RF-1 · RF-2 · RF-3 · RF-4 · RF-5 · RF-6 · RF-7 · RF-8 · RF-9 · RF-10

---

## Document Control

| Role | Name | Date | Signature |
|---|---|---|---|
| Author | Aldo (PM) | 2026-10-10 | Aldo |
| Reviewer | — | — | — |
| Approver (QA/RA) | — | — | — |

### Change Log

| Version | Date | Author | Summary of Change |
|---|---|---|---|
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft compilato per Call Guard (RF-1…RF-10, vincoli Android 10+ / CallScreeningService / SMS) |

---

## Overview

Call Guard è un'app Android-only (modulo nativo Kotlin con `CallScreeningService`, ruolo `ROLE_CALL_SCREENING`, Android 10+; UI Flutter via platform channel) che: intercetta le chiamate in ingresso prima della suoneria (RF-1), rifiuta automaticamente i numeri visibili non in rubrica/whitelist (RF-2), registra ogni tentativo (RF-3), invia un SMS automatico configurabile (RF-4, RF-9), rispetta whitelist/blacklist (RF-5, RF-6, RF-8, RF-10) e mostra all'apertura app gli SMS ricevuti con CTA Accetta/Rifiuta (RF-7). Nessun dato lascia il dispositivo; persistenza locale.

Questo documento identifica, valuta e mitiga i rischi di prodotto, tecnici, privacy e compliance. Non è un dispositivo medico: la scala di severità ISO 14971 è applicata in modo proporzionato (nessun rischio di morte/disabilità intrinseco al software; il danno massimo realistico è la perdita di una chiamata importante, addebiti SMS indesiderati, breach PII locale, o rifiuto di pubblicazione su Play Store).

## Evaluation Matrix

| **Probability \ Severity** | **Catastrophic (4)** | **Critical (3)** | **Marginal (2)** | **Negligible (1)** |
|---|---|---|---|---|
| **Frequent (6)** | [ALTO] 24 | [ALTO] 18 | [ALTO] 12 | [MEDIO] 6 |
| **Probable (5)** | [ALTO] 20 | [ALTO] 15 | [MEDIO] 10 | [MEDIO] 5 |
| **Occasional (4)** | [ALTO] 16 | [ALTO] 12 | [MEDIO] 8 | [BASSO] 4 |
| **Remote (3)** | [ALTO] 12 | [MEDIO] 9 | [MEDIO] 6 | [BASSO] 3 |
| **Unlikely (2)** | [MEDIO] 8 | [MEDIO] 6 | [BASSO] 4 | [BASSO] 2 |
| **Unbelievable (1)** | [BASSO] 4 | [BASSO] 3 | [BASSO] 2 | [BASSO] 1 |

**Severity Scale (applicazione a Call Guard):**
| Level | Label | Descrizione (adattata) |
|---|---|---|
| 4 | Catastrophic | Non applicabile al software in sé; riservato a danno grave a persona conseguente a chiamata critica persa in modo dimostrabile (caso limite, fuori controllo diretto del software) |
| 3 | Critical | Perdita di chiamata importante/urgente (es. medico, emergenza, lavoro); addebito economico significativo; breach PII con conseguenze legali (GDPR); rimozione/blocco pubblicazione |
| 2 | Marginal | Disservizio recuperabile: tentativo non registrato, SMS non inviato/doppio, classificazione errata correggibile, frizione UX |
| 1 | Negligible | Fastidio senza conseguenze: log rumoroso, ritardo minimo UI, testo SMS poco chiaro |

**Probability Scale:**
| Level | Label | Descrizione |
|---|---|---|
| 6 | Frequent | Accade subito o in modo continuativo senza mitigazione (es. ogni chiamata sconosciuta) |
| 5 | Probable | Probabile; più volte in 1–2 anni di uso per utente attivo |
| 4 | Occasional | Può accadere poche volte in 2–5 anni |
| 3 | Remote | Non atteso; possibile in 5–30 anni / solo in condizioni particolari (OEM, carrier, root) |
| 2 | Unlikely | Sorprenderebbe se accadesse con le mitigazioni attive |
| 1 | Unbelievable | Sorprenderebbe molto; solo con fallimento di più barriere |

**Risk Score = Probability × Severity**

**Acceptability:**
| Colour | Region | Score Range | Action Required |
|---|---|---|---|
| [ALTO] Red | Intolerable | ≥ 12 | Mitigazione obbligatoria prima del rilascio |
| [MEDIO] Yellow | Conditionally Tolerable | 5 – 11 | Revisione ALARP; confronto benefici–rischi; accettazione con giustificazione |
| [BASSO] Green | Broadly Tolerable | ≤ 4 | Rischio residuo accettabile; nessuna ulteriore azione |

> **ALARP note:** I rischi [MEDIO] non ulteriormente riducibili sono confrontati con il beneficio (filtro automatico anti-disturbo, traccia consultabile, classificazione rapida). Se il beneficio supera il rischio, il rischio è accettato come tollerabile con giustificazione. Il rischio residuo NON deve restare [ALTO].

---

## RSK-101

**Category:** Functional Reliability — False Rejection (mancata chiamata importante)
**Hazard:** Rifiuto automatico di una chiamata legittima e urgente da numero non in rubrica
**Source of Hazard:** RF-2 rifiuta per default ogni numero visibile non in rubrica/whitelist, senza distinzione di urgenza; l'utente potrebbe non aver pre-registrato numeri importanti (medico, scuola, corriere, reperibilità lavoro)
**Hazardous Situation:** L'utente perde una chiamata time-critical; se ne accorge solo a posteriori dalla lista (RF-3) o dall'SMS di risposta del chiamante
**Potential Harm:** Danno organizzativo/personale (appuntamento medico perso, emergenza familiare ritardata, opportunità di lavoro persa); nel caso limite, ritardo in una catena di soccorso

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **5 — Probable** · Score: **15** → [ALTO] **Intolerable**

**Risk Reduction Measures:**
- RF-5/RF-6/RF-10: whitelist con effetto immediato + importabile dalla rubrica; onboarding che invita a inserire numeri critici prima di attivare il filtro
- RF-3: lista tentativi sempre visibile con badge "non letto", ordinamento cronologico, filtro per data; nessun tentativo cancellabile senza conferma
- RF-4: SMS automatico con testo chiaro che invita a identificarsi via SMS (default approvato), così il chiamante legittimo ha un canale immediato di fallback
- RF-7: alla riapertura, gli SMS di risposta sono mostrati con CTA Accetta/Rifiuta a un tap per "promuovere" subito il numero
- Organisational: guida in-app "Prima di attivare: aggiungi i numeri critici; verifica il ruolo di call screening"

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **3 — Remote** · Score: **9** → [MEDIO] **Conditionally Tolerable**

**Benefit–Risk Justification:**
Il beneficio (blocco automatico di chiamate indesiderate/ambigue, traccia completa, recupero via SMS/whitelist in pochi secondi) supera il rischio residuo: l'utente informato che pre-registra i numeri critici riduce la probabilità a remota, e ogni falso positivo resta recuperabile via lista + SMS. Accettato a livello ALARP; non ulteriormente riducibile senza snaturare RF-2 (un filtro che chiede conferma per ogni numero non sarebbe più automatico).

**Traceability:** RF-2 · RF-3 · RF-4 · RF-5 · RF-7 · RF-10

---

## RSK-102

**Category:** Compliance — Google Play SMS Permissions Rejection
**Hazard:** Rifiuto o rimozione dell'app dal Play Store per uso di permessi SMS restricted
**Source of Hazard:** RF-4 e RF-7 richiedono `SEND_SMS` / `RECEIVE_SMS` (restricted) + ruolo `ROLE_CALL_SCREENING`; Google Play concede questi permessi solo alle app la cui funzionalità core li richiede con giustificazione verificabile
**Hazardous Situation:** Al review Play, l'app viene rifiutata o sospesa; l'utente non può installarla/aggiornarla dal canale ufficiale
**Potential Harm:** Blocco distribuzione, rilavorazione architetturale tardiva, perdita di fiducia e di finestra di lancio

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **5 — Probable** · Score: **15** → [ALTO] **Intolerable**

**Risk Reduction Measures:**
- Minimizzazione: richiedere `SEND_SMS`/`RECEIVE_SMS` solo con feature core dichiarata (filtro chiamate + SMS di identificazione), mai per usi secondari; `READ_CONTACTS` limitato al match locale rubrica
- Dichiarazione Play preparata in anticipo: video dimostrativo del flusso RF-2→RF-4→RF-7, policy privacy on-device, giustificazione per ogni permesso
- Fallback architetturale definito: se il permesso è negato, RF-2/RF-3 restano attivi senza RF-4 (rifiuto + log, SMS disabilitato con banner esplicativo); RF-6 configurabile "rifiuta senza SMS"
- Test di sottomissione su canale interno/closed testing prima della release pubblica

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **2 — Unlikely** · Score: **6** → [MEDIO] **Conditionally Tolerable**

**Benefit–Risk Justification:**
L'SMS automatico è il differenziale core del prodotto (il chiamante legittimo si identifica, l'utente classifica in un tap); senza di esso il prodotto perde metà del valore. Il rischio residuo è accettato perché mitigato da minimizzazione + fallback funzionante senza SMS. Accettato ALARP.

**Traceability:** RF-4 · RF-6 · RF-7

---

## RSK-103

**Category:** Privacy — PII Exposure in Logs
**Hazard:** Numeri di telefono (PII) scritti in log operativi, logcat o crash report
**Source of Hazard:** Logging di debug del modulo Kotlin (CallScreeningService, platform channel, invio SMS) che include il numero chiamante o il contenuto SMS in chiaro
**Hazardous Situation:** Chi ha accesso al dispositivo (altra persona, assistenza, tool di diagnostica) o a un report condiviso legge numeri e contenuti di chiamate/SMS di terzi
**Potential Harm:** Violazione GDPR (numeri = dati personali), sanzione, perdita di fiducia; nessun dato deve lasciare il dispositivo per requisito non funzionale

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **4 — Occasional** · Score: **12** → [ALTO] **Intolerable**

**Risk Reduction Measures:**
- Divieto di PII nei log: nel codice nativo e Flutter i numeri sono mascherati (`+39 *** *** 123`) o hashati prima del log; il contenuto SMS non è mai loggato
- Log schema: solo esiti e conteggi (es. `call_rejected, sms_sent=true/false, error_code`), mai identificativi diretti
- Test automatico: asserzione che l'output di log dei test non contenga pattern telefonici (`\+?\d{6,}`) né stringhe SMS di fixture
- Nessun analytics/crash-reporting con PII; se abilitato, scrubber dedicato + consenso esplicito; DPIA leggera pre-release

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **1 — Unbelievable** · Score: **3** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-2 · RF-3 · RF-4 · RF-7

---

## RSK-104

**Category:** Data Integrity — Call History / List Loss
**Hazard:** Perdita della cronologia tentativi o delle liste whitelist/blacklist (es. dopo riavvio, aggiornamento, kill del processo)
**Source of Hazard:** Persistenza locale non transazionale o non testata su kill/riavvio; scrittura best-effort del record (RF-3) dopo il rifiuto (RF-2) senza garanzia di atomicità
**Hazardous Situation:** L'utente non ritrova un tentativo o una classificazione; un numero in blacklist torna a squillare o un numero promosso viene ri-rifiutato
**Potential Harm:** Perdita di traccia (valore core), ricomparsa del disturbo, sfiducia; decisioni RF-10 non effettive

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **5 — Probable** · Score: **10** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- Persistenza locale sincrona e testata: scrittura del record RF-3 prima/contemporanea all'invio SMS; liste whitelist/blacklist su storage durabile (es. Room/DataStore) con flush immediato a ogni decisione RF-10
- Contatore di versione/monotonico per rilevamento gap; all'avvio, verifica integrità e banner "ripristino completato"
- Test: kill/riavvio simulato, upgrade con migrazione, 100 rifiuti consecutivi senza perdite
- Future: export/backup locale cifrato (fuori release corrente)

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **2 — Unlikely** · Score: **4** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-3 · RF-8 · RF-10

---

## RSK-105

**Category:** Availability — Screening Timeout / OEM-Carrier Variance
**Hazard:** Il rifiuto non avviene prima della suoneria o non avviene affatto su alcuni dispositivi/reti
**Source of Hazard:** Timeout di piattaforma su `CallScreeningService.onScreenCall`, Doze/battery-optimization che sospende il servizio, implementazioni OEM/carrier difformi, ruolo di call screening non assegnato o revocato
**Hazardous Situation:** Il telefono squilla nonostante il filtro attivo, o la chiamata passa senza registrazione; l'utente crede di essere protetto ma non lo è
**Potential Harm:** Disturbo non bloccato (promessa prodotto mancata), registrazione incompleta, supporto sommerso da segnalazioni "non funziona"

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **5 — Probable** · Score: **10** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- Path nativo minimo e veloce: `onScreenCall` fa solo match rubrica/whitelist/blacklist + `disconnect()` entro il timeout; nessuna I/O pesante nel path critico (log/SMS in coda asincrona)
- Onboarding + stato persistente: check ruolo screening a ogni avvio con CTA di (ri)assegnazione; banner se il ruolo è revocato; guida anti-battery-optimization per i principali OEM
- Matrice di test su Android 10–15 + almeno 3 OEM + dual-SIM; metriche locali (conteggio screening/timeout) senza PII
- Organisational: documentare i limiti noti (numeri anonimi non gestibili, VoIP/SIP fuori perimetro, iOS escluso)

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **3 — Remote** · Score: **6** → [MEDIO] **Conditionally Tolerable**

**Benefit–Risk Justification:**
Il beneficio (filtro silenzioso nella maggioranza dei casi reali) supera il degrado residuo su una minoranza di dispositivi/reti: nei casi limite l'app degrada a "registra senza bloccare" con stato onesto, senza promettere ciò che la piattaforma non consente. Accettato ALARP.

**Traceability:** RF-1 · RF-2 · RF-5 · RF-6

---

## RSK-106

**Category:** Financial / Abuse — Unwanted SMS Send (costi, loop, spam)
**Hazard:** Invio di SMS automatici indesiderati, ripetuti o a numerazioni a pagamento
**Source of Hazard:** RF-4 invia un SMS a ogni rifiuto senza rate-limit; numeri premium/servizi, short-code o attaccanti che richiamano in loop generano addebiti o traffico spam
**Hazardous Situation:** L'utente paga SMS multipli o l'app appare come sorgente spam; l'operatore o il destinatario segnala abuso
**Potential Harm:** Addebito economico, blocco SMS da parte dell'operatore, reputazione compromessa, segnalazione Play

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **4 — Occasional** · Score: **12** → [ALTO] **Intolerable**

**Risk Reduction Measures:**
- Un solo SMS per numero per finestra (es. 24h) + toggle RF-6 "blacklist: rifiuta senza SMS" (default: senza SMS per blacklist) + toggle globale RF-9
- Blocco invio verso short-code/premium/not-known-SMS-capable (euristica + prefissi configurati); nessun SMS verso numeri anonimi/bloccati
- Contatore visibile "SMS inviati" con costo stimato da piano utente; conferma alla prima attivazione ("l'invio SMS può avere un costo operatore")
- Log di invio con esito (RF-3: stato SMS inviato/fallito) per audit locale

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **1 — Unbelievable** · Score: **3** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-3 · RF-4 · RF-6 · RF-9

---

## RSK-107

**Category:** Security / Usability — Erroneous Classification & Malicious SMS Content
**Hazard:** Classificazione errata (whitelist a uno spammer / blacklist a un contatto utile) o interazione non sicura con SMS malevoli (smishing con link)
**Source of Hazard:** RF-7 mostra SMS in ingresso con CTA a un tap; l'utente decide in fretta basandosi su testo auto-dichiarato dal chiamante; link/phishing resi tappabili senza avvisi
**Hazardous Situation:** Uno spammer "promosso" bypassa per sempre il filtro (RF-5), o l'utente tocca un link malevolo dallo SMS visualizzato
**Potential Harm:** Filtro neutralizzato per quell'attaccante (disturbo ricorrente), potenziale phishing se l'utente segue il link; nel caso opposto, contatto utile silenziato

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **5 — Probable** · Score: **10** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- RF-8: ogni decisione è reversibile in un tap (rimozione/spostamento whitelist↔blacklist, profilo con nome/note/categoria/data); conferma esplicita per whitelist ("consentirai sempre le chiamate da questo numero")
- Vista RF-7 con segnali anti-truffa: numero maiuscolo, avviso "il mittente si è auto-identificato, verificalo", link non auto-aperti (tap con dialogo di conferma + anteprima URL)
- Nessuna azione automatica sul contenuto SMS: la classificazione richiede sempre il gesto utente; default prudente (resta "da classificare")
- Test UX: tempo di classificazione < 10s con tasso di errore osservato su fixture smishing/lecite

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **2 — Unlikely** · Score: **4** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-5 · RF-6 · RF-7 · RF-8 · RF-10

---

## RSK-108

**Category:** Privacy — On-Device Data Access by Third Parties
**Hazard:** Altre app o persone con accesso al dispositivo leggono cronologia, whitelist/blacklist o SMS di identificazione
**Source of Hazard:** Database locale non cifrato, backup automatico non controllato, schermata app visibile in task-switcher, esportazioni non protette
**Hazardous Situation:** Numeri e note (es. "presunto truffatore", "dott. X") esposti a terzi con accesso fisico o a backup cloud dell'OS
**Potential Harm:** Esposizione PII di utente e terzi, violazione del principio "nessun dato lascia il dispositivo"

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **3 — Remote** · Score: **9** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- Storage locale cifrato (SQLCipher/EncryptedSharedPreferences o equivalente), nessuna sincronizzazione cloud; esclusione da backup automatico o backup cifrato
- Oscuramento screenshot/task-switcher per le viste con numeri; blocco app con biometria opzionale
- Permessi minimi: nessuna lettura SMS oltre la vista RF-7, nessuna condivisione implicita; export solo esplicito e con avviso
- Test: ispezione DB a riposo (cifrato), verifica `allowBackup`/regole backup, review dei provider esportati (nessuno)

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **1 — Unbelievable** · Score: **3** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-3 · RF-7 · RF-8

---

## Risk Summary Table

| RSK ID | Category | Hazard | Potential Harm | Initial Region | Mitigations | Residual Region |
|---|---|---|---|---|---|---|
| RSK-101 | Functional Reliability — False Rejection | Rifiuto di chiamata legittima urgente da numero non in rubrica | Chiamata critica persa/ritardata; danno personale/organizzativo | [ALTO] Intolerable (15) | Whitelist immediata + onboarding numeri critici; lista tentativi con badge; SMS fallback; CTA Accetta a un tap | [MEDIO] Conditionally Tolerable (9) |
| RSK-102 | Compliance — Play SMS Permissions | Rifiuto Play per SEND/RECEIVE_SMS restricted | Blocco distribuzione, rilavorazione tardiva | [ALTO] Intolerable (15) | Minimizzazione permessi; dichiarazione Play + video; fallback senza SMS; closed testing | [MEDIO] Conditionally Tolerable (6) |
| RSK-103 | Privacy — PII in Logs | Numeri/contenuti SMS nei log | Breach GDPR, sanzione, sfiducia | [ALTO] Intolerable (12) | Mascheramento PII; schema log senza identificativi; test anti-pattern; no analytics con PII | [BASSO] Broadly Tolerable (3) |
| RSK-104 | Data Integrity — History Loss | Perdita cronologia/liste dopo kill/riavvio/update | Traccia persa; filtro inefficace | [MEDIO] Conditionally Tolerable (10) | Scrittura sincrona + flush a ogni decisione; contatore gap; test kill/riavvio/upgrade | [BASSO] Broadly Tolerable (4) |
| RSK-105 | Availability — Screening Timeout/OEM | Rifiuto oltre timeout o mai eseguito su alcuni device/reti | Disturbo non bloccato; promessa mancata | [MEDIO] Conditionally Tolerable (10) | Path nativo minimo; check ruolo + banner; guida battery-optimization; matrice OEM 10–15 | [MEDIO] Conditionally Tolerable (6) |
| RSK-106 | Financial/Abuse — Unwanted SMS | SMS ripetuti/a pagamento/spam | Addebiti, blocco operatore, segnalazioni | [ALTO] Intolerable (12) | 1 SMS/numero/24h; blacklist senza SMS di default; blocco premium; contatore costi + consenso | [BASSO] Broadly Tolerable (3) |
| RSK-107 | Security/Usability — Misclassification & Smishing | Whitelist a spammer / tap su link malevolo | Filtro neutralizzato; phishing | [MEDIO] Conditionally Tolerable (10) | Decisioni reversibili + conferma whitelist; avvisi anti-truffa; link con conferma; nessuna auto-azione | [BASSO] Broadly Tolerable (4) |
| RSK-108 | Privacy — On-Device Access | Lettura DB/SMS da terzi con accesso al device | Esposizione PII, violazione on-device-only | [MEDIO] Conditionally Tolerable (9) | DB cifrato; no cloud; oscuramento task-switcher; blocco biometrico; review backup/provider | [BASSO] Broadly Tolerable (3) |

**Esito complessivo:** nessun rischio residuo [ALTO] Intolerable. Restano [MEDIO] RSK-101, RSK-102, RSK-105 accettati ALARP con giustificazione sopra; tutti gli altri [BASSO]. Il documento è approvabile subordinatamente all'implementazione delle mitigazioni pre-release (test matrice OEM, asserzioni anti-PII nei log, dichiarazione Play, rate-limit SMS, storage cifrato).

---

*End of Document — CG-RSK-001 v0.1.0*
*Next in package: CG-SRS-001 — Software Requirements Specifications*
