# Call Guard — Software Requirements Specifications

**Document ID:** CG-SRS-001
**Version:** 0.1.0
**Status:** Draft
**Service:** `call-guard`
**Last Updated:** 2026-10-10
**Trace Parents:** CG-UN-001 · CG-UC-001 · CG-RSK-001

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
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft da brief Call Guard (RF-1…RF-10, vincoli Android, rischi Play/PII) |

---

## Document Scope

Questo documento definisce tutti i requisiti software di **Call Guard**, app Android per la gestione delle chiamate da numeri sconosciuti: intercettazione prima dello squillo, rifiuto automatico dei numeri visibili non in rubrica/whitelist, registrazione locale del tentativo, risposta automatica via SMS configurabile, e classificazione rapida (whitelist/blacklist) delle risposte ricevute.

Ogni requisito è atomico, non ambiguo e verificabile singolarmente con "shall" (obbligatorio), "should" (raccomandato), "may" (opzionale). I requisiti coprono integralmente RF-1…RF-10 del brief e i vincoli di piattaforma (modulo nativo Kotlin con `CallScreeningService`, ruolo `ROLE_CALL_SCREENING`, Android 10+; UI Flutter via platform channel). Requisiti fuori perimetro (iOS, cloud/backend, sync multi-dispositivo, chiamate in uscita) non generano requisiti e sono esclusi esplicitamente in §10.

Riferimenti genitori assunti dal brief (in assenza di package completo):

- UN-01: filtrare automaticamente le chiamate da numeri sconosciuti senza far squillare il telefono.
- UN-02: avere una traccia consultabile di ogni tentativo rifiutato (numero, data/ora, esito, SMS).
- UN-03: rispondere automaticamente al chiamante sconosciuto chiedendo di identificarsi via SMS.
- UN-04: classificare rapidamente un numero che risponde via SMS come affidabile (whitelist) o indesiderato (blacklist).
- UN-05: gestire whitelist/blacklist e il profilo di ogni numero (nome, note, categoria).
- UN-06: personalizzare il testo della risposta automatica.
- RSK-01: rifiuto da Google Play per permessi SMS/telefono restricted.
- RSK-02: trattamento PII (numeri di telefono) solo on-device, nessun PII nei log.
- RSK-03: mancato rifiuto o squillo tardivo per timeout carrier/piattaforma o ruolo non assegnato.
- RSK-04: comportamento errato su numeri nascosti/anonimi o guasto invio SMS.

---

## Ambiguities & Clarifications

| ID | Item | Status |
|---|---|---|
| AMB-01 | Numero chiamante nascosto/soppresso (nessun numero visibile): l'app non può inviare SMS né classificare il numero. Decisione: nessun rifiuto automatico obbligatorio; se la piattaforma lo segnala, viene registrato come "sconosciuto senza numero" e non genera SMS. | Resolved — cfr. SRS-103, SRS-204, SRS-304 |
| AMB-02 | Numeri in blacklist: inviare o no l'SMS automatico? Decisione: di default la blacklist rifiuta silenziosamente senza SMS; l'invio per numeri in blacklist è disattivabile/attivabile da configurazione (default = OFF). | Resolved — cfr. SRS-305, SRS-403 |
| AMB-03 | "Prima che squillino": su Android il `CallScreeningService` può bloccare/silenziare prima che l'utente percepisca lo squillo, ma un ritardo minimo di rete/carrier è possibile. Decisione: il requisito è "rispondere entro il timeout di piattaforma senza ritardare la suoneria oltre i limiti di sistema", non "zero squilli garantiti". | Resolved — cfr. SRS-104, SRS-901 |
| AMB-04 | Intercettazione SMS "all'apertura dell'app": lettura retroattiva via `RECEIVE_SMS`/provider SMS vs. solo SMS ricevuti ad app aperta. Decisione: all'apertura l'app rilegge gli SMS in ingresso pertinenti (risposte a numeri precedentemente rifiutati o da mittenti non in rubrica) e li mostra nella vista dedicata. | Resolved — cfr. SRS-501, SRS-502 |

