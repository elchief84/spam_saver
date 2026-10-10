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
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft from project brief (RF-1–RF-10) |

---

## Document Scope

This document defines all Use Cases (UCs) for Call Guard, an Android-only app that shields the device owner from unknown visible calls by rejecting them before they ring, logging each attempt, sending a configurable automatic SMS reply, and letting the owner classify replying numbers into whitelist/blacklist. Use Cases are written from the perspective of the actors who use or depend on the service. They describe *what* each actor needs to accomplish and *why* — not how the system implements it internally.

Parent document: CG-OVW-001 — Service Overview. Next in package: CG-UN-001 — User Needs (already drafted; traceability in both directions is aligned to UN-101–UN-120). Functional coverage: RF-1–RF-10 per the project brief.

Out of scope for these UCs: iOS, cloud/backend and multi-device sync, outgoing calls, spam scoring and shared directories.

---

## Actor Definitions

| Actor | Description |
|---|---|
| **Owner (device owner)** | Owner of the Android device who installs, configures and uses Call Guard. Sole user of the app and sole decision-maker for whitelist/blacklist classification. Has full in-app access: rejected-call log, reply-SMS view, lists, auto-reply text, settings. |
| **Unknown Caller** | Person or system calling from a visible number not present in contacts or whitelist. Not an app user; only receives the automatic SMS and may reply by SMS with identifying information. |
| **Android OS / Carrier** | Android 10+ platform (CallScreeningService, ROLE_CALL_SCREENING, runtime permissions) and the voice/SMS network. Notifies the app of incoming calls before ringing, executes reject/silence on command, delivers inbound/outbound SMS. No app data leaves the device toward any backend (no backend exists). |

---

## UC-01 — Screen an Incoming Call

**Actor:** Android OS / Carrier (triggers screening); Owner (beneficiary, configures behaviour via UC-05/UC-06)
**Preconditions:**
- The app is installed on Android 10+ (API 29+) and the Owner has granted the call-screening role (ROLE_CALL_SCREENING) plus phone/contacts permissions.
- Whitelist, blacklist and contacts are readable on-device; the configured auto-reply settings exist (defaults apply on first install).
- An incoming call notification is delivered by the OS to the screening module before ringing.

**Story:**
As the **Owner**, I want every call from a visible number that is neither in my contacts nor in my whitelist to be rejected automatically before my phone rings, so that unwanted or ambiguous calls never interrupt me. As the **Unknown Caller**, I expect that if my call does not go through I receive a clear SMS asking me to identify myself, rather than silence.

**Main Flow:**
1. The OS notifies the app of an incoming call with the calling number (visible/hidden) before the ringtone.
2. The app evaluates list membership in fixed order: blacklist → contacts/whitelist → unknown visible → hidden.
3. If the number is in blacklist, the app commands reject (RF-6); the call never rings.
4. If the number is in contacts or whitelist, the app lets the call ring normally (RF-5).
5. If the number is visible and in neither contacts nor whitelist, the app commands reject/silence automatically (RF-1, RF-2).
6. The app returns the screening decision within the platform timeout and records the decision in the local operation record (linked to UC-02/UC-03) without writing PII to general logs.

**Unhappy Paths:**
- Number hidden/suppressed (no SMS-able destination) → the call is let through or silenced per Owner setting; no automatic SMS is attempted; no SMS-failure entry is fabricated.
- Screening role or phone/contacts permission missing → the app cannot screen; the call rings normally (fail-open) and the Owner is shown a fix-it prompt on next app open; no silent blocking.
- Screening decision cannot be completed within the platform timeout → the call is let through (fail-open); the timeout is recorded as an anonymised counter, not with the number.
- Contacts/whitelist/blacklist storage unreadable at screening time → fail-open (let ring) to avoid blocking a legitimate urgent call; the Owner is notified of the storage fault on next app open.
- OS/carrier rejects the disconnect command (carrier variance) → the call rings; the attempt is still logged as "screening requested, carrier did not disconnect" without PII in logs.

