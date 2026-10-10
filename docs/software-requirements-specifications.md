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
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft — requisiti compilati dal brief Call Guard (RF-1…RF-10) |

---

## Document Scope

Questo documento definisce tutti i Software Requirements Specifications (SRS) di **Call Guard**, app Android per la gestione delle chiamate da numeri sconosciuti. Ogni requisito è singolare, non ambiguo, atomico e testabile indipendentemente. I requisiti sono organizzati per area funzionale e ciascuno traccia ad almeno un User Need.

Contesto richiamato:

- **Overview:** l'app intercetta le chiamate in ingresso prima che squillino; se il numero è visibile e non è in rubrica/whitelist, rifiuta la chiamata, la registra e invia un SMS automatico configurabile. All'apertura dell'app, gli SMS di risposta vengono mostrati con azioni rapide ACCETTA (whitelist) / RIFIUTA (blacklist).
- **User Needs:**
  - UN-01 — Non essere disturbato da numeri sconosciuti (nessuno squillo per numeri non in rubrica).
  - UN-02 — Avere una traccia consultabile di ogni tentativo rifiutato (numero, data/ora, esito, stato SMS).
  - UN-03 — Classificare rapidamente un numero in base a come si presenta via SMS (promuovi/bandisci in 1–2 tocchi).
  - UN-04 — Personalizzare il testo dell'SMS automatico, con un default pronto all'uso.
  - UN-05 — Gestire whitelist/blacklist con profilo del numero (nome, note, categoria).
  - UN-06 — Nessun dato personale lascia il dispositivo.
- **Rischi:**
  - RSK-01 — Policy Google Play su permessi SMS/telefono (SEND_SMS / RECEIVE_SMS restricted, rischio pubblicazione).
  - RSK-02 — Timeout del call screening di piattaforma (la risposta oltre il limite ritarda o manca il blocco).
  - RSK-03 — Esposizione PII (numeri di telefono) nei log o fuori dal dispositivo.
  - RSK-04 — Rifiuto inaffidabile al variare di rete/carrier/dispositivo.
  - RSK-05 — Ruolo di call screening non assegnato dall'utente (l'app non può operare).
  - RSK-06 — Perdita di cronologia/liste al riavvio o all'aggiornamento.
- **Componenti di piattaforma citati:** modulo nativo Kotlin `CallScreeningService`, ruolo `ROLE_CALL_SCREENING` (Android 10+), UI Flutter + platform channel, permessi `READ_CONTACTS`, `READ_PHONE_STATE`, `SEND_SMS`, `RECEIVE_SMS`/`READ_SMS`.

Piattaforma: Android-only. iOS fuori perimetro. Nessun cloud/backend, nessuna sincronizzazione, nessuna gestione delle chiamate in uscita.

---

## Ambiguities & Clarifications

| ID | Item | Status |
|---|---|---|
| AMB-01 | RF-6: i numeri in blacklist "sempre rifiutati (anche senza invio SMS, secondo configurazione)". Ambiguità: l'invio SMS per blacklist è on/off? Decisione: default OFF (nessun SMS ai blacklistati), con toggle esplicito in impostazioni. | Resolved — default OFF + toggle; vedi SRS-502, SRS-710 |
| AMB-02 | Numeri nascosti/sconosciuti (caller ID soppresso) e numeri non validi: vanno rifiutati? Decisione: NO — RF-2 richiede numero visibile; i numeri nascosti passano normalmente e non generano SMS. | Resolved — vedi SRS-304, SRS-305 |
| AMB-03 | "Intercettazione SMS all'apertura dell'app": lettura retroattiva vs solo a foreground? Decisione: all'apertura l'app legge gli SMS ricevuti (provider SMS) e mostra quelli provenienti da numeri in cronologia chiamate rifiutate e non ancora classificati. Nessun listener background oltre quanto concesso dai permessi dichiarati. | Resolved — vedi SRS-601…SRS-604 |
| AMB-04 | Contatto in rubrica ma anche in blacklist: quale regola prevale? Decisione: prevale la blacklist (rifiuto). Whitelist esplicita prevale sulla rubrica solo come equivalenza (nessun rifiuto in entrambi i casi). | Resolved — vedi SRS-306, SRS-703 |
| AMB-05 | Comportamento dual-SIM e inoltri operatore: il rifiuto via CallScreeningService è garantito su tutti i carrier? | Open — da verificare in test su device/SIM reali prima del disegno architetturale; mitigato da SRS-1004 e RSK-04 |

---

## 1. Configurazione e bootstrap

