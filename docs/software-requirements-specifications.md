# Call Guard — Software Requirements Specifications

**Document ID:** CG-SRS-001
**Version:** 0.1.0
**Status:** Draft
**Service:** `call-guard`
**Last Updated:** 2026-10-10
**Trace Parents:** CG-UC-001 · CG-UN-001 · CG-RSK-001

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
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft — full SRS for Call Guard Android app |

---

## Document Scope

This document defines all Software Requirements Specifications (SRS) for **Call Guard**, app Android (UI Flutter + modulo nativo Kotlin) per la gestione delle chiamate da numeri sconosciuti.

Ogni requisito è atomico, non ambiguo e testabile indipendentemente. I requisiti sono organizzati per area funzionale e ciascuno traccia ad almeno un User Need. Dove il requisito implementa un controllo di rischio, traccia anche al rischio corrispondente.

**Riferimenti di pacchetto (assunti come parent, anche se redatti separatamente):**

- User Needs (CG-UN-001):
  - UN-01 — Come proprietario del dispositivo voglio che le chiamate da numeri visibili non in rubrica vengano rifiutate automaticamente, per non essere disturbato da chiamate indesiderate/ambigue.
  - UN-02 — Come proprietario voglio una lista consultabile di tutti i tentativi rifiutati (numero, data/ora, esito, stato SMS), per avere una traccia verificabile.
  - UN-03 — Come proprietario voglio che al numero rifiutato arrivi un SMS automatico che chiede di identificarsi via SMS, per dare al chiamante legittimo un canale di identificazione.
  - UN-04 — Come proprietario voglio vedere all'apertura dell'app le risposte SMS ricevute con azioni rapide Accetta/Rifiuta, per classificare un numero in pochi tocchi.
  - UN-05 — Come proprietario voglio gestire whitelist e blacklist (aggiunta, rimozione, profilo numero), per controllare quali numeri passano sempre e quali vengono sempre bloccati.
  - UN-06 — Come proprietario voglio modificare il testo dell'SMS automatico, per adattare tono e contenuto alle mie esigenze.
  - UN-07 — Come proprietario voglio che nessun dato lasci il dispositivo e che i numeri non finiscano nei log, per privacy.
- Rischi (CG-RSK-001):
  - RSK-01 — Policy Google Play: `SEND_SMS` / `RECEIVE_SMS` sono permessi restricted; rischio di rifiuto in pubblicazione.
  - RSK-02 — Il call screening richiede che l'utente assegni esplicitamente il ruolo `ROLE_CALL_SCREENING`; senza ruolo l'app non può intercettare/rifiutare.
  - RSK-03 — La risposta al call screening deve avvenire entro il timeout di piattaforma; oltre il limite la suoneria parte comunque.
  - RSK-04 — I numeri di telefono sono PII; esposizione nei log o fuori dal dispositivo è una violazione privacy.
  - RSK-05 — Affidabilità del rifiuto e dell'invio SMS variabile per carrier/rete/stato radio; possibili rifiuti o SMS non recapitati.
- Use Cases (CG-UC-001): UC-01 Chiamata sconosciuta rifiutata + SMS; UC-02 Chiamata da whitelist passa; UC-03 Chiamata da blacklist rifiutata; UC-04 Classificazione da risposta SMS; UC-05 Gestione liste e profilo numero; UC-06 Modifica template SMS.

**Componenti di piattaforma richiamati:** modulo nativo Kotlin con `CallScreeningService`, ruolo `ROLE_CALL_SCREENING` (Android 10 / API 29+), Flutter UI via platform channel (MethodChannel), `SmsManager` per invio SMS, `SmsReceiver` / SMS Retriever per lettura SMS in ingresso, storage locale on-device (nessun backend/cloud).

**Fuori perimetro (non coperto da requisiti):** iOS e altre piattaforme, cloud/backend e sincronizzazione multi-dispositivo, chiamate in uscita.

---

## Ambiguities & Clarifications

