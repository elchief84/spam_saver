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
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft from project brief RF-1–RF-10 |

---

## Document Scope

This document captures the User Needs (UN) for Call Guard. User Needs represent the high-level intentions, expectations, and constraints of all stakeholders — before any technical solution is defined. Each need is traceable to one or more Use Cases and will be decomposed into testable Software Requirements in the next phase.

### Product Overview

Call Guard is an Android-only mobile app that protects the device owner from calls by unknown visible numbers: it rejects such calls before they ring, records each attempt in an in-app list, automatically replies with a configurable SMS asking the caller to identify themselves, and — when the app is opened — shows any reply SMS with quick actions to whitelist (accept) or blacklist (reject) the number. Value: fewer unwanted interruptions, a consultable trace of attempts, and fast promotion/ban of numbers based on how callers present themselves.

### Stakeholders

- Device owner (primary user): wants automatic filtering, a readable history, and one-tap classification.
- Unknown caller (visible number, not in contacts): receives an automatic SMS and can reply to identify themselves.
- Android OS / carrier environment: grants the call-screening role and SMS permissions; imposes timing and policy limits.

### In Scope / Out of Scope

In scope: pre-ring interception, automatic rejection of visible non-contact numbers, in-app attempt log, automatic configurable SMS reply, reply-SMS triage on app open with Accept/Reject, manageable whitelist/blacklist with editable number profiles, local persistence across reboots, on-device privacy.

Out of scope: iOS and other platforms, cloud/backend and multi-device sync, outgoing calls.

---

## UN-101 — Automatic Rejection of Unknown Visible Calls

**Text:** The device owner must be able to have every incoming call from a visible number that is neither in contacts nor in the whitelist automatically rejected before it rings, so that unwanted or ambiguous calls never interrupt them.

**Note:** Covers the core protection promise. Applies only to visible numbers; withheld/private numbers are not auto-rejected by this need. Rejection must happen before any audible ring. Platform condition: the owner must have assigned the app the call-screening role (Android 10+).

**Tags:** `Operator-Workflow`, `Platform-Integration`, `Performance`
**Trace UC:** UC-01

---

## UN-102 — Trusted Numbers Always Ring Through

**Text:** The device owner must be able to count on contacts and whitelisted numbers always ringing normally, so that trusted callers are never blocked by the automatic filter.

**Note:** Whitelist is an explicit trust override that complements the device contacts. A number added to the whitelist must pass even if it was previously unknown. This is the safety counterpart to UN-101: no false positives on trusted callers.

**Tags:** `Operator-Workflow`, `Access-Control`, `Configurability`
**Trace UC:** UC-01, UC-05

---

## UN-103 — Blocked Numbers Always Rejected

**Text:** The device owner must be able to have blacklisted numbers always rejected, so that once-banned callers cannot get through again.

**Note:** Blacklist is an explicit permanent ban. Per configuration it may reject without sending the automatic SMS (to avoid engaging persistent spammers). Blacklist takes precedence over any other passing rule except an explicit later removal.

**Tags:** `Operator-Workflow`, `Access-Control`, `Configurability`
**Trace UC:** UC-01, UC-05

---

## UN-104 — Consultable Record of Rejected Attempts

**Text:** The device owner must be able to review every rejected call with its number, date and time, outcome, SMS-sent status, and notes, so that no filtered attempt is lost and each can be followed up.

**Note:** The history is the user's evidence trail: it must remain readable as it grows and survive device reboots. Notes allow the owner to annotate context (e.g. "claimed to be courier"). No record may silently disappear.

**Tags:** `Operator-Workflow`, `Data-Retention`, `Offline-Support`
**Trace UC:** UC-02

---

## UN-105 — Automatic SMS Reply Asking for Identification

**Text:** The device owner must be able to have each rejected unknown caller automatically receive an SMS asking them to identify themselves by text message, so that legitimate callers have a clear path to get recognised.

**Note:** Default text: "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione." The owner can edit the text in-app with the default pre-filled. Sending must not block or delay call rejection. Blacklisted numbers may be excluded from the SMS per configuration (see UN-103).

**Tags:** `Operator-Workflow`, `Configurability`, `Platform-Integration`
**Trace UC:** UC-03

---

## UN-106 — Reply-SMS Triage on App Open

**Text:** The device owner must be able to see reply SMS messages intercepted at app opening in a dedicated view with one-tap "Accept (whitelist)" and "Reject (blacklist)" actions, so that classifying an unknown number takes seconds.

**Note:** This is the "promote or ban" loop: the caller identifies themselves by SMS, the owner judges the presentation and classifies immediately. The view must show which number each reply belongs to and link it to the corresponding rejected-call record where possible.

**Tags:** `Operator-Workflow`, `Configurability`, `Performance`
**Trace UC:** UC-04

---

## UN-107 — Manageable Whitelist, Blacklist, and Number Profiles

**Text:** The device owner must be able to add, remove, and edit whitelist and blacklist entries including name, notes, category, and date added, so that the trust lists stay accurate over time.

**Note:** Each number has an editable profile (name, notes, category, date added). Removing a number from a list must restore default handling (unknown numbers return to auto-reject + SMS flow). Lists must survive reboots and stay manageable/readable.

**Tags:** `Operator-Workflow`, `Configurability`, `Data-Retention`
**Trace UC:** UC-05

---

## UN-108 — Immediate Effect of Classification Decisions

**Text:** The device owner must be able to have every whitelist/blacklist decision take effect immediately on subsequent calls, so that there is no window where an outdated rule still applies.