### SRS-101
**Text:** The system shall pre-populate the auto-reply SMS text with the default "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione." on first launch when no user value exists.
**Note:** Copre RF-9. Il default non deve mai essere vuoto al primo avvio.
**Tags:** `Configuration`, `Boot`
**Trace:** UN-04

---

### SRS-102
**Text:** The system shall persist the user-configured SMS text across restarts and app updates and shall use the persisted value for every auto-reply until changed again.
**Note:** Test: modifica testo → kill + riavvio → nuova chiamata rifiutata usa il testo modificato.
**Tags:** `Configuration`, `Persistence`
**Trace:** UN-04 · RSK-06

---

### SRS-103
**Text:** The system shall expose a Boolean setting "Invia SMS ai numeri in blacklist", default false, persisted across restarts.
**Note:** Risolve AMB-01. Default OFF per evitare spam verso spammer noti.
**Tags:** `Configuration`, `Blacklist`
**Trace:** UN-01 · RSK-01

---

## 2. Contesto piattaforma, ruoli e permessi

### SRS-201
**Text:** The system shall implement inbound-call interception exclusively in the native Kotlin module via `CallScreeningService` on Android 10+ with the `ROLE_CALL_SCREENING` role; the Flutter layer shall never implement call interception directly.
**Note:** Vincolo di piattaforma. iOS escluso.
**Tags:** `Platform`, `Architecture`, `Android`
**Trace:** UN-01 · RSK-02

---

### SRS-202
**Text:** The system shall detect whether the `ROLE_CALL_SCREENING` role is held and, when it is not held, shall display a blocking state in-app with a single action that opens the system role request, and shall not claim to be protecting the user.
**Note:** Senza ruolo, RF-1/RF-2 non possono operare. Mitiga RSK-05.
**Tags:** `Platform`, `Permissions`, `Usability`
**Trace:** UN-01 · RSK-05

---

### SRS-203
**Text:** The system shall request and operate only with the declared sensitive permissions (`READ_CONTACTS`, `READ_PHONE_STATE`, `SEND_SMS`, `RECEIVE_SMS`/`READ_SMS`) and shall disable each dependent feature with an explicit message when the corresponding permission is denied.
**Note:** Chiamata senza READ_CONTACTS = nessun confronto rubrica; SMS senza SEND_SMS = nessun invio. Rilevante per RSK-01 (giustificazione Play).
**Tags:** `Permissions`, `Security`, `Play-Policy`
**Trace:** UN-01 · RSK-01

---

## 3. Screening e rifiuto chiamate

### SRS-301
**Text:** The system shall intercept every incoming call in `CallScreeningService.onScreenCall` before the ringtone and shall issue a screening decision within the platform timeout.
**Note:** Copre RF-1. NFR: nessuna attesa di rete o I/O lento nel percorso di screening; solo lookup locali (rubrica/whitelist/blacklist).
**Tags:** `Call-Screening`, `Reliability`
**Trace:** UN-01 · RSK-02

---

### SRS-302
**Text:** The system shall reject (disconnect and silence) an incoming call if and only if the caller number is visible AND not found in contacts AND not found in whitelist AND the call-screening role is held.
**Note:** Copre RF-2 + RF-5 (whitelist passa). "Numero visibile" = E.164/nazionale normalizzato non vuoto e non hidden/withheld.
**Tags:** `Call-Screening`, `Rejection`
**Trace:** UN-01 · RSK-02

---

### SRS-303
**Text:** The system shall let calls from numbers present in the device contacts pass normally without rejection, logging, or auto-SMS.
**Note:** La rubrica equivale a whitelist implicita; nessuna registrazione per non inquinare la cronologia (vedi SRS-401 per i rifiutati).
**Tags:** `Call-Screening`, `Contacts`
**Trace:** UN-01

---

### SRS-304
**Text:** The system shall let calls with hidden, suppressed, or empty caller ID pass normally and shall never send an auto-reply SMS for them.
**Note:** Risolve AMB-02. Non esiste un destinatario SMS; rifiutare gli anonimi è fuori scope approvato.
**Tags:** `Call-Screening`, `Edge-Case`
**Trace:** UN-01

---

### SRS-305
**Text:** The system shall never send an auto-reply SMS to short codes, alphanumeric sender IDs, or numbers that fail E.164/national dialability validation.
**Note:** Evita costi/errori su mittenti non richiamabili.
**Tags:** `Call-Screening`, `SMS-Safety`
**Trace:** UN-01 · RSK-01

---