| ID | Item | Status |
|---|---|---|
| AMB-01 | RF-6 dice "I numeri in blacklist vengono sempre rifiutati (anche senza invio SMS, secondo configurazione)". Chiarire il default: di default la blacklist rifiuta SENZA inviare SMS, con opzione utente per inviarlo. | Resolved — Default = nessun SMS per blacklist; flag per-chiamata/app per abilitarlo (SRS-401, SRS-502). |
| AMB-02 | RF-7 dice "All'apertura dell'app, gli SMS in ingresso sono intercettati". Chiarire se lettura continua in background o solo on-open: per vincoli Play e semplicità v1, lettura solo all'apertura dell'app (Inbox SMS letta on-open, nessun listener background permanente). | Resolved — Lettura on-open dell'inbox SMS con filtro (SRS-601). Nessun servizio background SMS in v1. |
| AMB-03 | "Numero visibile": include numeri privati/sconosciuti/bloccati (withheld)? | Resolved — Solo i numeri visibili (E.164/cifre presenti) sono valutati; numeri privati/anonimi/non presentati non sono rifiutati automaticamente (SRS-201). |
| AMB-04 | Cosa significa "tutte le info acquisite" in RF-3 oltre a numero/data-ora/esito/stato SMS? | Resolved — Set minimo chiuso: numero, data/ora, esito, stato SMS, origine decisione (rubrica/whitelist/blacklist/sconosciuto), note utente; null'altro è obbligatorio (SRS-301). |
| AMB-05 | Comportamento con rubrica non sincronizzata o contatto senza numero normalizzato (prefissi, spazi)? | Open — La normalizzazione E.164 sarà definita in architettura (AD); SRS richiede confronto dopo normalizzazione senza imporre l'algoritmo (SRS-202). |

---

## Definizioni

- **Numero visibile:** chiamante con ID presentecallable (cifre ottenibili da `Call.Details.getHandle()`); esclusi "Private/Unknown/Withheld".
- **In rubrica:** numero presente nei contatti del dispositivo (via `ContactsContract`) dopo normalizzazione.
- **Whitelist:** lista in-app di numeri che passano sempre.
- **Blacklist:** lista in-app di numeri rifiutati sempre.
- **Rifiuto:** `CallResponse` con `setDisallowCall(true)` + `setRejectCall(true)` (silenzia e disconnette), senza far squillare.
- **Testo SMS di default:** "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione."

---

## 1. Intercettazione chiamate (Call Screening)

### SRS-101
**Text:** The system shall intercept every incoming call through the native Kotlin `CallScreeningService` before the ringtone plays, on Android 10 (API 29) and above.
**Note:** Covers RF-1. Interception point is the OS screening callback, not the in-call UI. If the role is not held, no screening occurs (see SRS-1001).
**Tags:** `Call-Screening`, `Native`, `Android-10+`
**Trace:** UN-01 · RSK-02

### SRS-102
**Text:** The system shall obtain the caller number from the screened call details and shall classify the call as "number-visible" only when digits are present; calls with withheld/private/unknown presentation shall be classified as "number-not-visible".
**Note:** Only "number-visible" calls are eligible for auto-reject. Prevents acting on unidentifiable callers.
**Tags:** `Call-Screening`, `Classification`
**Trace:** UN-01

### SRS-103
**Text:** The system shall respond to the platform screening request within the platform timeout so that the ringtone is never delayed by screening.
**Note:** NFR affidabilità. Verification: screening response latency measured under platform limit on reference devices; timeout path lets the call through rather than hanging.
**Tags:** `Reliability`, `Performance`, `Platform`
**Trace:** UN-01 · RSK-03

---

## 2. Decisione di rifiuto

### SRS-201
**Text:** The system shall NOT auto-reject a call classified as "number-not-visible"; such calls shall be allowed to proceed normally.
**Note:** Explicit guard for private/unknown numbers. Covers AMB-03 resolution.
**Tags:** `Decision`, `Privacy`
**Trace:** UN-01

### SRS-202
**Text:** The system shall compare the visible caller number against device contacts and the in-app whitelist after phone-number normalisation; the system shall treat the number as "known" when it matches either source.
**Note:** Covers RF-2 / RF-5. Normalisation algorithm is an architecture decision; SRS requires only that comparison be normalisation-consistent (same normalisation for incoming number, contacts, and lists).
**Tags:** `Decision`, `Contacts`, `Whitelist`
**Trace:** UN-01 · UN-05

### SRS-203
**Text:** The system shall auto-reject a visible incoming call when the number is not in contacts and not in the whitelist.
**Note:** Core RF-2 behaviour. Reject = disallow + reject call via `CallResponse`, silenced/disconnected before ringing.
**Tags:** `Decision`, `Auto-Reject`
**Trace:** UN-01

### SRS-204
**Text:** The system shall auto-reject a visible incoming call when the number is in the blacklist, regardless of contacts state.
**Note:** Blacklist takes precedence (covers RF-6 + RF-10). If a number is simultaneously in contacts/whitelist and blacklist, blacklist wins and the conflict shall be surfaced in the number profile (see SRS-505).
**Tags:** `Decision`, `Blacklist`
**Trace:** UN-05