**Postconditions:**
- A screening decision (reject / let-ring) has been returned for this call within the platform timeout.
- If rejected as unknown-visible or blacklisted, a rejected-call log entry is created (see UC-02) and, where applicable, an automatic SMS is queued (see UC-03).
- If let through, no log entry is required beyond an anonymised pass counter; the Owner's lists are unchanged.

---

## UC-02 — Review the Rejected-Call Log

**Actor:** Owner
**Preconditions:**
- The Owner opens the app (authentication = device ownership; no login, single-user local app).
- At least one screening rejection has occurred, or the log is empty and the empty state is shown.

**Story:**
As the **Owner**, I want to see every automatically rejected call with its number, date/time, outcome, SMS-sent status and notes, so that no filtered attempt goes unnoticed and I can follow up on legitimate callers.

**Main Flow:**
1. The Owner opens the rejected-call list.
2. The app shows entries newest-first, each with: number, date/time, outcome (rejected), SMS-sent status (sent / failed / not-applicable, e.g. hidden or blacklist-no-SMS), and notes preview; the list stays legible as it grows.
3. The Owner selects an entry to see full detail (link to sent SMS text, link to reply SMS if arrived, number profile if listed, history of decisions for that number).
4. The Owner optionally edits the notes field of the entry or jumps to classify the number (hands off to UC-04/UC-05).

**Unhappy Paths:**
- Log storage corrupted or write fails (disk full) → the Owner sees a clear storage-error message with a retry action; existing entries are never silently altered or dropped; error output contains no phone numbers.
- Entry references a number since removed from lists → detail view still renders with "not currently listed" state instead of a not-found failure.
- Log is empty (no rejections yet) → an explicit empty state explains what will appear here instead of showing a blank screen.

**Postconditions:**
- The Owner has reviewed the filtered attempts; no data is modified except optional notes edits (each note edit preserves date and does not rewrite the immutable call record itself).
- History persists locally across app restarts and reboots (offline-first); reinstall without backup is the only expected-loss case.

---

## UC-03 — Send the Automatic SMS Reply

**Actor:** Android OS / Carrier (delivers); Owner (configures text via UC-06); Unknown Caller (receives)
**Preconditions:**
- A call has just been auto-rejected as unknown-visible (UC-01 path step 5).
- SEND_SMS permission is granted; the auto-reply text is configured and non-empty (default precompiled on first install).
- The rejected number is visible and therefore SMS-addressable; blacklist-no-SMS configuration is respected (default: no SMS for blacklist rejections).

**Story:**
As the **Owner**, I want each rejected unknown caller to automatically receive an SMS asking them to identify themselves by SMS, so that legitimate callers have a clear path to be recognised without me answering voice. As the **Unknown Caller**, I want to receive a comprehensible message telling me why my call was rejected and what to do next.

**Main Flow:**
1. On the unknown-visible rejection, the app composes the SMS with the currently configured text. Default text (Italian): "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione."
2. The app sends the SMS to the rejected number via the carrier.
3. The app updates the corresponding rejected-call entry (UC-02) with the SMS-sent status (sent with timestamp, or failed with reason) linked to the call record.

**Unhappy Paths:**
- SEND_SMS permission missing or revoked → no send is attempted; the log entry shows "SMS not sent — permission missing" with a fix-it prompt; the call rejection itself remains valid.
- SMS send fails (no signal, carrier error, quota) → the log entry shows "SMS failed" with a retry action; no duplicate SMS is sent silently.
- Auto-reply text is empty (user cleared it, import fault) → send is blocked with a "message text required" prompt linking to UC-06; the rejection is still logged.
- Number is hidden or blacklisted with SMS disabled → no send is attempted by design; status shows "not applicable" with the reason (hidden / blacklist-no-SMS setting).
- Dual-SIM / cost concern → send uses the configured default subscription; per-SMS cost remains the carrier's standard rate (no in-app billing); Owner can disable blacklist SMS to avoid spammer costs.

**Postconditions:**
- Exactly one automatic SMS per rejected unknown-visible call has been attempted (or an explicit not-applicable/not-sent status recorded with reason).
- The rejected-call entry carries the final SMS status; the Unknown Caller has received at most the single configured message (no marketing, no follow-ups).