### SRS-306
**Text:** The system shall always reject calls from numbers in the blacklist, even when the number is also present in device contacts, subject to SRS-502 for SMS behaviour.
**Note:** Risolve AMB-04. Copre RF-6. La blacklist prevale su rubrica e whitelist.
**Tags:** `Call-Screening`, `Blacklist`
**Trace:** UN-01

---

### SRS-307
**Text:** The system shall apply a whitelist or blacklist decision to the very next incoming call from that number without requiring app restart.
**Note:** Copre RF-10. Test: classifica → richiama dallo stesso numero → nuovo comportamento immediato.
**Tags:** `Call-Screening`, `Consistency`
**Trace:** UN-03

---

## 4. Registrazione tentativi

### SRS-401
**Text:** The system shall persist one history record for every rejected call containing: caller number, date/time of the call, outcome=rejected, SMS-sent status (sent / failed / skipped with reason), and free-text notes (empty by default).
**Note:** Copre RF-3. Un record per chiamata, mai aggregati.
**Tags:** `History`, `Persistence`
**Trace:** UN-02 · RSK-06

---

### SRS-402
**Text:** The system shall update the SMS-sent status of the history record when the auto-reply send completes or fails, recording the failure reason (e.g., no permission, invalid number, radio error) without recording message content beyond the template reference.
**Note:** Lo stato SMS è parte della traccia consultabile (RF-3).
**Tags:** `History`, `SMS-Status`
**Trace:** UN-02

---

### SRS-403
**Text:** The system shall retain call history across device restarts and app updates and shall order the in-app list by date/time descending.
**Note:** NFR persistenza locale. Nessun backend.
**Tags:** `History`, `Persistence`, `Usability`
**Trace:** UN-02 · RSK-06

---

## 5. SMS automatico di risposta

### SRS-501
**Text:** The system shall send exactly one auto-reply SMS to the rejected caller number using the persisted template text for every rejected call, except for blacklist numbers when the SRS-103 setting is false and except for numbers excluded by SRS-304/SRS-305.
**Note:** Copre RF-4 + RF-6. "Exactly one" = nessun doppio invio su retry di screening.
**Tags:** `Auto-SMS`, `Idempotency`
**Trace:** UN-01 · RSK-01

---

### SRS-502
**Text:** The system shall skip the auto-reply SMS for blacklist numbers when the "Invia SMS ai numeri in blacklist" setting is false, and shall record skipped/blacklisted as the SMS status.
**Note:** Default OFF per SRS-103.
**Tags:** `Auto-SMS`, `Blacklist`
**Trace:** UN-01

---

### SRS-503
**Text:** The system shall allow the user to edit the auto-reply SMS text in-app, shall validate that the text is non-empty and within a single-SMS or concatenated-SMS limit declared in-app, and shall reject empty saves with an explicit error.
**Note:** Copre RF-9. Il limite va dichiarato (es. 480 caratteri) e testato.
**Tags:** `Auto-SMS`, `Configuration`, `Validation`
**Trace:** UN-04

---

## 6. Intercettazione SMS e classificazione rapida

### SRS-601
**Text:** The system shall, on every app foreground/open, read inbound SMS messages and display those received from numbers present in the rejected-call history and not yet classified in a dedicated view showing number, date/time, message body, and linked call record.
**Note:** Copre RF-7. Risolve AMB-03: nessuna pretesa di realtime-background oltre i permessi dichiarati.
**Tags:** `SMS-Interception`, `Classification`
**Trace:** UN-03 · RSK-01

---

### SRS-602
**Text:** The system shall present exactly two primary actions on each unclassified inbound SMS: "Accetta (whitelist)" and "Rifiuta (blacklist)".
**Note:** Copre RF-7. CTA sempre visibili senza menu annidati (NFR usabilità).
**Tags:** `SMS-Interception`, `Usability`
**Trace:** UN-03

---

### SRS-603
**Text:** The system shall, on "Accetta (whitelist)", add the number to the whitelist with source=SMS-classification and timestamp, and shall remove its pending-classification state.
**Note:** La classificazione aggiorna immediatamente lo screening (SRS-307).
**Tags:** `Classification`, `Whitelist`
**Trace:** UN-03

---

### SRS-604
**Text:** The system shall, on "Rifiuta (blacklist)", add the number to the blacklist with source=SMS-classification and timestamp, and shall remove its pending-classification state.
**Note:** Simmetrico a SRS-603.
**Tags:** `Classification`, `Blacklist`
**Trace:** UN-03

---

## 7. Whitelist, blacklist e profilo numero