### SRS-205
**Text:** The system shall allow a visible incoming call to ring normally when the number is in contacts or in the whitelist and not in the blacklist.
**Note:** Covers RF-5. No SMS is sent for allowed calls.
**Tags:** `Decision`, `Allow`
**Trace:** UN-01 · UN-05

---

## 3. Registrazione tentativi (Call Log in-app)

### SRS-301
**Text:** The system shall record one log entry for every auto-rejected call containing exactly: caller number, date/time of the call, outcome = "rejected", SMS-send status, decision source (unknown / blacklist), and free-text user notes (empty by default).
**Note:** Covers RF-3 and AMB-04. No other mandatory fields. Optional display of contact-matched name only for non-rejected entries if ever shown.
**Tags:** `Logging`, `History`
**Trace:** UN-02 · RSK-04

### SRS-302
**Text:** The system shall make the rejected-call list visible in-app ordered by date/time descending and shall keep it readable with at least number, date/time, and SMS status visible per row without opening the detail.
**Note:** NFR usabilità. Testable via UI test: list renders ≥100 entries with row-level info and scroll without overlap/truncation of the three mandatory fields.
**Tags:** `Usability`, `History`
**Trace:** UN-02

### SRS-303
**Text:** The system shall allow the user to add or edit free-text notes on any rejected-call log entry.
**Note:** Notes are part of RF-3 "note". Stored locally only.
**Tags:** `History`, `Notes`
**Trace:** UN-02

---

## 4. SMS automatico al numero rifiutato

### SRS-401
**Text:** The system shall send exactly one automatic SMS to the rejected number after each auto-reject of an unknown (non-blacklist) number, using the currently configured template text.
**Note:** Covers RF-4. "Exactly one" prevents duplicate SMS on redial-screening retries for the same call session; retries of the same call ID shall not re-send.
**Tags:** `SMS-Send`, `Auto-Reply`
**Trace:** UN-03 · RSK-01 · RSK-05

### SRS-402
**Text:** The system shall NOT send the automatic SMS for blacklist rejections by default; the system shall send it for blacklist rejections only when the user has explicitly enabled "Send SMS also for blacklist" in settings.
**Note:** Covers RF-6 "secondo configurazione" and AMB-01. Default off.
**Tags:** `SMS-Send`, `Blacklist`, `Configuration`
**Trace:** UN-05 · UN-06

### SRS-403
**Text:** The system shall update the corresponding call-log entry with the SMS-send status set to one of: sent, failed, or not-sent (blacklist default), including the timestamp of the send attempt.
**Note:** Makes RF-3 "stato SMS inviato" verifiable. Failed includes carrier/radio errors (see SRS-901).
**Tags:** `SMS-Send`, `History`, `Observability`
**Trace:** UN-02 · UN-03 · RSK-05

### SRS-404
**Text:** The system shall pre-fill the SMS template with the default text: "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione."
**Note:** Default obbligatorio da brief. Editable per SRS-701.
**Tags:** `SMS-Send`, `Template`, `Default`
**Trace:** UN-03 · UN-06

---

## 5. Whitelist e Blacklist

### SRS-501
**Text:** The system shall support adding a phone number to the whitelist and to the blacklist, and removing it from either list.
**Note:** Covers RF-8 (aggiunta/rimozione). Add may originate from call log, SMS view, or manual entry.
**Tags:** `Whitelist`, `Blacklist`, `Management`
**Trace:** UN-05

### SRS-502
**Text:** The system shall store for each listed number a profile containing: number (identifier), display name, user notes, category, and date-added; all fields except number and date-added shall be user-editable.
**Note:** Covers RF-8 "profilo del numero modificabile". Category is a free or preset label (e.g., corriere, studio medico, spam) — preset list is a design choice, not imposed here.
**Tags:** `Whitelist`, `Blacklist`, `Profile`
**Trace:** UN-05

### SRS-503
**Text:** The system shall apply whitelist/blacklist decisions to call screening immediately, so that the next incoming call after a decision follows the updated behaviour without app restart.
**Note:** Covers RF-10. Testable: classify → place test call → verify new behaviour; max propagation delay defined in architecture but shall not require restart/reboot.
**Tags:** `Decision`, `Consistency`
**Trace:** UN-05