---

## UC-04 — Triage a Reply SMS on App Open

**Actor:** Owner (classifies); Unknown Caller (author of the reply)
**Preconditions:**
- The Owner opens the app; RECEIVE_SMS/read-SMS permission allows reading inbound SMS.
- At least one inbound SMS from a previously rejected number (or any non-contact number) exists, or the view shows its empty state.

**Story:**
As the **Owner**, I want to see incoming reply SMS messages in a dedicated view when I open the app, each with "Accept (whitelist)" and "Reject (blacklist)" actions, so that I can promote or ban a number in one tap based on how it presents itself.

**Main Flow:**
1. On app open, the app intercepts/loads inbound SMS messages and shows them in a dedicated triage view with, at minimum: sender number, message content, date/time, and link to the original rejected call where available.
2. The Owner reads a reply and taps one action: "Accept (whitelist)" or "Reject (blacklist)".
3. The app adds the number to the chosen list with a profile stub (number, date added, optional name/notes/category prompt) and confirms the decision inline.
4. The filtering behaviour for that number changes immediately (see UC-01): whitelisted rings next time, blacklisted is rejected next time — no restart or manual sync.

**Unhappy Paths:**
- SMS permission missing → triage view shows a fix-it prompt instead of an empty list; previously stored triage state remains visible.
- Reply arrives from a number already listed → the CTA row shows current membership ("already whitelisted/blacklisted") and offers profile edit (UC-05) instead of duplicate insertion.
- Message content is empty or undecodable → the row renders with "empty/unreadable message" placeholder; classification actions remain available on the number.
- Two rapid taps / concurrent classification of the same number → last explicit Owner action wins; no duplicate list entries are created (idempotent by normalised number).
- No inbound SMS present → explicit empty state ("no replies yet — rejected callers will appear here") instead of a blank screen.

**Postconditions:**
- Each triaged number is in exactly one of whitelist/blacklist (or left untriaged by explicit Owner choice) with a dated profile entry.
- Triage state persists locally across restarts and works offline; the next incoming call from that number follows the new decision.

---

## UC-05 — Manage Whitelist, Blacklist and Number Profiles

**Actor:** Owner
**Preconditions:**
- The Owner opens the whitelist or blacklist management view.
- Numbers are stored in normalised form for comparison against contacts and incoming caller IDs.

**Story:**
As the **Owner**, I want to add, remove and edit whitelisted and blacklisted numbers — including name, notes, category and date added — so that my lists stay accurate over time and trusted contacts are never blocked by mistake.

**Main Flow:**
1. The Owner opens the whitelist or blacklist and sees entries with name (where set), number, category and date added.
2. The Owner adds a number (manual entry, from call log, or from triage view), removes a number, or edits its profile (name, notes, category; date added is set automatically and preserved).
3. The app validates the entry (non-empty valid number, no duplicate across both lists — a number lives in at most one list) and saves it locally.
4. The app confirms inline and the new membership takes effect on the very next incoming call (RF-10); contacts remain implicitly trusted alongside the explicit whitelist.

**Unhappy Paths:**
- Invalid or empty number entered → the save is rejected with the specific issue reported; nothing is saved.
- Number already present in the opposite list → the app asks for an explicit move (with confirmation) instead of creating a duplicate; no number is ever in both lists.
- Removing a number → it returns to default unknown-number behaviour (future calls screened as unknown); removal keeps a dated "removed" trace in the number's history without resurrecting the entry.
- Storage write fails → the change is not applied; the Owner sees a retryable error; lists remain in their last consistent state.
- Caller-supplied SMS content attempts to influence membership (e.g. "whitelist me" text) → ignored by design; only the Owner's explicit action changes lists.

**Postconditions:**
- Whitelist/blacklist reflect exactly the Owner's last confirmed decisions, each entry carrying name, notes, category and date added.
- Screening (UC-01) uses the updated lists immediately; changes persist across restarts offline.

---

## UC-06 — Configure the Automatic Reply Text

