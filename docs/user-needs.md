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
| Author | Aldo (PM) | 2026-10-10 | — |
| Reviewer | To be assigned (BA/PM review pending) | — | — |
| Approver (QA/RA) | To be assigned (approval gate not yet opened) | — | — |

### Change Log

| Version | Date | Author | Summary of Change |
|---|---|---|---|
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft from project brief |

---

## Document Scope

This document captures the User Needs (UN) for Call Guard, an Android-only mobile app that shields the device owner from unknown visible calls by rejecting them before they ring, logging each attempt, sending a configurable automatic SMS reply, and letting the owner quickly promote or ban numbers when reply SMS messages arrive. User Needs represent the high-level intentions, expectations, and constraints of all stakeholders — before any technical solution is defined. Each need is traceable to one or more Use Cases and will be decomposed into testable Software Requirements in the next phase.

Stakeholders: device owner (primary user), unknown caller with a visible number (external party that receives the automatic SMS), Android OS / carrier (platform actor). Out-of-scope stakeholders: iOS users, cloud/backend operators (no backend exists).

---

## UN-101 — Automatic rejection of unknown visible calls before ringing

**Text:** The device owner must be able to have every incoming call from a visible number that is neither in contacts nor in the whitelist rejected automatically before the phone rings, so that unwanted or ambiguous calls never interrupt them.

**Note:** Applies only when the calling number is visible. Hidden/suppressed numbers, contacts, and whitelisted numbers follow different rules (see UN-104, UN-105, UN-114). The owner must explicitly grant the call-screening role; without it this need cannot be met.

**Tags:** `Operator-Workflow`, `Performance`, `Architecture-Constraint`
**Trace UC:** UC-01

---

## UN-102 — Consultable log of rejected attempts

**Text:** The device owner must be able to review every automatically rejected call with its number, date/time, outcome (rejected), SMS-sent status, and notes, so that no filtered attempt goes unnoticed and each one can be followed up.

**Note:** The log is the owner's trace of what the filter did. Entries are created for every automatic rejection and must remain readable as the list grows. The log must not expose numbers anywhere outside the app.

**Tags:** `Operator-Workflow`, `Observability`, `Data-Retention`
**Trace UC:** UC-02

---

## UN-103 — Automatic SMS reply asking the caller to identify themselves

**Text:** The device owner must be able to have an automatic SMS sent to each rejected unknown number asking the caller to identify themselves by SMS, so that legitimate callers have a clear path to be recognised.

**Note:** Default text (Italian, precompiled): "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione." The owner can change the text (see UN-108). No SMS can be sent to hidden numbers or to blacklisted numbers when the owner has disabled it (see UN-105, UN-114).

**Tags:** `Operator-Workflow`, `Configurability`, `Compliance`
**Trace UC:** UC-03

---

## UN-104 — Whitelisted numbers always ring normally

**Text:** The device owner must be able to whitelist a number so that calls from it always ring normally and are never auto-rejected, so that trusted contacts are never blocked by mistake.

**Note:** Whitelist takes precedence over the unknown-number filter. Contacts in the phone book behave as implicitly trusted alongside the explicit whitelist.

**Tags:** `Operator-Workflow`, `Access-Control`, `Configurability`
**Trace UC:** UC-01, UC-05

---

## UN-105 — Blacklisted numbers are always rejected

**Text:** The device owner must be able to blacklist a number so that calls from it are always rejected, so that known-unwanted callers stay blocked without further triage.

**Note:** Blacklist takes precedence over everything else. Whether a blacklist rejection also sends the automatic SMS follows the owner's configuration (default: no SMS for blacklisted numbers, to avoid replying to spammers).

**Tags:** `Operator-Workflow`, `Access-Control`, `Configurability`
**Trace UC:** UC-01, UC-05

---

## UN-106 — Rapid triage of reply SMS messages on app open

**Text:** The device owner must be able to see incoming reply SMS messages in a dedicated view when opening the app, each with "Accept (whitelist)" and "Reject (blacklist)" actions, so that an unknown number can be classified in one tap based on how it presents itself.

**Note:** This is the "promote or ban" loop: rejected call -> automatic SMS -> caller replies by SMS -> owner classifies on next app open. The view must show at minimum the number, the reply content, and the link to the original rejected call where available.

**Tags:** `Operator-Workflow`, `Performance`
**Trace UC:** UC-04

---

## UN-107 — Manageable whitelist, blacklist, and number profiles

**Text:** The device owner must be able to add, remove, and edit whitelisted and blacklisted numbers including name, notes, category, and date added, so that the lists stay accurate over time.

**Note:** Every list entry carries an editable profile (name, notes, category, date added). Removing a number returns it to the default unknown-number behaviour. The date added is set automatically and preserved for traceability.

**Tags:** `Operator-Workflow`, `Configurability`, `Data-Governance`
**Trace UC:** UC-05

