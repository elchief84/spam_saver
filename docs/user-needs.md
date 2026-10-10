# Call Guard — User Needs

**Document ID:** CG-UN-001
**Version:** 0.1.0
**Status:** Draft
**Service:** `call-guard`
**Last Updated:** 2026-10-10
**Trace Parent:** CG-UC-001

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
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft for Call Guard |

---

## Document Scope

This document captures the User Needs (UN) for Call Guard, app Android per la gestione delle chiamate da numeri sconosciuti: intercetta le chiamate in ingresso prima che squillino, rifiuta automaticamente quelle da numeri visibili non in rubrica/whitelist, registra ogni tentativo, invia un SMS automatico configurabile, e permette di classificare rapidamente i numeri (whitelist/blacklist) dalle risposte SMS ricevute. Ogni need è espresso dal punto di vista dello stakeholder, senza dettagli implementativi, è tracciabile a uno o più Use Cases e sarà decomposto in requisiti software testabili nella fase successiva.

Stakeholder principali: utente proprietario del dispositivo, chiamante sconosciuto, sistema operativo Android (ruolo di call screening, permessi SMS). Fuori perimetro: iOS, cloud/backend e sincronizzazione multi-dispositivo, chiamate in uscita.

---

## UN-101 — Rifiuto automatico dei numeri sconosciuti

**Text:** Device owners must be able to have incoming calls from visible numbers that are neither in contacts nor in the whitelist automatically rejected before the phone rings, so that unwanted or ambiguous calls never disturb them.

**Note:** Solo numeri visibili non in rubrica/whitelist. Numeri nascosti/anonimi, contatti e whitelist devono passare normalmente. Il rifiuto deve avvenire entro il timeout di piattaforma del call screening, senza ritardare la suoneria per le chiamate legittime.

**Tags:** `Operator-Workflow`, `Performance`, `Platform-Integration`
**Trace UC:** UC-01, UC-02

---

## UN-102 — Registro consultabile dei tentativi rifiutati

**Text:** Device owners must be able to review every automatically rejected call with number, date and time, outcome, SMS-sent status, and notes, so that no attempt goes untracked and each one can be followed up.

**Note:** La lista è solo locale (on-device). Deve restare leggibile anche con molti tentativi e sopravvivere al riavvio del dispositivo. Nessun numero deve finire in log diagnostici in chiaro.

**Tags:** `Operator-Workflow`, `Data-Retention`, `Privacy`
**Trace UC:** UC-03

---

## UN-103 — Risposta automatica via SMS con testo configurabile

**Text:** Device owners must be able to have each rejected unknown caller automatically receive an SMS asking for identification, so that legitimate callers can present themselves in writing.

**Note:** Testo di default: "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione." L'utente deve poter modificare il testo in-app con il default precompilato. Per i numeri in blacklist l'invio segue la configurazione (può essere disattivato).

**Tags:** `Operator-Workflow`, `Configurability`, `Platform-Integration`
**Trace UC:** UC-04

---

## UN-104 — Whitelist sempre consentita

**Text:** Device owners must be able to mark trusted numbers as whitelisted so that calls from those numbers always ring through normally.

**Note:** La whitelist prevale sul filtro automatico. Vale anche per numeri non in rubrica che l'utente ha promosso esplicitamente.

**Tags:** `Operator-Workflow`, `Access-Control`, `Configurability`
**Trace UC:** UC-05

---

## UN-105 — Blacklist sempre rifiutata

**Text:** Device owners must be able to mark unwanted numbers as blacklisted so that calls from those numbers are always rejected.

**Note:** La blacklist prevale su rubrica/whitelist in caso di conflitto operativo da risolvere in UC (un numero non può stare in entrambe le liste). Invio SMS per blacklist secondo configurazione (default: nessun SMS).

**Tags:** `Operator-Workflow`, `Access-Control`, `Configurability`
**Trace UC:** UC-06

---

## UN-106 — Triage rapido delle risposte SMS all'apertura dell'app

**Text:** Device owners must be able to see incoming SMS replies in a dedicated view when opening the app and classify each sender with one tap as Accept (whitelist) or Reject (blacklist), so that unknown numbers are resolved in seconds.