### SRS-701
**Text:** The system shall support add, remove, and edit operations on whitelist and blacklist entries, where each entry holds: number (unique, normalized), display name, notes, category, date-added, and source (manual / SMS-classification / call-history).
**Note:** Copre RF-8. Numero normalizzato = chiave univoca.
**Tags:** `Lists`, `CRUD`
**Trace:** UN-05

---

### SRS-702
**Text:** The system shall enforce that a number exists in at most one of whitelist or blacklist at any time; adding it to one list shall remove it from the other and record the move.
**Note:** Evita decisioni di screening contraddittorie.
**Tags:** `Lists`, `Data-Integrity`
**Trace:** UN-05

---

### SRS-703
**Text:** The system shall evaluate screening precedence as: blacklist > contacts/whitelist-pass > unknown-reject, i.e., blacklist always rejects per SRS-306.
**Note:** Fissa la semantica di AMB-04 in requisito testabile.
**Tags:** `Lists`, `Call-Screening`
**Trace:** UN-01

---

### SRS-704
**Text:** The system shall allow promoting any rejected-call history number to whitelist or blacklist directly from the history list with a single action per choice.
**Note:** "Promuovi/bandisci" rapido anche senza SMS di risposta (estende RF-7/RF-8).
**Tags:** `Lists`, `Usability`
**Trace:** UN-03

---

### SRS-705
**Text:** The system shall persist whitelist and blacklist across restarts and app updates.
**Note:** NFR persistenza; perdita liste = regressione critica.
**Tags:** `Lists`, `Persistence`
**Trace:** UN-05 · RSK-06

---

## 8. Ricerca, liste e dettaglio

### SRS-801
**Text:** The system shall display the rejected-call history, whitelist, and blacklist as three separate readable lists, each supporting filter by number substring and sort by date-added/date-call descending.
**Note:** NFR leggibilità; filtro minimo obbligatorio, nessun filtro su campi non dichiarati.
**Tags:** `Search`, `Usability`
**Trace:** UN-02 · UN-05

---

### SRS-802
**Text:** The system shall provide a number-profile detail view showing linked history records, list membership, name, notes, category, and dates, with edit actions for name, notes, and category.
**Note:** Copre "profilo del numero modificabile" (RF-8).
**Tags:** `Detail`, `Usability`
**Trace:** UN-05

---

## 9. Error Handling

### SRS-901
**Text:** The system shall surface screening/SMS failures (missing role, missing permission, SMS send failure) in-app with a human-readable message and a corrective action, using a machine-readable error code internally; error surfaces shall never display full phone numbers beyond the already-known list context nor stack traces.
**Note:** Nessun PII aggiuntivo nelle schermate di errore; niente stack trace all'utente.
**Tags:** `Error-Handling`, `Privacy`
**Trace:** UN-02 · RSK-03

---

### SRS-902
**Text:** The system shall queue a failed auto-reply SMS for at most one manual retry from the history record and shall never auto-retry in background without user action.
**Note:** Evita invii multipli e costi imprevisti; "exactly one" automatico resta (SRS-501).
**Tags:** `Error-Handling`, `Auto-SMS`
**Trace:** UN-02 · RSK-01

---

## 10. Piattaforma / Cross-Cutting (NFR)

### SRS-1001
**Text:** The system shall complete the call-screening decision using only on-device lookups and shall not perform any network call in the screening path.
**Note:** Controllo di affidabilità per RSK-02/RSK-04; test con network disabilitata.
**Tags:** `Reliability`, `Performance`
**Trace:** UN-01 · RSK-02

---

### SRS-1002
**Text:** The system shall store all phone numbers, SMS bodies, history, and lists exclusively in on-device storage and shall include no network sync, analytics, or backup transmitting phone numbers off-device.
**Note:** NFR privacy: nessun dato lascia il dispositivo. Qualsiasi futura sync richiede Change Request.
**Tags:** `Privacy`, `Data-Locality`
**Trace:** UN-06 · RSK-03

---

### SRS-1003
**Text:** The system shall exclude full phone numbers and SMS bodies from all logs (logcat, crash reports, file logs); logs may contain only hashes or truncated prefixes for diagnostics.
**Note:** Controllo RSK-03. Verificabile per ispezione log.
**Tags:** `Logging`, `Privacy`
**Trace:** UN-06 · RSK-03

---

### SRS-1004
**Text:** The system shall degrade gracefully when the screening role is missing, permissions are denied, or SMS send fails: calls pass through normally, the user is notified in-app, and no partial state (record senza esito, SMS fantasma) is left unwritten.
**Note:** Fail-open sulle chiamate (mai bloccare tutto), fail-explicit sulla UI. Mitiga RSK-04/RSK-05.
**Tags:** `Resilience`, `Usability`
**Trace:** UN-01 · RSK-04