---

## UN-108 — Editable automatic SMS text with precompiled default

**Text:** The device owner must be able to edit the automatic SMS reply text in-app starting from the precompiled default, so that the message matches their tone and language needs.

**Note:** The default text is always available as the starting value (see UN-103 for the exact wording). An empty message must not be sendable — the app must require non-empty text.

**Tags:** `Configurability`, `Operator-Workflow`
**Trace UC:** UC-06

---

## UN-109 — Classification decisions take effect immediately

**Text:** The device owner must be able to have every whitelist/blacklist decision change call filtering immediately, so that the next call from that number behaves as just decided without restart or delay.

**Note:** Covers both directions: newly whitelisted numbers ring on the next call; newly blacklisted numbers are rejected on the next call. No app restart or manual sync step is acceptable.

**Tags:** `Operator-Workflow`, `Performance`
**Trace UC:** UC-01, UC-04, UC-05

---

## UN-110 — Screening without delaying the ringtone beyond platform limits

**Text:** The system must complete its screening decision fast enough that normal ringing is never perceptibly delayed and platform screening timeouts are always met, such that protection is invisible for wanted calls.

**Note:** Reliability boundary: if the platform timeout expires, the safe fallback is to let the call ring rather than leave the caller in an undefined state. Behaviour under poor network/carrier conditions is a known risk and is tracked in the Risk Analysis.

**Tags:** `Performance`, `Operability`, `Architecture-Constraint`
**Trace UC:** UC-01

---

## UN-111 — Local-only handling of phone numbers with no PII in logs

**Text:** The system must keep all numbers, call history, messages, and lists exclusively on the device and never transmit them off-device, such that phone numbers (personal data) cannot leak through the app.

**Note:** No cloud, no backend, no multi-device sync. Operational logs must never contain full phone numbers; full identifiers appear only inside the app's own local storage visible to the device owner. GDPR relevance: numbers are PII and stay under the owner's control.

**Tags:** `Privacy`, `Security`, `GDPR`, `Logging`
**Trace UC:** UC-01, UC-02, UC-03, UC-04, UC-05, UC-06

---

## UN-112 — Readable lists and one-tap classification

**Text:** The device owner must be able to scan the rejected-call list, the reply-SMS view, and both lists (whitelist/blacklist) at a glance and classify a number quickly, so that triage takes seconds even with many entries.

**Note:** Usability boundary: lists must stay legible as they grow (number, name where known, date/time, status visible without opening details). Classification from the SMS view must require a single explicit action per number.

**Tags:** `Operator-Workflow`, `Performance`
**Trace UC:** UC-02, UC-04, UC-05

---

## UN-113 — History and lists survive restart and work offline

**Text:** The device owner must be able to rely on call history, reply-SMS triage state, both lists, and the configured SMS text persisting across app restarts and device reboots without any network connection, so that protection never depends on connectivity.

**Note:** The app is fully offline by design. Reinstall without backup is the only case where data is expected to be lost; this must be clear to the owner.

**Tags:** `Offline-Support`, `Data-Retention`, `Operability`
**Trace UC:** UC-02, UC-04, UC-05, UC-06

---

## UN-114 — Android-only operation within platform capabilities

**Text:** The device owner must be able to use the full protection exclusively on an Android device where they have granted the call-screening role and the SMS permissions, so that expectations match what the platform actually allows.

**Note:** Hard boundaries: iOS is out of scope (no runtime call interception or automatic SMS there). Hidden numbers cannot receive the automatic SMS reply. Outgoing calls, cloud sync, and multi-device operation are explicitly out of scope and must not be promised.

**Tags:** `Architecture-Constraint`, `Platform-Integration`, `Compliance`
**Trace UC:** UC-01, UC-03, UC-04

---

## UN-115 — Publishable use of sensitive phone/SMS permissions

**Text:** The system must request and use call-screening and SMS permissions only for the documented filtering and auto-reply purposes, such that the app remains justifiable under Google Play restricted-permission policy.

**Note:** SEND_SMS / RECEIVE_SMS are restricted permissions on Google Play and carry publication risk. The permission rationale shown to the owner and to the store review must match exactly what the app does (reject + log + auto-reply + triage). Any widening of SMS use requires a new review of this need.

**Tags:** `Compliance`, `Privacy`, `Security`
**Trace UC:** UC-01, UC-03, UC-04

---

## UN-116 — Only the device owner can see call and message data (Access Control)

**Text:** The system must make call history, message contents, whitelist, blacklist, and settings accessible only to the device owner, such that unknown callers and any other party can never access, infer, or alter them.

**Note:** Adapted access-control gate for a single-user local app: there is no login and no second consumer role. Unknown callers receive only the automatic SMS text — never any app data. No caller-supplied value may bypass list membership checks.

**Tags:** `Access-Control`, `Security`, `Privacy`, `GDPR`
**Trace UC:** UC-02, UC-04, UC-05, UC-06