### SRS-504
**Text:** The system shall allow promoting a number directly from a rejected-call entry or from an inbound-SMS entry to the whitelist with the "Accetta (whitelist)" action, and banning it to the blacklist with the "Rifiuta (blacklist)" action.
**Note:** Covers RF-7 CTA + rapid classification need. One tap creates the list entry with number pre-filled; name/category remain editable afterwards.
**Tags:** `Whitelist`, `Blacklist`, `CTA`, `Usability`
**Trace:** UN-04 · UN-05

### SRS-505
**Text:** The system shall detect a number present in both whitelist and blacklist and shall enforce blacklist precedence while flagging the conflict in the number profile view.
**Note:** Deterministic tie-break required for testability of SRS-204. UI must show the conflict; silent dual-membership is prohibited.
**Tags:** `Whitelist`, `Blacklist`, `Data-Integrity`
**Trace:** UN-05

---

## 6. Intercettazione SMS in ingresso e classificazione

### SRS-601
**Text:** The system shall, on every app open, read the device SMS inbox and display inbound SMS messages in a dedicated in-app view grouped or filterable by sender number.
**Note:** Covers RF-7 as clarified in AMB-02: on-open inbox read, no permanent background SMS listener in v1. Requires `RECEIVE_SMS`/`READ_SMS` permission grant; without grant the view shows the permission prompt (see SRS-1004).
**Tags:** `SMS-Receive`, `Inbox`, `Permissions`
**Trace:** UN-04 · RSK-01

### SRS-602
**Text:** The system shall display on each inbound-SMS entry two actions: "Accetta (whitelist)" and "Rifiuta (blacklist)", performing the list update defined in SRS-504.
**Note:** Covers RF-7 CTA. Actions must be reachable without opening a separate screen (inline buttons on row or bottom sheet).
**Tags:** `SMS-Receive`, `CTA`, `Usability`
**Trace:** UN-04

### SRS-603
**Text:** The system shall prioritise in the SMS view the messages whose sender number matches a rejected-call log entry without a classification decision yet.
**Note:** Supports the core flow "chiamata rifiutata → risposta SMS → classifica". Testable: unmatched/new replies surface at top or under an "Awaiting classification" filter.
**Tags:** `SMS-Receive`, `Usability`, `History`
**Trace:** UN-02 · UN-04

---

## 7. Configurazione template SMS

### SRS-701
**Text:** The system shall allow the user to view and edit the automatic SMS text in-app, starting from the pre-filled default in SRS-404.
**Note:** Covers RF-9. Single active template in v1 (no multi-template).
**Tags:** `Settings`, `Template`
**Trace:** UN-06

### SRS-702
**Text:** The system shall validate the edited template before saving: it shall reject empty text and text exceeding a single-SMS length that the app declares (160 GSM-7 or 70 UCS-2 characters), showing which limit was violated.
**Note:** Prevents silent multi-part charges and carrier fragmentation. Declared limit must be visible in the editor. Multi-part sending is out of scope for v1.
**Tags:** `Settings`, `Validation`
**Trace:** UN-06 · RSK-05

### SRS-703
**Text:** The system shall use the saved template for all subsequent automatic SMS sends until the template is changed again.
**Note:** No per-number template override in v1.
**Tags:** `Settings`, `SMS-Send`
**Trace:** UN-06

---

## 8. Persistenza locale

### SRS-801
**Text:** The system shall persist the call history, whitelist, blacklist, number profiles, and SMS template in on-device storage so that all data survive app restart and device reboot.
**Note:** Covers NFR persistenza locale. No cloud/backend/sync in v1.
**Tags:** `Persistence`, `Local-Storage`
**Trace:** UN-02 · UN-05 · UN-06 · UN-07

### SRS-802
**Text:** The system shall perform all storage and screening decisions fully on-device; the system shall never transmit phone numbers, SMS content, contacts, or logs to any remote server.
**Note:** NFR privacy "nessun dato lascia il dispositivo". Testable via network-interception test: zero non-OS egress containing PII during screening/reject/SMS/classify flows.
**Tags:** `Privacy`, `Local-Only`, `Security`
**Trace:** UN-07 · RSK-04

---

## 9. Error Handling

### SRS-901
**Text:** The system shall handle SMS-send failure (no signal, airplane mode, carrier rejection, invalid destination) by marking the log entry as "failed" and showing a retry action on that entry; the system shall never retry automatically more than once per rejected call.
**Note:** Bounds retry storms and cost. Manual retry sends using the current template.
**Tags:** `Error-Handling`, `SMS-Send`, `Resilience`
**Trace:** UN-03 · RSK-05