**Note:** La vista mostra il testo ricevuto e il numero mittente con due CTA chiare: ACCETTA e RIFIUTA. La classificazione alimenta immediatamente il comportamento di filtro (UN-101, UN-104, UN-105).

**Tags:** `Operator-Workflow`, `Configurability`, `Platform-Integration`
**Trace UC:** UC-07

---

## UN-107 — Gestione di whitelist, blacklist e profilo del numero

**Text:** Device owners must be able to add, remove, and edit whitelisted and blacklisted numbers including name, notes, category, and date added, so that the lists stay accurate over time.

**Note:** La data di aggiunta è compilata automaticamente e non modificabile; nome, note e categoria sono modificabili. Le liste sono locali e persistono al riavvio.

**Tags:** `Operator-Workflow`, `Data-Retention`, `Configurability`
**Trace UC:** UC-08

---

## UN-108 — Effetto immediato delle decisioni

**Text:** Device owners must be able to have every whitelist/blacklist decision take effect immediately on subsequent incoming calls, so that there is no window in which an outdated rule still applies.

**Note:** Nessuna sincronizzazione differita o riavvio richiesto. Vale per decisioni prese dal triage SMS e dalla gestione liste.

**Tags:** `Operator-Workflow`, `Performance`, `Data-Integrity`
**Trace UC:** UC-05, UC-06, UC-07, UC-08

---

## UN-109 — Screening affidabile senza degradare le chiamate legittime

**Text:** The system must screen every incoming call and reach a reject-or-allow decision within the platform timeout such that legitimate calls ring without perceptible delay.

**Note:** Vincolo Android: ruolo di call screening assegnato dall'utente, modulo nativo Kotlin (CallScreeningService, Android 10+), UI Flutter via platform channel. L'affidabilità del rifiuto può variare per rete/operatore: è un rischio noto da coprire con test su dispositivi reali.

**Tags:** `Performance`, `Architecture-Constraint`, `Platform-Integration`, `Operability`
**Trace UC:** UC-01, UC-02

---

## UN-110 — Privacy locale e protezione PII

**Text:** The system must keep all phone numbers and message contents exclusively on the device and never transmit them off-device such that user call data stays private.

**Note:** I numeri sono PII. Nessun dato lascia il dispositivo: niente cloud, niente analytics con numeri in chiaro, nessun PII nei log operativi. Rilevante per GDPR e per la policy Google Play sui permessi sensibili (SEND_SMS, RECEIVE_SMS restricted: serve giustificazione e valutazione impatto pubblicazione).

**Tags:** `Privacy`, `Security`, `GDPR`, `Compliance`
**Trace UC:** UC-01, UC-02, UC-03, UC-04, UC-07, UC-08

---

## UN-111 — Persistenza locale e leggibilità

**Text:** Device owners must be able to rely on call history, whitelist, blacklist, number profiles, and the custom SMS text surviving device restarts, presented in readable lists, so that the protection setup is never lost.

**Note:** Persistenza solo locale. Le liste devono restare leggibili e la classificazione rapida anche a volumi elevati (requisito di usabilità del brief).

**Tags:** `Data-Retention`, `Offline-Support`, `Operator-Workflow`
**Trace UC:** UC-03, UC-08

---

## UN-112 — Gating di piattaforma e consenso esplicito

**Text:** Device owners must be able to grant the call-screening role and SMS permissions through explicit system prompts and change them at any time, so that no interception or SMS sending happens without informed consent.

**Note:** Senza ruolo di call screening l'app non può intercettare/rifiutare: deve guidare l'utente all'attivazione e degradare con grazia (nessun blocco silenzioso). Solo Android 10+. iOS escluso perché non consente intercettazione a runtime né invio/lettura automatica di SMS.

**Tags:** `Architecture-Constraint`, `Platform-Integration`, `Compliance`, `Access-Control`
**Trace UC:** UC-01, UC-04, UC-07

---

## UN-113 — Blocking Gate / Access Control

**Text:** Any incoming caller must only ring through when the number meets the defined allow criteria (in contacts, in whitelist, or hidden/undeterminable number that cannot be safely auto-rejected), and must otherwise be rejected.