---

## UN-117 — Immutable call history and dated list changes (Audit History)

**Text:** The system must preserve every rejected-call record and every whitelist/blacklist change with its date, without silent modification or deletion, enabling the owner to reconstruct what happened to any number at any point in time.

**Note:** Lightweight audit for a local app (no GxP/ISO-13485 scope): log entries are append-only from the owner's perspective — corrections happen via notes or list decisions, not by editing history. List additions/removals keep the date added/changed visible in the number profile.

**Tags:** `Data-Retention`, `Audit`, `Data-Governance`
**Trace UC:** UC-02, UC-05

---

## UN-118 — Single-device isolation, no cross-device leakage

**Text:** The system must confine all data to the single device where it was created so that no other device, installation, or person can access or infer it, such that there is no cross-device data leakage by design.

**Note:** Replaces multi-tenant isolation for this single-user, no-backend app: there are no tenants and no server copies. The device boundary is the isolation boundary. Future cloud sync, if ever proposed, must be treated as a scope change with a new privacy review.

**Tags:** `Security`, `Privacy`, `GDPR`, `Architecture-Constraint`
**Trace UC:** UC-01, UC-02, UC-03, UC-04, UC-05, UC-06

---

## UN-119 — Consistent error handling without exposing internals

**Text:** The system must handle every failure it can encounter (screening timeout, SMS send failure, storage failure, missing permissions or role) with a clear, consistent indication to the owner that never exposes internal system details, so that the owner always knows what happened and what to do next.

**Note:** Examples of expected behaviour: SMS send failure is shown on the corresponding call-log entry; missing screening role or SMS permission is surfaced as a fix-it prompt, not a crash. Error messages must not include numbers in exported diagnostics.

**Tags:** `Operability`, `Security`, `Observability`
**Trace UC:** UC-01, UC-02, UC-03, UC-04

---

## UN-120 — Traceable operation logs with PII protection

**Text:** The system must produce structured, traceable local operation records for screening decisions, SMS sends, and list changes, enabling the owner and diagnostics to reconstruct incidents, without ever writing personally identifiable information into general log outputs.

**Note:** Each record must be linkable to its cause (e.g., an SMS send links to its rejected call; a list change links to the triaged SMS). Full phone numbers are anonymised or redacted in logs; complete numbers live only in the app's protected local storage per UN-111.

**Tags:** `Observability`, `Logging`, `Privacy`, `GDPR`
**Trace UC:** UC-01, UC-02, UC-03, UC-05

---

## Traceability Matrix

| UN ID | Summary | UC Trace |
|---|---|---|
| UN-101 | Auto-reject unknown visible calls before ringing | UC-01 |
| UN-102 | Consultable rejected-call log (number, datetime, outcome, SMS status, notes) | UC-02 |
| UN-103 | Automatic SMS reply asking caller to identify | UC-03 |
| UN-104 | Whitelist always rings | UC-01, UC-05 |
| UN-105 | Blacklist always rejected | UC-01, UC-05 |
| UN-106 | Triage reply SMS on app open with Accept/Reject CTA | UC-04 |
| UN-107 | Manage lists + editable number profile | UC-05 |
| UN-108 | Editable auto-SMS text with precompiled default | UC-06 |
| UN-109 | Decisions take effect immediately | UC-01, UC-04, UC-05 |
| UN-110 | Screening within platform timeout, no ring delay | UC-01 |
| UN-111 | Local-only PII handling, no PII in logs | UC-01, UC-02, UC-03, UC-04, UC-05, UC-06 |
| UN-112 | Readable lists, one-tap classification | UC-02, UC-04, UC-05 |
| UN-113 | Persistence across reboot, offline-first | UC-02, UC-04, UC-05, UC-06 |
| UN-114 | Android-only within platform capabilities | UC-01, UC-03, UC-04 |
| UN-115 | Justifiable restricted-permission use for Play policy | UC-01, UC-03, UC-04 |
| UN-116 | Owner-only access to call/message data | UC-02, UC-04, UC-05, UC-06 |
| UN-117 | Immutable history + dated list changes | UC-02, UC-05 |
| UN-118 | Single-device isolation, no cross-device leakage | UC-01, UC-02, UC-03, UC-04, UC-05, UC-06 |
| UN-119 | Consistent error handling | UC-01, UC-02, UC-03, UC-04 |
| UN-120 | Traceable logs without PII | UC-01, UC-02, UC-03, UC-05 |

Assumed Use Cases: UC-01 Screen incoming call · UC-02 Review rejected-call log · UC-03 Automatic SMS reply · UC-04 Triage reply SMS on app open · UC-05 Manage whitelist/blacklist · UC-06 Configure auto-reply text.

---

*End of Document — CG-UN-001 v0.1.0*
*Next in package: CG-RSK-001 — Risk Analysis*