### SRS-902
**Text:** The system shall present errors with a human-readable message and a correlation identifier (call-log ID or timestamp-based ID); error surfaces shall never include stack traces, internal class names, or other numbers' PII.
**Note:** Privacy-safe diagnostics per RSK-04.
**Tags:** `Error-Handling`, `Privacy`
**Trace:** UN-02 · RSK-04

### SRS-903
**Text:** The system shall, when required permissions or the call-screening role are missing at the time of an event, record the limiting condition (which permission/role is missing) without crashing and guide the user to grant it on next app open.
**Note:** Graceful degradation (e.g., screening skipped, SMS view shows permission gate).
**Tags:** `Error-Handling`, `Permissions`, `Usability`
**Trace:** UN-01 · RSK-01 · RSK-02

---

## 10. Platform / Cross-Cutting

### SRS-1001
**Text:** The system shall implement call interception exclusively in the native Kotlin module and shall expose a setup flow that requests the `ROLE_CALL_SCREENING` role from the user; until the role is granted, the app shall declare "protection inactive" in the UI.
**Note:** Covers vincolo di piattaforma. Flutter must not claim screening capability on its own; truth of protection state comes from the native role check via platform channel.
**Tags:** `Platform`, `Native`, `Permissions`, `Onboarding`
**Trace:** UN-01 · RSK-02

### SRS-1002
**Text:** The system shall communicate between the Flutter UI and the native module exclusively via a versioned platform channel, and shall reject calls from mismatched channel versions with a logged error and a user-visible "update required" state.
**Note:** Contract stability between UI and screening/SMS native code. Testable with version-mismatch injection.
**Tags:** `Platform`, `Flutter-Bridge`, `Compatibility`
**Trace:** UN-01

### SRS-1003
**Text:** The system shall target Android 10 (API 29) as minimum supported version and shall declare Android-only support; the system shall not claim iOS compatibility in UI, store listing text, or docs.
**Note:** iOS fuori perimetro per limiti di piattaforma (no runtime interception, no automatic SMS send/read).
**Tags:** `Platform`, `Android`, `Scope`
**Trace:** UN-01

### SRS-1004
**Text:** The system shall request at runtime only the permissions strictly needed (`READ_PHONE_STATE`, `READ_CALL_LOG`, `READ_CONTACTS`, `SEND_SMS`, `RECEIVE_SMS`/`READ_SMS`), each with an in-app rationale naming the exact feature it enables, and shall remain installed and navigable when any permission is denied, with the dependent feature marked unavailable.
**Note:** Minimises Play-review surface for restricted SMS permissions (RSK-01) and respects consent.
**Tags:** `Permissions`, `Privacy`, `Play-Policy`
**Trace:** UN-07 · RSK-01

### SRS-1005
**Text:** The system shall exclude phone numbers and SMS content from all logs (logcat, file logs, crash reports); logs shall contain only non-PII identifiers such as call-log IDs, timestamps, and status codes.
**Note:** NFR privacy "nessun PII nei log". Verifiable by log-inspection test over all flows.
**Tags:** `Logging`, `Privacy`, `GDPR`
**Trace:** UN-07 · RSK-04

### SRS-1006
**Text:** The system should document in-app and in the store listing that SMS permissions are used solely for the user-configured auto-reply and on-open reply triage, with no data leaving the device, to support Google Play restricted-permission declaration.
**Note:** "Should" because store approval is external, but the disclosure text is mandatory deliverable for the declaration form.
**Tags:** `Play-Policy`, `Transparency`, `Privacy`
**Trace:** UN-07 · RSK-01

---

## Requirements Traceability Summary