**Actor:** Owner
**Preconditions:**
- The Owner opens the auto-reply text settings; a precompiled default is present on first install.

**Story:**
As the **Owner**, I want to edit the automatic SMS reply text in-app starting from the precompiled default, so that the message matches my tone and language needs.

**Main Flow:**
1. The Owner opens the SMS-text setting and sees the current text (initial value = default: "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione.").
2. The Owner edits the text and saves it.
3. The app validates non-empty (and reasonable length for single-SMS delivery) and confirms the save.
4. Future automatic replies (UC-03) use the new text; past sent messages keep the text they were sent with.

**Unhappy Paths:**
- Empty text submitted → save is rejected with "message text required"; the previous text stays active; no empty SMS can ever be queued.
- Text exceeding single-SMS length → the app warns about multi-part/cost and asks for explicit confirmation (or offers to shorten); nothing is truncated silently.
- Settings storage fails → the previous text remains active; the Owner sees a retryable error.
- Text reset requested → the app restores the exact precompiled default above on explicit Owner confirmation.

**Postconditions:**
- Exactly one active auto-reply text exists (default or Owner-customised), persisted locally across restarts offline.
- UC-03 sends only this active text; only the Owner can read or change it.

---

## Cross-Cutting Rules (apply to all UCs)

- **Privacy / PII:** all numbers, call history, SMS contents and lists stay on-device; no data leaves the phone (no backend, no sync). General logs and diagnostics never contain full phone numbers — only anonymised counters/outcomes; complete identifiers live solely in the app's protected local storage (UN-111, UN-120).
- **Access control:** call history, message contents, lists and settings are visible only to the Owner. Unknown Callers receive only the auto-reply text — never any app data (UN-116).
- **Isolation:** single-device boundary; no cross-device access or inference by design (UN-118).
- **Error handling:** every failure (screening timeout, SMS failure, storage failure, missing role/permission) surfaces a clear Owner-facing indication with a next action, without exposing internals (UN-119).
- **Audit:** rejected-call records are append-only from the Owner's perspective (corrections via notes/decisions, not history edits); list additions/removals keep their dates visible (UN-117).
- **Fail-open safety:** any screening-path fault defaults to letting the call ring rather than blocking a possibly urgent legitimate call.

---

## Traceability Matrix

| UC ID | Title | RF Trace | UN Trace |
|---|---|---|---|
| UC-01 | Screen an Incoming Call | RF-1, RF-2, RF-5, RF-6, RF-10 | UN-101, UN-104, UN-105, UN-109, UN-110, UN-111, UN-114, UN-115, UN-118, UN-119, UN-120 |
| UC-02 | Review the Rejected-Call Log | RF-3 | UN-102, UN-111, UN-112, UN-113, UN-116, UN-117, UN-118, UN-119, UN-120 |
| UC-03 | Send the Automatic SMS Reply | RF-4 | UN-103, UN-111, UN-114, UN-115, UN-118, UN-119, UN-120 |
| UC-04 | Triage a Reply SMS on App Open | RF-7, RF-10 | UN-106, UN-109, UN-111, UN-112, UN-113, UN-114, UN-115, UN-116, UN-118, UN-119 |
| UC-05 | Manage Whitelist, Blacklist and Number Profiles | RF-5, RF-6, RF-8, RF-10 | UN-104, UN-105, UN-107, UN-109, UN-111, UN-112, UN-113, UN-116, UN-117, UN-118, UN-120 |
| UC-06 | Configure the Automatic Reply Text | RF-9 | UN-108, UN-111, UN-113, UN-116, UN-118 |

RF coverage check: RF-1→UC-01 · RF-2→UC-01 · RF-3→UC-02 · RF-4→UC-03 · RF-5→UC-01, UC-05 · RF-6→UC-01, UC-05 · RF-7→UC-04 · RF-8→UC-05 · RF-9→UC-06 · RF-10→UC-01, UC-04, UC-05. All RF-1–RF-10 covered; no UC without an RF parent except cross-cutting NFR handling embedded in each UC.

---

*End of Document — CG-UC-001 v0.1.0*
*Next in package: CG-UN-001 — User Needs*