**Note:** No restart, sync, or waiting period is acceptable between classifying a number and the new behaviour. This closes the loop between UN-106/UN-107 and UN-101/UN-102/UN-103.

**Tags:** `Operator-Workflow`, `Performance`, `Configurability`
**Trace UC:** UC-04, UC-05, UC-01

---

## UN-109 — Filtering Gate / Access Control

**Text:** Any incoming call must only reach the ringer if it meets the defined passing criteria (contact, whitelisted, or non-filterable), so that no unknown unvetted caller can ever cause a ring.

**Note:** This is the safety gate of the service and applies unconditionally — it must not be bypassable by caller behaviour (e.g. repeated calling). Conversely, trusted callers must never be suppressed by the filter. Passing criteria are the device contacts plus the user-managed whitelist minus the blacklist.

**Tags:** `Access-Control`, `Compliance`, `Security`
**Trace UC:** UC-01

---

## UN-110 — Local History Retention and Decision Trace

**Text:** The system must retain the rejected-call history and every whitelist/blacklist decision locally across reboots, enabling full reconstruction of why each number is currently treated the way it is.

**Note:** Required for user trust and dispute resolution ("why was this number blocked?"). Every classification change preserves what changed and when (date added / decision trace). Retention is on-device only; there is no backend. History is never silently pruned.

**Tags:** `Data-Retention`, `Audit`, `Compliance`, `Offline-Support`
**Trace UC:** UC-02, UC-05

---

## UN-111 — Single-User Isolation and On-Device Privacy

**Text:** The system must keep all numbers, call records, messages, and lists strictly on the device such that no data leaves the phone and no other party can access, modify, or infer it.

**Note:** Call Guard is single-user, single-device with no cloud or sync: there are no tenants to leak across by design. Phone numbers are personal data under GDPR: they must never leave the device, never appear in general logs, and require the user's explicit consent via the call-screening role and SMS permissions. Publication risk: SEND_SMS / RECEIVE_SMS are restricted permissions on Google Play and require justification — tracked as a release gate, not a reason to weaken this need.

**Tags:** `Privacy`, `Security`, `GDPR`, `ISO-27001`, `Architecture-Constraint`
**Trace UC:** UC-01, UC-02, UC-03, UC-04, UC-05

---

## UN-112 — Consistent Error Handling

**Text:** The system must respond to all screening failures, SMS send/receive failures, and missing-permission states with consistent, clearly understandable behaviour that never leaves the user unprotected or misinformed.

**Note:** Failures must fail safe from the user's perspective: a missed SMS send must be shown as "not sent" on the call record rather than silently claimed; a missing call-screening role or denied SMS permission must be surfaced with guidance instead of pretending filtering is active. Error messages must not expose internal system details or personal data.

**Tags:** `Operability`, `Security`, `ISO-27001`
**Trace UC:** UC-01, UC-03, UC-04

---

## UN-113 — Traceable Logging with PII Protection

**Text:** The system must produce structured, traceable diagnostics for every screening and messaging operation, enabling fault investigation, without exposing personally identifiable information in log outputs.

**Note:** Phone numbers and message contents are personal data and must be redacted or anonymised in logs. Full identifiers live only in the on-device app data (call log, lists), never in diagnostic output. Each diagnostic entry must be linkable to its operation (screened call, sent SMS) for troubleshooting across the native screening path and the UI.

**Tags:** `Observability`, `Logging`, `GDPR`, `ISO-27001`, `Privacy`
**Trace UC:** UC-01, UC-02, UC-03

---

## UN-114 — Timely, Non-Intrusive Screening

**Text:** The system must complete call screening within platform timing limits such that the ringer behaviour for trusted callers is never perceptibly delayed and rejected calls never ring.

**Note:** Reliability/usability constraint: screening must answer within the OS timeout and SMS sending must not hold up the rejection decision. Lists must stay readable and classification must stay a one/two-tap action even as history grows. iOS is out of scope because it cannot meet this need (no runtime interception or automatic SMS).

**Tags:** `Performance`, `Platform-Integration`, `Architecture-Constraint`
**Trace UC:** UC-01, UC-04

---

## Traceability Matrix

| UN ID | Summary | UC Trace |
|---|---|---|
| UN-101 | Auto-reject unknown visible calls pre-ring | UC-01 |
| UN-102 | Trusted numbers (contacts + whitelist) ring | UC-01, UC-05 |
| UN-103 | Blacklisted numbers always rejected | UC-01, UC-05 |
| UN-104 | Consultable rejected-attempt log | UC-02 |
| UN-105 | Automatic identification-request SMS | UC-03 |
| UN-106 | Reply-SMS triage with Accept/Reject on open | UC-04 |
| UN-107 | Manageable lists + editable number profiles | UC-05 |
| UN-108 | Decisions take effect immediately | UC-04, UC-05, UC-01 |
| UN-109 | Filtering gate: only passing calls ring | UC-01 |
| UN-110 | Local retention + decision trace | UC-02, UC-05 |
| UN-111 | Single-user on-device isolation, no data leaves phone | UC-01, UC-02, UC-03, UC-04, UC-05 |
| UN-112 | Consistent failure behaviour, fail-safe + informed | UC-01, UC-03, UC-04 |
| UN-113 | Traceable diagnostics without PII in logs | UC-01, UC-02, UC-03 |
| UN-114 | Screening within platform limits, non-intrusive | UC-01, UC-04 |

---

*End of Document — CG-UN-001 v0.1.0*
*Next in package: CG-RSK-001 — Risk Analysis*