---

### SRS-1005
**Text:** The system shall support Android 10 and above only and shall refuse to enable call protection on unsupported versions with an explicit incompatibility message.
**Note:** Vincolo Android-only; iOS e Android <10 fuori perimetro.
**Tags:** `Platform`, `Compatibility`
**Trace:** UN-01

---

## Requirements Traceability Summary

| SRS ID | Summary | RF | UN Trace | Risk Trace |
|---|---|---|---|---|
| SRS-101 | Default SMS precompilato | RF-9 | UN-04 | — |
| SRS-102 | Persistenza testo SMS | RF-9 | UN-04 | RSK-06 |
| SRS-103 | Toggle SMS per blacklist (default OFF) | RF-6 | UN-01 | RSK-01 |
| SRS-201 | Screening nel nativo Kotlin, Android 10+ | RF-1 | UN-01 | RSK-02 |
| SRS-202 | Stato bloccante se ruolo mancante | RF-1 | UN-01 | RSK-05 |
| SRS-203 | Permessi sensibili con feature-gate | RF-1…RF-7 | UN-01 | RSK-01 |
| SRS-301 | Intercettazione prima dello squillo entro timeout | RF-1 | UN-01 | RSK-02 |
| SRS-302 | Rifiuto se visibile e non in rubrica/whitelist | RF-2 | UN-01 | RSK-02 |
| SRS-303 | Contatti passano senza log/SMS | RF-2 | UN-01 | — |
| SRS-304 | Anonimi passano, mai SMS | RF-2 | UN-01 | — |
| SRS-305 | Mai SMS a short code / non composti | RF-4 | UN-01 | RSK-01 |
| SRS-306 | Blacklist prevale sempre (rifiuto) | RF-6 | UN-01 | — |
| SRS-307 | Decisioni effettive dalla chiamata successiva | RF-10 | UN-03 | — |
| SRS-401 | Record per chiamata rifiutata | RF-3 | UN-02 | RSK-06 |
| SRS-402 | Stato invio SMS nel record | RF-3 | UN-02 | — |
| SRS-403 | Cronologia persiste, ordinata discendente | RF-3 | UN-02 | RSK-06 |
| SRS-501 | Un solo SMS automatico per rifiuto | RF-4 | UN-01 | RSK-01 |
| SRS-502 | Skip SMS per blacklist se toggle OFF | RF-6 | UN-01 | — |
| SRS-503 | Modifica testo SMS validata | RF-9 | UN-04 | — |
| SRS-601 | Vista SMS in ingresso all'apertura | RF-7 | UN-03 | RSK-01 |
| SRS-602 | Due CTA: Accetta / Rifiuta | RF-7 | UN-03 | — |
| SRS-603 | Accetta → whitelist | RF-7 | UN-03 | — |
| SRS-604 | Rifiuta → blacklist | RF-7 | UN-03 | — |
| SRS-701 | CRUD liste + profilo numero | RF-8 | UN-05 | — |
| SRS-702 | Mutua esclusione whitelist/blacklist | RF-8 | UN-05 | — |
| SRS-703 | Precedenza blacklist > pass > reject | RF-5/RF-6 | UN-01 | — |
| SRS-704 | Promozione diretta dalla cronologia | RF-8 | UN-03 | — |
| SRS-705 | Liste persistenti | RF-8 | UN-05 | RSK-06 |
| SRS-801 | Tre liste con filtro e ordinamento | RF-3/RF-8 | UN-02 · UN-05 | — |
| SRS-802 | Dettaglio profilo numero modificabile | RF-8 | UN-05 | — |
| SRS-901 | Errori con azione correttiva, no PII extra | — | UN-02 | RSK-03 |
| SRS-902 | Un solo retry manuale per SMS fallito | RF-4 | UN-02 | RSK-01 |
| SRS-1001 | Screening solo on-device, no rete | RF-1 | UN-01 | RSK-02 |
| SRS-1002 | Nessun dato lascia il dispositivo | — | UN-06 | RSK-03 |
| SRS-1003 | No PII nei log | — | UN-06 | RSK-03 |
| SRS-1004 | Degrado graceful (fail-open chiamate) | RF-1 | UN-01 | RSK-04 |
| SRS-1005 | Solo Android 10+, messaggio se incompatibile | — | UN-01 | — |

---

*End of Document — CG-SRS-001 v0.1.0*
*Next in package: CG-ARCH-001 — Software Architecture*