---

## 1. Intercettazione e rifiuto chiamate

### SRS-101
**Text:** The system shall intercept every incoming call via the native Kotlin `CallScreeningService` before the user-perceived ring.
**Note:** Modulo nativo obbligatorio; la UI Flutter non intercetta chiamate. Copre RF-1.
**Tags:** `Call-Screening`, `Native-Kotlin`, `Android-10+`
**Trace:** UN-01 · RSK-03

### SRS-102
**Text:** The system shall automatically reject (disconnect/silence via `CallResponse`) an incoming call if and only if the caller number is visible AND is not in the device contacts AND is not in the whitelist.
**Note:** Un solo comportamento per requisito. Numeri nascosti esclusi (SRS-103). Whitelist vince sempre (SRS-402). Copre RF-2.
**Tags:** `Call-Screening`, `Reject-Rule`
**Trace:** UN-01 · RSK-03

### SRS-103
**Text:** The system shall never attempt to send an SMS to a hidden/withheld caller number, and shall not treat a hidden number as a classifiable whitelist/blacklist entry.
**Note:** Senza numero non esiste destinatario SMS né profilo numero. Copre AMB-01.
**Tags:** `Call-Screening`, `Privacy`, `Edge-Case`
**Trace:** UN-03 · RSK-02

### SRS-104
**Text:** The system shall return the screening decision within the platform timeout so that normal ringing behaviour for allowed calls is not delayed beyond system limits.
**Note:** Requisito di affidabilità misurabile nei test con chiamate reali/emulate: nessuna ANR, nessuna suoneria ritardata per chiamate lecite oltre la tolleranza di piattaforma. Copre NFR affidabilità.
**Tags:** `Performance`, `Reliability`, `Platform`
**Trace:** UN-01 · RSK-03

### SRS-105
**Text:** The system shall operate only if the user has granted the app the `ROLE_CALL_SCREENING` role; if the role is not held, the system shall not claim to filter calls and shall prompt the user to assign the role.
**Note:** Senza ruolo, Android non consegna le chiamate allo screener. Stato ruolo sempre visibile in-app.
**Tags:** `Platform`, `Permissions`, `UX`
**Trace:** UN-01 · RSK-03

---

## 2. Registrazione dei tentativi rifiutati

### SRS-201
**Text:** The system shall persist every automatically rejected call as an entry in the in-app call history.
**Note:** Copre RF-3 (esistenza della registrazione). Il dettaglio dei campi è nei requisiti seguenti.
**Tags:** `History`, `Persistence`
**Trace:** UN-02

### SRS-202
**Text:** The system shall record for each rejected call the caller number in E.164/normalized form as displayed by the platform.
**Note:** Il numero è PII: solo storage locale, mai nei log (SRS-904).
**Tags:** `History`, `PII`
**Trace:** UN-02 · RSK-02

### SRS-203
**Text:** The system shall record for each rejected call the date and time of the attempt in the device local timezone with second precision.
**Note:** Usa l'orologio di sistema al momento dello screening; nessun timestamp fornito dal chiamante.
**Tags:** `History`, `Audit`
**Trace:** UN-02

### SRS-204
**Text:** The system shall record for each rejected call the outcome, with at least the values `rifiutata`, `consentita-whitelist`, `rifiutata-blacklist`, `sconosciuto-senza-numero`.
**Note:** L'esito consente di distinguere filtro automatico, whitelist e blacklist. Copre RF-3 ("esito").
**Tags:** `History`, `Audit`
**Trace:** UN-02

### SRS-205
**Text:** The system shall record for each rejected call the SMS status with at least the values `inviato`, `non-inviato`, `fallito`, `non-applicabile`.
**Note:** "Non-applicabile" per numeri nascosti e blacklist con SMS disattivato. Copre RF-3 ("stato SMS inviato").
**Tags:** `History`, `SMS`
**Trace:** UN-02 · UN-03

