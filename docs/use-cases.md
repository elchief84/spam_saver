# Call Guard — Use Cases

**Document ID:** CG-UC-001
**Version:** 0.1.0
**Status:** Draft
**Service:** `call-guard`
**Last Updated:** 2026-10-10
**Trace Parent:** CG-OVW-001

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
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft — use cases for call screening, auto-SMS, reply triage, lists |

---

## Document Scope

This document defines all Use Cases for Call Guard, the Android-only app that filters calls from unknown visible numbers. Use Cases are written from the perspective of the actors who use or depend on the service: what each actor needs to accomplish and why — not how the system implements it internally.

Parent document: CG-OVW-001 (Overview). Next in package: CG-UN-001 (User Needs).

In scope: automatic pre-ring screening and rejection of unknown numbers, logging of rejected attempts, configurable automatic identification SMS, triage of identification replies at app open with ACCETTA / RIFIUTA quick actions, whitelist/blacklist management with editable number profiles, SMS text configuration. Out of scope: iOS, cloud/backend and multi-device sync, outgoing calls.

---

## Actor Definitions

| Actor | Description |
|---|---|
| Utente | Owner of the Android device. Configures the app, grants the call-screening role and SMS permissions, reads the rejected-call log and reply inbox, classifies numbers, manages lists. |
| Chiamante sconosciuto | External caller with a visible number that is not in the device contacts, not in whitelist, and not in blacklist. Receives the automatic SMS and may reply with identification. |
| Sistema operativo Android | Android 10+ platform acting as call-screening host (CallScreeningService, ROLE_CALL_SCREENING) and SMS carrier. Delivers incoming-call events before ringing and incoming-SMS events, enforces timeouts and permissions. |

---

## UC-01 — Screen an Incoming Call Automatically

**Actor:** Sistema operativo Android (trigger), Utente (beneficiary)
**Preconditions:**
- The app is installed on Android 10+ and the Utente has assigned it the call-screening role.
- The app holds the phone/call-screening permissions needed to observe incoming calls.
- Whitelist, blacklist, and device contacts are readable locally at screening time.

**Story:**
As the Utente, I want every incoming call to be checked before it rings so that unknown numbers never disturb me while known numbers always get through.

**Main Flow:**
1. The Sistema operativo Android notifies Call Guard of an incoming call before ringing, with the caller number when visible.
2. The app compares the number against device contacts, whitelist, and blacklist.
3. If the number is visible and is neither in contacts nor in whitelist, the app issues a reject/silence decision within the platform timeout.
4. The Sistema operativo Android disconnects the call without ringing the Utente's phone.

**Unhappy Paths:**
- The caller number is hidden/withheld → the app takes no reject decision on this path; the call follows the default system behaviour.
- The number is in contacts or in whitelist → no rejection; the call rings normally (see UC-08).
- The screening decision exceeds the platform timeout → the system falls back to normal ringing; the missed screening is logged as a non-blocking miss, with no PII in logs.
- The call-screening role was revoked by the Utente → incoming calls ring normally until the role is re-granted; the app surfaces a prompt to restore it.

**Postconditions:**
- An unknown visible number is rejected before ringing; a known/whitelisted number rings normally.
- Control passes to UC-02 (logging) and, when applicable, UC-03 (auto-SMS) or UC-08 (blacklist path).

---

## UC-02 — Record a Rejected Call Attempt

**Actor:** Utente (reader), Sistema operativo Android (trigger)
**Preconditions:**
- UC-01 has produced a reject decision for a visible unknown number.

**Story:**
As the Utente, I want every automatically rejected call to leave a complete trace so that I can review who tried to call me and what happened next.

**Main Flow:**
1. After a rejection, the app creates a log entry with: number, date/time, outcome (rifiutata), SMS-sent status, and notes field (initially empty).
2. The entry is persisted locally so it survives reboot.
3. The Utente opens the in-app rejected-call list and sees the new entry with all acquired information, most recent first.

**Unhappy Paths:**
- Local storage write fails (e.g., disk full) → the entry is retried once; if it still fails the Utente sees an error state and no partial/duplicate entry is shown.
- Duplicate screening events for the same call → the app keeps a single entry per call attempt; no duplicates in the list.