**Note:** Controllo di sicurezza dell'utente: il filtro non deve mai essere aggirabile da parametri forniti dal chiamante. La blacklist rifiuta sempre. Questo è l'equivalente del publish-gate del template, adattato a Call Guard (single-user, nessun contenuto patient-facing).

**Tags:** `Access-Control`, `Security`, `Operator-Workflow`
**Trace UC:** UC-01, UC-02, UC-05, UC-06

---

## UN-114 — Consistent Error Handling

**Text:** The system must respond to all screening, SMS, and storage failures with consistent, user-comprehensible behaviour that never exposes internal system details.

**Note:** Errori tipici: SMS non inviato (rete/credito/permesso revocato), ruolo screening revocato, storage non disponibile. L'utente deve vedere stato ed esito (es. "SMS non inviato") nella lista tentativi, senza dettagli tecnici o PII extra. Il fallimento dell'SMS non deve sbloccare la chiamata rifiutata.

**Tags:** `Operability`, `Security`, `ISO-27001`
**Trace UC:** UC-01, UC-02, UC-03, UC-04

---

## UN-115 — Traceable Logging with PII Protection

**Text:** The system must produce structured, traceable logs for every screening decision and SMS operation, enabling operational monitoring and incident investigation, without exposing personally identifiable information in log outputs.

**Note:** Numeri di telefono e contenuti SMS sono PII: nei log solo identificatori anonimizzati/troncati; i dati completi restano esclusivamente nello storage applicativo locale. Adattamento single-device del requisito di logging distribuito del template (nessun tracing cross-service: nessun backend).

**Tags:** `Observability`, `Logging`, `GDPR`, `ISO-27001`, `Privacy`
**Trace UC:** UC-01, UC-02, UC-03, UC-04

---

## Note di non applicabilità (adattamenti dal template)

- **Versioning/audit GxP/ISO 13485:** non applicabile (nessun dispositivo medico, nessun requisito GxP). Sostituito da UN-102 (storico locale dei tentativi) + UN-107 (profilo numero con data di aggiunta).
- **Cross-tenant isolation:** non applicabile (app single-user, single-device, nessun backend/multi-tenancy). Sostituito da UN-110 (isolamento on-device: nessun dato lascia il dispositivo) + UN-115 (PII protection nei log).
- **Patient safety:** non applicabile (nessun contenuto clinico). Sostituito da UN-113 (blocking gate: nessun chiamante indesiderato deve squillare, nessuna chiamata legittima deve essere persa in silenzio senza traccia).

---

## Traceability Matrix

| UN ID | Summary | UC Trace |
|---|---|---|
| UN-101 | Rifiuto automatico numeri sconosciuti prima dello squillo | UC-01, UC-02 |
| UN-102 | Registro locale dei tentativi rifiutati | UC-03 |
| UN-103 | SMS automatico configurabile al numero rifiutato | UC-04 |
| UN-104 | Whitelist sempre consentita | UC-05 |
| UN-105 | Blacklist sempre rifiutata | UC-06 |
| UN-106 | Triage SMS all'apertura con CTA Accetta/Rifiuta | UC-07 |
| UN-107 | Gestione liste + profilo numero | UC-08 |
| UN-108 | Effetto immediato delle decisioni | UC-05, UC-06, UC-07, UC-08 |
| UN-109 | Screening entro timeout, nessun degrado chiamate legittime | UC-01, UC-02 |
| UN-110 | Privacy: tutto on-device, nessun PII off-device | UC-01, UC-02, UC-03, UC-04, UC-07, UC-08 |
| UN-111 | Persistenza al riavvio + liste leggibili | UC-03, UC-08 |
| UN-112 | Consenso esplicito: ruolo screening + permessi SMS | UC-01, UC-04, UC-07 |
| UN-113 | Blocking gate: squilla solo chi soddisfa i criteri | UC-01, UC-02, UC-05, UC-06 |
| UN-114 | Gestione errori consistente senza dettagli interni | UC-01, UC-02, UC-03, UC-04 |
| UN-115 | Log tracciabili senza PII | UC-01, UC-02, UC-03, UC-04 |

---

*End of Document — CG-UN-001 v0.1.0*
*Next in package: CG-RSK-001 — Risk Analysis*