### SRS-206
**Text:** The system shall allow the user to attach and edit a free-text note on each history entry.
**Note:** Copre RF-3 ("note"). La nota è separata dalle note del profilo numero (SRS-406).
**Tags:** `History`, `UX`
**Trace:** UN-02 · UN-05

---

## 3. SMS automatico di risposta

### SRS-301
**Text:** The system shall automatically send an SMS to the rejected visible unknown number immediately after rejection.
**Note:** Invio via API SMS Android con permesso `SEND_SMS`. Copre RF-4 (caso base).
**Tags:** `SMS`, `Automation`
**Trace:** UN-03 · RSK-01

### SRS-302
**Text:** The system shall pre-fill the automatic SMS text with the following default: "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione."
**Note:** Default esatto da brief, modificabile (SRS-601). Copre RF-4 + RF-9.
**Tags:** `SMS`, `Configuration`, `Default-Text`
**Trace:** UN-03 · UN-06

### SRS-303
**Text:** The system shall send the automatic SMS using the user-configured text in force at the moment of rejection.
**Note:** Una sola variabile per requisito (il corpo del testo). La modifica del testo è SRS-601.
**Tags:** `SMS`, `Configuration`
**Trace:** UN-03 · UN-06

### SRS-304
**Text:** The system shall not send the automatic SMS when the caller number is hidden or invalid as a SMS destination.
**Note:** Controllo anti-spreco/anti-errore; lo storico riporta `non-applicabile`. Copre AMB-01.
**Tags:** `SMS`, `Edge-Case`
**Trace:** UN-03 · RSK-04

### SRS-305
**Text:** The system shall not send the automatic SMS for numbers in the blacklist when the "SMS per blacklist" setting is OFF (factory default OFF).
**Note:** Copre RF-6 ("anche senza invio SMS, secondo configurazione") e AMB-02. L'impostazione ON/OFF è SRS-602.
**Tags:** `SMS`, `Blacklist`, `Configuration`
**Trace:** UN-03 · RSK-04

### SRS-306
**Text:** The system shall update the history entry SMS status to `fallito` if the SMS send fails, and shall keep the call entry.
**Note:** Il fallimento SMS non cancella la registrazione della chiamata. Base per retry manuale futuro (non obbligatorio in questa versione).
**Tags:** `SMS`, `Error-Handling`, `History`
**Trace:** UN-02 · UN-03 · RSK-04

---

## 4. Whitelist e Blacklist

### SRS-401
**Text:** The system shall always reject incoming calls from numbers in the blacklist, regardless of contacts content.
**Note:** Blacklist vince sulla rubrica ai fini del rifiuto. Copre RF-6 (prima parte).
**Tags:** `Blacklist`, `Call-Screening`
**Trace:** UN-01 · UN-04

### SRS-402
**Text:** The system shall never automatically reject incoming calls from numbers in the whitelist; such calls shall ring normally.
**Note:** Whitelist vince sul filtro sconosciuti. Copre RF-5.
**Tags:** `Whitelist`, `Call-Screening`
**Trace:** UN-01 · UN-04

### SRS-403
**Text:** The system shall evaluate screening decisions with the following precedence: blacklist > whitelist > contacts > unknown-visible-reject.
**Note:** Ordine deterministico e testabile; risolve i conflitti (es. numero sia in rubrica sia in blacklist → rifiutato).
**Tags:** `Call-Screening`, `Rules`
**Trace:** UN-01 · UN-04

### SRS-404
**Text:** The system shall allow the user to add a number to the whitelist or blacklist, and to remove a number from either list.
**Note:** Copre RF-8 (aggiunta/rimozione). La classificazione dalla vista SMS è SRS-503/SRS-504.
**Tags:** `Lists`, `UX`
**Trace:** UN-04 · UN-05

### SRS-405
**Text:** The system shall apply whitelist/blacklist decisions immediately so that the next incoming call from that number follows the new rule without app restart.
**Note:** Copre RF-10. Verifica: classificare → richiamare → comportamento aggiornato.
**Tags:** `Lists`, `Call-Screening`, `Consistency`
**Trace:** UN-04 · RSK-03