**Postconditions:**
- The rejected attempt is stored in the local history and visible in the in-app list.
- The SMS-sent status field is available for UC-03 to update.

---

## UC-03 — Send the Automatic Identification SMS

**Actor:** Sistema operativo Android (sender channel), Chiamante sconosciuto (recipient), Utente (configurator)
**Preconditions:**
- A call was rejected under UC-01 and the number is not under a no-SMS blacklist configuration (see UC-08).
- The app holds SEND_SMS permission.
- A configured SMS text exists (user text or the default below).

**Story:**
As the Utente, I want each rejected unknown caller to receive an automatic SMS asking them to identify themselves so that legitimate callers have a channel to explain who they are.

**Main Flow:**
1. On rejection, the app composes the SMS using the Utente-configured text, or the default when never edited: "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione."
2. The app sends the SMS to the rejected number via the Sistema operativo Android.
3. The app updates the UC-02 log entry with the SMS outcome (inviato / non inviato + reason) and timestamp.

**Unhappy Paths:**
- SEND_SMS permission missing or denied → no SMS is sent; the log entry records "SMS non inviato — permesso mancante" and the Utente is prompted to grant it.
- SMS send fails (no signal, carrier error, quota) → the log entry records "SMS non inviato — errore invio"; the call log itself is preserved.
- The number is in blacklist with SMS disabled by configuration → no SMS is sent by design; the log entry records that suppression.

**Postconditions:**
- The rejected caller has been sent the identification request, or the log truthfully records why not.
- The log entry's SMS status is final for that attempt.

---

## UC-04 — Review Identification Replies on App Open

**Actor:** Utente
**Preconditions:**
- The app holds RECEIVE_SMS / SMS-read permission granted by the Utente.
- One or more inbound SMS messages exist, including possible replies to UC-03 messages.

**Story:**
As the Utente, I want to see who answered my automatic SMS as soon as I open the app so that I can quickly decide whether each number is legitimate.

**Main Flow:**
1. The Utente opens Call Guard.
2. The app intercepts/reads inbound SMS messages and presents them in a dedicated reply view: sender number, date/time, message body, and linked rejected-call context where available.
3. Each reply shows two quick actions: ACCETTA (whitelist) and RIFIUTA (blacklist).
4. The Utente reads the identification provided by the caller.

**Unhappy Paths:**
- SMS permission missing → the reply view shows an empty state with a prompt to grant access; no messages are displayed.
- No inbound SMS exists → the view shows an empty state; no error is raised.
- A message cannot be linked to a prior rejected call (e.g., spontaneous SMS) → it is still shown, marked as unlinked, with the same quick actions.

**Postconditions:**
- Inbound identification replies are visible in one dedicated view with sender context.
- Control passes to UC-05 for classification.

---

## UC-05 — Classify a Number with a Quick Action

**Actor:** Utente
**Preconditions:**
- A reply or log entry for an unknown number is displayed (UC-02 or UC-04).
- The number is not already definitively classified, or the Utente intends to reclassify it.

**Story:**
As the Utente, I want to promote or ban a number with one tap from the reply so that future calls from that number are handled correctly without extra steps.

**Main Flow:**
1. The Utente taps ACCETTA (whitelist) or RIFIUTA (blacklist) on a reply or log entry.
2. The app adds the number to the chosen list with an editable profile (name, notes, category, date added — prefilled with date and number) and removes it from the opposing list if present.
3. The app confirms the classification immediately in the UI.

**Unhappy Paths:**
- The number is already in the target list → the action is idempotent; the app confirms without creating a duplicate.
- The number is in the opposing list → it is moved, not duplicated; the move is confirmed.
- The write fails → no list change occurs; the Utente sees an error and the previous classification stands.

**Postconditions:**
- The number belongs to exactly one of whitelist/blacklist (or neither, if the Utente takes no action).
- Future screening behaviour (UC-01/UC-08) changes immediately per RF-10.

---

## UC-06 — Manage Whitelist and Blacklist

**Actor:** Utente
**Preconditions:**
- The Utente has opened the list management view.

**Story:**
As the Utente, I want to add, remove, and edit entries in my whitelist and blacklist so that my filtering decisions stay accurate over time.