| SRS ID | Summary | RF | UN Trace | Risk Trace |
|---|---|---|---|---|
| SRS-101 | Intercept via CallScreeningService pre-ring | RF-1 | UN-01 | RSK-02 |
| SRS-102 | Visible vs not-visible classification | RF-1 | UN-01 | — |
| SRS-103 | Screening within platform timeout | NFR | UN-01 | RSK-03 |
| SRS-201 | No auto-reject for private/unknown | RF-2 | UN-01 | — |
| SRS-202 | Normalised match vs contacts + whitelist | RF-2/RF-5 | UN-01, UN-05 | — |
| SRS-203 | Auto-reject unknown visible | RF-2 | UN-01 | — |
| SRS-204 | Blacklist always rejected, precedence | RF-6 | UN-05 | — |
| SRS-205 | Contacts/whitelist ring normally | RF-5 | UN-01, UN-05 | — |
| SRS-301 | Log entry content | RF-3 | UN-02 | RSK-04 |
| SRS-302 | Readable log list, row-level info | RF-3/NFR | UN-02 | — |
| SRS-303 | User notes on log entries | RF-3 | UN-02 | — |
| SRS-401 | One auto-SMS per unknown reject | RF-4 | UN-03 | RSK-01, RSK-05 |
| SRS-402 | No SMS for blacklist by default + flag | RF-6 | UN-05, UN-06 | — |
| SRS-403 | SMS status + timestamp on log | RF-3 | UN-02, UN-03 | RSK-05 |
| SRS-404 | Default SMS text pre-filled | RF-4 | UN-03, UN-06 | — |
| SRS-501 | Add/remove whitelist/blacklist | RF-8 | UN-05 | — |
| SRS-502 | Number profile fields | RF-8 | UN-05 | — |
| SRS-503 | Immediate enforcement of decisions | RF-10 | UN-05 | — |
| SRS-504 | Accetta/Rifiuta CTA from log/SMS | RF-7 | UN-04, UN-05 | — |
| SRS-505 | Blacklist precedence + conflict flag | RF-6 | UN-05 | — |
| SRS-601 | On-open inbox read, dedicated view | RF-7 | UN-04 | RSK-01 |
| SRS-602 | Inline Accetta/Rifiuta on SMS entries | RF-7 | UN-04 | — |
| SRS-603 | Prioritise unclassified replies | RF-7/NFR | UN-02, UN-04 | — |
| SRS-701 | Editable SMS template | RF-9 | UN-06 | — |
| SRS-702 | Template validation (non-empty, single-SMS) | RF-9 | UN-06 | RSK-05 |
| SRS-703 | Saved template used henceforth | RF-9 | UN-06 | — |
| SRS-801 | On-device persistence across reboot | NFR | UN-02, UN-05, UN-06 | — |
| SRS-802 | Local-only, no data leaves device | NFR | UN-07 | RSK-04 |
| SRS-901 | SMS failure → failed + single retry | NFR | UN-03 | RSK-05 |
| SRS-902 | Safe error surfaces, no PII/stack | NFR | UN-02 | RSK-04 |
| SRS-903 | Missing permission/role handled gracefully | NFR | UN-01 | RSK-01, RSK-02 |
| SRS-1001 | Native role flow + inactive state | NFR | UN-01 | RSK-02 |
| SRS-1002 | Versioned platform channel | NFR | UN-01 | — |
| SRS-1003 | Android 10+ only, no iOS claim | Vincolo | UN-01 | — |
| SRS-1004 | Minimal runtime permissions + rationale | NFR | UN-07 | RSK-01 |
| SRS-1005 | No PII in logs | NFR | UN-07 | RSK-04 |
| SRS-1006 | In-app/store disclosure for Play declaration | Compliance | UN-07 | RSK-01 |

---

## Appendice A — Acceptance Criteria per flusso (sintesi PM)

- **UC-01 Sconosciuto:** SIM test chiama da numero visibile non in rubrica → nessuna suoneria, log con numero+ora+rejected, 1 SMS col template corrente, stato `sent`, nessun dato in rete extra-device.
- **UC-02 Whitelist:** numero in whitelist chiama → squilla normalmente, nessun log rejected, nessun SMS.
- **UC-03 Blacklist:** numero in blacklist chiama → rifiutata, log con source=blacklist, stato SMS `not-sent` di default.
- **UC-04 Replica SMS:** risposta SMS all'apertura app → in vista dedicata con CTA inline; Accetta sposta in whitelist (chiamata successiva squilla), Rifiuta sposta in blacklist (chiamata successiva rifiutata) senza riavvio.
- **UC-05 Liste:** aggiunta/rimozione/modifica profilo (nome, note, categoria, data aggiunta) persistono dopo reboot.
- **UC-06 Template:** default precompilato, edit validato (non vuoto, single-SMS), usato dagli invii successivi.

## Appendice B — Rischi e compliance (sintesi)

- Dichiarazione Play per `SEND_SMS`/`RECEIVE_SMS` con video dimostrativo del core-feature (auto-reply + triage); senza approvazione valutare distribuzione fuori Play.
- Consenso: rationale per-permesso, stato "protezione inattiva" se ruolo non assegnato.
- PII: solo on-device, nessun PII nei log, nessuna sincronizzazione.

---

*End of Document — CG-SRS-001 v0.1.0*
*Next in package: CG-ARCH-001 — Software Architecture*