### SRS-406
**Text:** The system shall store for each listed number an editable profile with name, free-text notes, category, and date-added.
**Note:** Copre RF-8 ("profilo del numero modificabile"). La categoria è un'etichetta definita dall'utente (es. corriere, spam, studio medico).
**Tags:** `Lists`, `Profile`, `UX`
**Trace:** UN-05

---

## 5. SMS in ingresso e classificazione rapida

### SRS-501
**Text:** The system shall, on every app open, read incoming SMS messages and surface those relevant for classification in a dedicated view.
**Note:** "Rilevanti" = risposte da numeri precedentemente rifiutati o da mittenti non in rubrica/whitelist/blacklist. Copre RF-7 (prima parte) e AMB-04. Richiede `RECEIVE_SMS`/`READ_SMS`.
**Tags:** `SMS-Inbox`, `UX`
**Trace:** UN-04 · RSK-01

### SRS-502
**Text:** The system shall display each surfaced SMS with sender number, date/time, message body, and the linked rejected-call entry when one exists.
**Note:** Il collegamento chiamata↔SMS rende la classificazione informata ("come si presenta"). Copre RF-7 e il bisogno "promuovere/bandire in base a come si presenta".
**Tags:** `SMS-Inbox`, `UX`, `Traceability`
**Trace:** UN-02 · UN-04

### SRS-503
**Text:** The system shall provide on each surfaced SMS a one-tap "Accetta (whitelist)" action that moves the sender number to the whitelist.
**Note:** Copre RF-7 (CTA Accetta). Effetto immediato per SRS-405.
**Tags:** `SMS-Inbox`, `Whitelist`, `UX`
**Trace:** UN-04

### SRS-504
**Text:** The system shall provide on each surfaced SMS a one-tap "Rifiuta (blacklist)" action that moves the sender number to the blacklist.
**Note:** Copre RF-7 (CTA Rifiuta). Effetto immediato per SRS-405.
**Tags:** `SMS-Inbox`, `Blacklist`, `UX`
**Trace:** UN-04

---

## 6. Configurazione utente

### SRS-601
**Text:** The system shall allow the user to edit the automatic SMS text in-app, starting from the pre-filled default defined in SRS-302.
**Note:** Copre RF-9. Validazione: testo non vuoto, lunghezza ≤ limite SMS gestito (concatenazione o troncamento dichiarato in SDS).
**Tags:** `Configuration`, `SMS`, `UX`
**Trace:** UN-06

### SRS-602
**Text:** The system shall provide an ON/OFF setting "Invia SMS anche per numeri in blacklist" with factory default OFF.
**Note:** Copre RF-6 ("secondo configurazione") e SRS-305.
**Tags:** `Configuration`, `Blacklist`, `SMS`
**Trace:** UN-03 · UN-06

---

## 7. Liste, ricerca e persistenza locale

### SRS-701
**Text:** The system shall persist call history, whitelist, blacklist, number profiles, SMS text, and settings in on-device storage so that they survive device reboot and app restart.
**Note:** Copre NFR persistenza locale. Nessun cloud/sync (fuori perimetro, §10).
**Tags:** `Persistence`, `Local-Only`
**Trace:** UN-02 · UN-05 · UN-06

### SRS-702
**Text:** The system shall display the call history ordered by most recent first and shall support filtering by number substring, outcome, SMS status, and date interval.
**Note:** Copre NFR usabilità ("liste leggibili"). Un comportamento di consultazione per requisito; la paginazione/lazy-load va in SDS se la lista cresce.
**Tags:** `History`, `Search`, `Usability`
**Trace:** UN-02

### SRS-703
**Text:** The system shall display whitelist and blacklist as separate lists and shall support search by number substring and by profile name.
**Note:** Liste separate = nessuna ambiguità di appartenenza; un numero sta al massimo in una lista (enforced in SRS-704).
**Tags:** `Lists`, `Search`, `Usability`
**Trace:** UN-05