**Main Flow:**
1. The Utente opens Whitelist or Blacklist.
2. The Utente adds a number manually, removes an existing entry, or edits a number profile (name, notes, category, date added).
3. The app validates the number format, persists the change locally, and reflects it in the list immediately.

**Unhappy Paths:**
- Invalid number format on manual add → the app rejects the input with a specific message; nothing is saved.
- Removing a number that no longer exists → the app treats it as already removed and confirms the end state.
- Editing a non-existent entry → the app reports not-found; no new entry is created implicitly.

**Postconditions:**
- Whitelist and blacklist contents and number profiles are updated and survive reboot.
- Screening behaviour updates immediately for subsequent calls.

---

## UC-07 — Configure the Automatic SMS Text

**Actor:** Utente
**Preconditions:**
- The Utente has opened the SMS settings.

**Story:**
As the Utente, I want to customise the automatic reply text so that rejected callers receive a message in my tone with the identification details I care about.

**Main Flow:**
1. The Utente opens the SMS-text setting, prefilled with the current text (default on first run).
2. The Utente edits and saves the text.
3. The app validates (non-empty, within SMS length guidance) and persists it locally; UC-03 uses the new text from the next rejection onward.

**Unhappy Paths:**
- Empty text on save → the app rejects the save with a specific message and keeps the previous text.
- Text exceeding practical SMS length → the app warns about multi-part SMS and requires explicit confirmation before saving.

**Postconditions:**
- The configured text is stored locally and used by all subsequent automatic SMS sends.

---

## UC-08 — Let Known Numbers Through and Always Block Banned Ones

**Actor:** Sistema operativo Android (enforcer), Utente (beneficiary)
**Preconditions:**
- Call-screening role active; contacts, whitelist, and blacklist readable (as in UC-01).

**Story:**
As the Utente, I want numbers I trust to always ring and numbers I banned to always be blocked so that my past decisions are enforced without further work.

**Main Flow:**
1. On an incoming call, the app checks whitelist/contacts first, then blacklist.
2. If the number is in contacts or whitelist, the app takes no blocking action and the call rings normally.
3. If the number is in blacklist, the app rejects it; SMS sending follows the blacklist configuration (sent or suppressed per Utente setting) and the attempt is logged per UC-02.

**Unhappy Paths:**
- A number appears in both lists due to a race → whitelist membership is not assumed; the conflict is resolved by most-recent decision (UC-05 move semantics guarantee single membership) and the call is screened as unknown-safe (rejected) until resolved.
- Blacklist SMS configuration unset → default is no SMS for blacklisted numbers; the log records the suppression.

**Postconditions:**
- Trusted numbers ring; banned numbers are rejected and logged.
- No duplicate or contradictory list membership remains.

---

## Traceability Matrix

| UC ID | Title | RF Trace |
|---|---|---|
| UC-01 | Screen an Incoming Call Automatically | RF-1, RF-2 |
| UC-02 | Record a Rejected Call Attempt | RF-3 |
| UC-03 | Send the Automatic Identification SMS | RF-4 |
| UC-04 | Review Identification Replies on App Open | RF-7 |
| UC-05 | Classify a Number with a Quick Action | RF-7, RF-10 |
| UC-06 | Manage Whitelist and Blacklist | RF-8, RF-10 |
| UC-07 | Configure the Automatic SMS Text | RF-9 |
| UC-08 | Let Known Numbers Through and Always Block Banned Ones | RF-5, RF-6, RF-10 |

Coverage notes: RF-10 (immediate effect of decisions) is exercised by UC-05, UC-06, and UC-08 jointly. Non-functional constraints (screening timeout, PII stays on-device with no PII in logs, local persistence across reboot) apply as cross-cutting conditions to UC-01–UC-03 and UC-06. Platform constraints (Android 10+ CallScreeningService + ROLE_CALL_SCREENING, SEND_SMS/RECEIVE_SMS as restricted Play permissions, no iOS runtime interception) are recorded as preconditions and unhappy paths, not as use cases.

---

*End of Document — CG-UC-001 v0.1.0*
*Next in package: CG-UN-001 — User Needs*