### SRS-704
**Text:** The system shall prevent a number from belonging to both whitelist and blacklist at the same time; adding a number to one list shall remove it from the other.
**Note:** Invariante di coerenza necessario per la precedenza SRS-403.
**Tags:** `Lists`, `Data-Integrity`
**Trace:** UN-04 · UN-05

---

## 8. Error Handling

### SRS-801
**Text:** The system shall never crash or block the phone app on screening, SMS send, or SMS read failure; every failure shall be recorded in history/logs with a user-safe message and a machine-readable error code.
**Note:** Il telefono deve continuare a funzionare anche se Call Guard fallisce. Dettagli tecnici solo in log non-PII.
**Tags:** `Error-Handling`, `Reliability`
**Trace:** UN-01 · RSK-03 · RSK-04

### SRS-802
**Text:** The system shall show an explicit in-app state when required permissions or the call-screening role are missing, with a direct action to grant/assign them.
**Note:** Stati distinti per: ruolo mancante, `SEND_SMS` mancante, `RECEIVE_SMS`/`READ_SMS` mancante, accesso contatti mancante. Copre il rischio "l'utente crede di essere protetto ma non lo è".
**Tags:** `Error-Handling`, `Permissions`, `UX`
**Trace:** UN-01 · RSK-01 · RSK-03

---

## 9. Piattaforma / Cross-Cutting

### SRS-901
**Text:** The system shall implement call interception exclusively in a native Kotlin module using `CallScreeningService`, targeting Android 10 (API 29) and above, with the Flutter layer limited to UI and communication via platform channel.
**Note:** Vincolo architetturale da brief. iOS escluso (SRS-905).
**Tags:** `Platform`, `Android-Only`, `Architecture`
**Trace:** UN-01 · RSK-03

### SRS-902
**Text:** The system shall request at runtime only the permissions strictly needed for the features above (call screening role, contacts read, SMS send/receive/read as applicable) and shall declare the Play "restricted permissions" justification for `SEND_SMS` and `RECEIVE_SMS`.
**Note:** Controllo RSK-01: senza giustificazione l'app rischia il rifiuto in pubblicazione. La matrice permessi→feature va in SDS.
**Tags:** `Permissions`, `Compliance`, `Play-Policy`
**Trace:** UN-01 · UN-03 · UN-04 · RSK-01

### SRS-903
**Text:** The system shall keep all phone numbers, SMS bodies, history, and lists exclusively on the device and shall transmit no such data to any server or third party.
**Note:** Controllo privacy da brief ("nessun dato lascia il dispositivo"). Vieta backend/sync senza Change Request.
**Tags:** `Privacy`, `Local-Only`, `GDPR`
**Trace:** UN-02 · RSK-02

### SRS-904
**Text:** The system shall never write phone numbers, SMS bodies, or contact names to logs, crash reports, or error responses.
**Note:** Controllo "nessun PII nei log". I log usano hash/ID interni o maschere.
**Tags:** `Privacy`, `Logging`, `Security`
**Trace:** UN-02 · RSK-02

### SRS-905
**Text:** The system shall not target iOS or any non-Android platform in this release.
**Note:** iOS non consente intercettazione a runtime né invio/lettura automatica SMS. Qualsiasi porting richiede Change Request e nuovo SRS.
**Tags:** `Scope`, `Platform`
**Trace:** UN-01

---

## 10. Fuori perimetro (non requisiti)

Non generano requisiti in questo documento: app iOS o altre piattaforme; cloud/backend e sincronizzazione multi-dispositivo; chiamate in uscita; blocco statico stile Call Directory; integrazioni CRM/antispam di rete; backup cloud della cronologia.

---

## Requirements Traceability Summary

| SRS ID | Summary | UN Trace | Risk Trace |
|---|---|---|---|
| SRS-101 | Intercettazione nativa prima dello squillo | UN-01 | RSK-03 |
| SRS-102 | Rifiuto automatico sconosciuto visibile non in rubrica/whitelist | UN-01 | RSK-03 |
| SRS-103 | Numeri nascosti: nessun SMS, nessuna classificazione | UN-03 | RSK-02 |
| SRS-104 | Decisione entro timeout di piattaforma | UN-01 | RSK-03 |
| SRS-105 | Ruolo call screening richiesto + prompt | UN-01 | RSK-03 |
| SRS-201 | Storico persistito per ogni chiamata rifiutata | UN-02 | — |
| SRS-202 | Storico: numero normalizzato | UN-02 | RSK-02 |
| SRS-203 | Storico: data/ora locale al secondo | UN-02 | — |
| SRS-204 | Storico: esito (rifiutata/whitelist/blacklist/senza-numero) | UN-02 | — |
| SRS-205 | Storico: stato SMS (inviato/non-inviato/fallito/n-a-) | UN-02, UN-03 | — |
| SRS-206 | Note libere per voce di storico | UN-02, UN-05 | — |
| SRS-301 | SMS automatico dopo rifiuto | UN-03 | RSK-01 |
| SRS-302 | Default SMS precompilato da brief | UN-03, UN-06 | — |
| SRS-303 | SMS usa testo configurato al momento del rifiuto | UN-03, UN-06 | — |
| SRS-304 | Nessun SMS per numeri nascosti/non validi | UN-03 | RSK-04 |
| SRS-305 | Nessun SMS per blacklist se setting OFF (default) | UN-03 | RSK-04 |
| SRS-306 | SMS fallito → stato `fallito`, voce conservata | UN-02, UN-03 | RSK-04 |
| SRS-401 | Blacklist sempre rifiutata | UN-01, UN-04 | — |
| SRS-402 | Whitelist mai rifiutata | UN-01, UN-04 | — |
| SRS-403 | Precedenza blacklist > whitelist > contatti > sconosciuto | UN-01, UN-04 | — |
| SRS-404 | Aggiunta/rimozione whitelist/blacklist | UN-04, UN-05 | — |
| SRS-405 | Decisioni effettive subito, senza riavvio | UN-04 | RSK-03 |
| SRS-406 | Profilo numero: nome, note, categoria, data aggiunta | UN-05 | — |
| SRS-501 | Vista dedicata SMS rilevanti a ogni apertura | UN-04 | RSK-01 |
| SRS-502 | SMS mostrato con mittente, data/ora, corpo, chiamata collegata | UN-02, UN-04 | — |
| SRS-503 | CTA Accetta (whitelist) one-tap | UN-04 | — |
| SRS-504 | CTA Rifiuta (blacklist) one-tap | UN-04 | — |
| SRS-601 | Testo SMS modificabile in-app | UN-06 | — |
| SRS-602 | Setting SMS-per-blacklist ON/OFF, default OFF | UN-03, UN-06 | — |
| SRS-701 | Persistenza locale oltre riavvio, nessun cloud | UN-02, UN-05, UN-06 | — |
| SRS-702 | Storico ordinato recente-prima + filtri | UN-02 | — |
| SRS-703 | Liste separate con ricerca per numero/nome | UN-05 | — |
| SRS-704 | Invariante: mai in entrambe le liste | UN-04, UN-05 | — |
| SRS-801 | Nessun crash/blocco su failure; errore codificato | UN-01 | RSK-03, RSK-04 |
| SRS-802 | Stato esplicito permessi/ruolo mancanti con azione | UN-01 | RSK-01, RSK-03 |
| SRS-901 | Modulo nativo Kotlin + Flutter UI via channel, Android 10+ | UN-01 | RSK-03 |
| SRS-902 | Solo permessi stretti + giustificazione Play per SMS | UN-01, UN-03, UN-04 | RSK-01 |
| SRS-903 | Tutti i dati restano on-device | UN-02 | RSK-02 |
| SRS-904 | Nessun PII in log/crash/errori | UN-02 | RSK-02 |
| SRS-905 | Nessun target iOS/non-Android | UN-01 | — |

---

*End of Document — CG-SRS-001 v0.1.0*
*Next in package: CG-ARCH-001 — Software Architecture*
