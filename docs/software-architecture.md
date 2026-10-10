# Architecture Document
## `call-guard` — Call Guard

**Document ID:** CG-ARCH-001
**Version:** 0.1.0
**Status:** Draft
**IEC 62304 Phase:** 5.3 — Software Architectural Design (proportional application; product is not a medical device per CG-OVW-001 §2.3)
**Service:** `call-guard`
**Last Updated:** 2026-10-10
**Trace Parents:** CG-OVW-001 · CG-UC-001 · CG-UN-001 · CG-RSK-001 · CG-SRS-001

---

## Document Control

| Role | Name | Date | Signature |
|---|---|---|---|
| Author | Onofrio (TA) | 2026-10-10 | Onofrio |
| Technical Reviewer | Onofrio (TA) | 2026-10-10 | Onofrio |
| Approver (QA/RA) | TBD | — | — |

### Change Log

| Version | Date | Author | Summary of Change |
|---|---|---|---|
| 0.1.0 | 2026-10-10 | Onofrio (TA) | Initial draft from approved CG-OVW-001, CG-UC-001, CG-UN-001, CG-RSK-001, CG-SRS-001 |

---

## Table of Contents

1. [Purpose & Scope](#1-purpose--scope)
2. [Architectural Principles & Constraints](#2-architectural-principles--constraints)
3. [C4 Level 1 — System Context Diagram](#3-c4-level-1--system-context-diagram)
4. [C4 Level 2 — Container Diagram](#4-c4-level-2--container-diagram)
5. [Software Items & Units Breakdown](#5-software-items--units-breakdown)
6. [Interface & API Contracts](#6-interface--api-contracts)
7. [High-Level Sequence Diagrams](#7-high-level-sequence-diagrams)
8. [Deployment Topology](#8-deployment-topology)
9. [Cross-Cutting Concerns](#9-cross-cutting-concerns)
10. [Bidirectional Traceability Matrix](#10-bidirectional-traceability-matrix)
11. [Open Decisions & Implementation Readiness](#11-open-decisions--implementation-readiness)
12. [Authoring & Approval](#12-authoring--approval)
13. [Change Log](#13-change-history)

---

## 1. Purpose & Scope

### 1.1 Purpose

This document defines the software architecture for **`call-guard`** (Call Guard, Android-only call-filter app). It is the bridge between the approved business baseline (CG-OVW-001, CG-UC-001, CG-UN-001, CG-RSK-001, CG-SRS-001) and the deterministic design in CG-SDS-001.

It establishes:

- The decomposition of the app into **Software Items (SI) and Software Units (SU)** per IEC 62304 §5.3, applied proportionally to a non-medical-device product.
- The **technology and pattern decisions** that govern implementation: native Kotlin screening path, Flutter UI, on-device storage, platform-channel contract.
- The **interface contracts** between the native module, the Flutter layer, Android OS, and the carrier (no backend, no HTTP API).
- The **deployment topology**: single APK on one device, Android 10+ (API 29+), offline-first.

Normative detail (numbered algorithms, data shapes, channel codecs, error registry values) belongs to CG-SDS-001. This document fixes the decomposition, the layering, and the constraints the SDS must respect.

### 1.2 Scope

| In Scope | Out of Scope |
|---|---|
| Internal decomposition of `call-guard` into SI/SU (Domain, Application, Infrastructure) | iOS and any other platform (explicitly out of scope per CG-OVW-001 §4.2) |
| Native Kotlin screening path (`CallScreeningService`, role `ROLE_CALL_SCREENING`) and its contract with the Flutter layer | Cloud/backend, multi-device sync, backup/restore beyond on-device persistence |
| On-device persistence (history, whitelist/blacklist, SMS template, settings) and its transactional guarantees | Outgoing calls (never intercepted, never logged) |
| SMS auto-reply send path and foreground SMS-triage read path | Carrier-side static blocking, external spam databases, ML scoring |
| Traceability to all 38 approved SRS items (SRS-101…SRS-1005) | CI/CD pipeline implementation; Play Store submission paperwork (tracked as RSK-105 gate) |
| Architectural controls for RSK-101…RSK-109 | Rewriting upstream business decisions (RF-1…RF-10, AMB-01…AMB-04 resolutions) |

Deviations from the H.Core microservice template are deliberate and recorded in §2.2 and §8: there is no server, no Kubernetes, no edge, no mesh, no DAS/MongoDB, no HTTP surface. Any future introduction of network, analytics, or sync requires a scope Change Request and a privacy re-review (CG-OVW-001 §2.2 mandatory principle).

### 1.3 Definitions & Acronyms

| Term | Definition |
|---|---|
| SaMD | Software as a Medical Device — not applicable to Call Guard (CG-OVW-001 §2.3) |
| SI | Software Item — logically separable part of the software (IEC 62304 §5.3) |
| SU | Software Unit — lowest independently testable decomposition unit |
| SOUP/OTS | Software of Unknown Provenance / Off-the-Shelf — third-party runtime and libraries |
| Screening path | `CallScreeningService.onScreenCall` execution from OS notification to `RespondViaDisconnection` decision; must complete within the platform timeout |
| Fail-open | On screening-path failure the call is allowed to ring normally (never fail-closed); the failure is surfaced in-app |
| PII | Personally Identifiable Information — here: phone numbers, contact names, SMS bodies, notes |
| Room | AndroidX Room persistence over SQLite (on-device, app-private) |
| Platform channel | Flutter `MethodChannel`/`EventChannel` bridge between Dart UI and Kotlin native code |
| E.164 | Canonical international phone-number format used as the normalised identity key |

---

## 2. Architectural Principles & Constraints

### 2.1 Governing Principles

| # | Principle | Rationale |
|---|---|---|
| P-01 | **Clean / Hexagonal layering, dependency inward** | Domain holds pure decision logic (normalisation, precedence, eligibility, idempotency keys) with zero Android/Flutter I/O imports. Application orchestrates use cases against ports. Infrastructure implements adapters (screening, contacts, SMS, store, channel, UI). Rationale: testability without devices; screening-path determinism; GDPR data-minimisation (PII only crosses into Infrastructure). Source: CG-OVW-001 P-01/P-02, CG-SRS-001 SRS-201/SRS-1001. |
| P-02 | **Native owns screening; Flutter never screens** | Only `CallScreeningService` can intercept pre-ring on Android 10+. The UI layer is excluded from the time-critical path. Rationale: platform constraint; reliability NFR (RSK-102). Source: CG-OVW-001 C-01/P-01, SRS-201/SRS-301. |
| P-03 | **Synchronous, allocation-light screening; no network, no blocking I/O on the screening path** | The decision uses only in-memory snapshots (blacklist set, whitelist set, contacts presence) pre-loaded before the call. Persistence writes and SMS sends happen off the decision path. Rationale: platform timeout compliance (RSK-102, SRS-301, SRS-1001). |
| P-04 | **Fixed decision order: blacklist → contacts/whitelist-pass → unknown-reject; anonymous always passes** | Eliminates classification ambiguity (AMB-02, AMB-04). Blacklist rejects even over contacts (SRS-306); hidden/empty IDs pass with no SMS (SRS-304); non-dialable/short-codes never get SMS (SRS-305). Rationale: false-positive control (RSK-101). Source: CG-OVW-001 P-04. |
| P-05 | **On-device only; no PII in logs, no network exfiltration** | All numbers, SMS bodies, history, and lists live in app-private storage. Logs carry only hashes/truncated prefixes. No sync/analytics/backup transmitting PII. Rationale: GDPR Art. 25, RSK-103/RSK-104, SRS-1002/SRS-1003. Source: CG-OVW-001 C-03/P-03. |
| P-06 | **Exactly-once auto-reply per rejected call; blacklist SMS default OFF; one manual retry only** | Idempotency key = rejected-call event ID. No background auto-retry. Rationale: cost control and anti-spam (RSK-107), SRS-501/SRS-502/SRS-902. |
| P-07 | **Immediate effect of classification; one record per rejected call** | List writes are synchronous and visible to the next screening (SRS-307); each rejection creates a distinct history row (SRS-401). Rationale: UN-108/RF-10, RSK-106. |
| P-08 | **Fail-open on calls, fail-explicit on UI** | Missing role/permissions, send failure, or corrupt data never blocks all calls and never leaves partial state; every failure surfaces with a corrective action (SRS-1004, SRS-901). Rationale: RSK-102/RSK-104 availability. |

### 2.2 Tech Stack Constraints

| Constraint | Value | Source |
|---|---|---|
| Platforms | Android 10+ only (API 29–35 tested matrix); `minSdk 29`. iOS and Android <10 explicitly unsupported | CG-OVW-001 C-01; SRS-1005; SRS-201 |
| Native language | Kotlin, `CallScreeningService` + `ROLE_CALL_SCREENING`; AndroidX Room for store; `SmsManager` for send; SMS provider query for foreground read | Brief vincoli di piattaforma; SRS-201/SRS-301/SRS-501/SRS-601 |
| UI language | Dart + Flutter (stable channel pinned at build time, version recorded in SDS §SOUP); Material UI, no screening logic in Dart | CG-OVW-001 P-01/D-01 |
| Bridge | Flutter platform channel (`MethodChannel`, binary messenger; `EventChannel` only if streaming is justified in SDS — default: request/response + local notification trigger) | CG-OVW-001 D-01 |
| Persistence | Room/SQLite (app-private internal storage) for history + lists + profiles; `DataStore`/`SharedPreferences` (app-private) for SMS template text + blacklist-SMS flag; `allowBackup=false` unless encrypted backup is justified in SDS | RSK-104/RSK-106; SRS-102/SRS-103/SRS-403/SRS-705 |
| Network | None. Zero network calls in the app, and specifically zero in the screening path | SRS-1001/SRS-1002 |
| H.Core server stack (Node.js 20+, TypeScript strict, ESM, DAS/MongoDB Wire, K8s, edge/mesh, HTTP + `/health`, `/metrics`) | **Not applicable — explicitly excluded.** No server exists; no DAS; no MongoDB; no edge authentication; no mesh; no HTTP surface. This row is retained only to record the deviation so no reviewer assumes the template defaults apply | CG-OVW-001 D-03 (no backend); template §2.2 deviation log |

### 2.3 GSPR / Regulatory Alignment

Call Guard is not MDSW (CG-OVW-001 §2.3); GSPR/MDR rows are not applicable. The applicable regimes and their architectural consequences are:

| Architectural Decision | Regulatory / Policy Basis |
|---|---|
| On-device only; no sync/analytics/backup with PII; explicit deletion per entry + wipe on uninstall | GDPR (data minimisation, storage limitation, Art. 25 by design); ISO 27001 A.8/A.18 |
| No PII in logs (hash/truncated prefix only); PII-scrub code-review gate + log-inspection test | GDPR Art. 25/32; ISO 27001 logging policy; RSK-103 |
| App-private Room store, no exported `ContentProvider`, `allowBackup=false` (or encrypted), no share/export | GDPR integrity/confidentiality; RSK-104 |
| Restricted permissions (`SEND_SMS`/`RECEIVE_SMS` or scoped `READ_SMS`) minimised, feature-gated, with Play declaration + degraded no-SMS mode | Google Play restricted-permission policy; RSK-105; SRS-203 |
| Soft-delete prohibited as silent pruning: history rows are never silently overwritten or merged; removal from a list never deletes history | ISO 13485 §4.2.5 record-retention principle applied proportionally; RSK-106; SRS-401/SRS-403 |
| Immutable decision trace: every list move records source + timestamp; every history row records decision origin + SMS status | Post-production information principle (ISO 14971 §10, proportional); UN-110; SRS-402/SRS-701 |

---

## 3. C4 Level 1 — System Context Diagram

`call-guard` is a single-user, single-device, offline-first mobile app. There is no backend, no multi-tenancy, no cross-service traffic.

| System | Type | Relationship |
|---|---|---|
| `call-guard` (this app: Kotlin native module + Flutter UI + Room store) | This system | — |
| Device owner (Utente) | Human actor, primary | Assigns screening role; grants permissions; reads blocked-call history and SMS triage; classifies numbers; edits lists/profiles/SMS template |
| Unknown caller | Human actor, external | Places inbound calls from a visible number; receives auto-reply SMS; may reply by SMS for identification |
| Android OS 10+ | Platform | Notifies `CallScreeningService.onScreenCall` pre-ring; enforces `ROLE_CALL_SCREENING`; executes disconnect/silence; provides contacts (`READ_CONTACTS`), telephony state, SMS provider, `SmsManager`; enforces permission grants/revocation |
| Carrier network | External infrastructure | Delivers inbound calls (caller ID, hidden/visible) and SMS; delivery/tariff behaviour varies by carrier (RSK-102/RSK-107 context) |
| Google Play review | External gate | Grants or rejects restricted-permission declaration (`SEND_SMS`/`RECEIVE_SMS`); no runtime interface |
| Explicitly absent | — | No backend, no sync server, no analytics/crash-reporting with PII, no DAS/MongoDB, no edge/mesh, no HTTP consumers |

Context notes (binding):

1. All PII flows are device-local: caller number and SMS bodies move only between Android OS ↔ native module ↔ Room ↔ Flutter UI. No flow leaves the device.
2. Contacts are read-only and used solely for the pass/lookup decision; no contact is copied beyond what the decision snapshot requires (CG-OVW-001 §2.1).
3. The unknown caller has no access scope in the app; interaction is via telephony/SMS only.

---

## 4. C4 Level 2 — Container Diagram

Single-APK deployment. "Containers" here are in-app runtime partitions, not server deployments.

| Container | Technology | Responsibility |
|---|---|---|
| Native screening & telephony module | Kotlin, `CallScreeningService`, `SmsManager`, contacts/SMS-provider queries, in-memory decision snapshot | Pre-ring interception (SRS-301); deterministic decision per P-04 (SRS-302…SRS-306); disconnect/silence actuation; exactly-once auto-reply send (SRS-501/502); foreground SMS read support (SRS-601); role/permission state detection (SRS-202/203) |
| Flutter UI + application orchestration host | Dart/Flutter, platform channel client | Protection-status onboarding (UC-01); blocked-call history list + filters (SRS-801); SMS triage view with two CTAs (SRS-602…604); list/profile management (SRS-701/702/704/802); SMS-template editor (SRS-503); error surfacing with corrective actions (SRS-901); manual SMS retry entry point (SRS-902) |
| On-device store | Room/SQLite (history, lists, profiles, triage state) + app-private prefs (template text, blacklist-SMS flag, decision snapshot cache) | Transactional persistence across reboot/update (SRS-102/103/401/403/705); single source of truth for next-call decisions (SRS-307); SMS-status ledger (SRS-402) |
| Platform-channel bridge | `MethodChannel` (versioned method names + codec, defined in SDS) | Sole crossing between native and UI; transports normalised numbers, record IDs, template text, status enums — never raw PII in logs; synchronous writes for classification (immediate effect) |
| Referenced but not part of the app | Android OS, carrier, Play review | See §3; no DAS, no K8s, no ConfigMap, no `/health`, no `/metrics` endpoint |

Memory/IO rule (binding for SDS): the screening decision reads only the pre-loaded in-memory snapshot; Room writes, contacts re-queries, and SMS sends are scheduled after the decision returns (SRS-301, SRS-1001).

---

## 5. Software Items & Units Breakdown

Decomposition follows IEC 62304 §5.3. IEC 62304 classification note (binding): Call Guard is not a medical device and no failure can cause death or (clinical) serious injury; worst-case harm is a missed urgent call, a privacy breach, unwanted SMS cost, or Store rejection (CG-OVW-001 §2.2–2.3, CG-RSK-001 §3). Therefore every SU is **Class A** (no injury or damage to health possible in the 62304 sense). The rationale column states the worst-case failure mode and why it remains Class A; operational criticality is still controlled via RSK-101…109 → §9.5. Any future clinical claim re-opens classification.

### 5.1 Domain Layer

Pure logic. Zero Android/Flutter imports. In Kotlin this is a `pure` module (or the Dart equivalent if the SDS places shared policy in Dart — the SDS must choose one canonical home and forbid duplication); no I/O, no clock/direct `System.currentTimeMillis` except via injected clock port.

| SU ID | Name | Responsibility | IEC 62304 Class | Rationale |
|---|---|---|---|---|
| SU-DOM-01-01 | PhoneNumber | Normalisation (E.164/national), visible-vs-hidden discrimination, dialability validation, short-code/alphanumeric rejection | A | Failure yields wrong pass/reject or wrong SMS skip; harm is a missed call or extra SMS (operational), no health injury possible |
| SU-DOM-02-01 | ScreeningDecision | Pure decision function implementing precedence blacklist → contacts/whitelist-pass → unknown-reject, anonymous-pass; decision-origin enum | A | Failure is RSK-101 false positive/negative; worst case is a lost urgent call handled as operational risk, not clinical injury |
| SU-DOM-02-02 | SmsEligibility | Pure eligibility: visible + dialable + not short-code + not SRS-304/305-excluded + blacklist-flag rule (SRS-103/502) | A | Failure causes unwanted SMS cost or missing SMS; economic/nuisance harm only |
| SU-DOM-03-01 | CallRecord | Rejected-call entity: number ref, timestamp, outcome=rejected, SMS status (sent/failed/skipped+reason), notes; one-row-per-call invariant | A | Failure loses trace (RSK-106); recoverability harm, no injury |
| SU-DOM-03-02 | TrustedEntry | Whitelist/blacklist entry: normalised number (unique key), name, notes, category, date-added, source; mutual-exclusion invariant (SRS-702) and move semantics | A | Failure causes contradictory screening; effect bounded to ring/reject behaviour |
| SU-DOM-04-01 | AutoReplyTemplate | Default text constant (SRS-101), non-empty + declared-length validation (SRS-503), single/concatenated-segment accounting input | A | Failure sends empty/oversize SMS; cost/UX harm only |

### 5.2 Application Layer

Use-case orchestration against ports. No direct Android framework or Room imports; ports are implemented by §5.3 adapters.

| SU ID | Name | Responsibility | IEC 62304 Class | Rationale |
|---|---|---|---|---|
| SU-APP-01-01 | ScreenIncomingCallUseCase | Executes screening algorithm: snapshot lookup → SU-DOM-02-01 → immediate decision return; schedules record + SMS off-path; enforces no-network rule | A | Time-critical orchestrator for RSK-102; failure mode is timeout/fail-open, no health injury |
| SU-APP-02-01 | RecordRejectedCallUseCase | Creates one CallRecord per rejection with decision origin; persists transactionally; never aggregates duplicates | A | RSK-106 trace integrity; data-loss harm only |
| SU-APP-03-01 | SendAutoReplyUseCase | Exactly-once send per event ID (idempotency key); composes persisted template; maps result to SMS status (SRS-402); at most one manual retry (SRS-902) | A | RSK-107 cost control; failure is cost/nuisance |
| SU-APP-04-01 | TriageInboundSmsUseCase | On app foreground: fetches inbound SMS, links to history numbers, computes pending-classification set for dedicated view (SRS-601) | A | RSK-109 deferral handling; delay harm only |
| SU-APP-05-01 | ClassifyNumberUseCase | Accept→whitelist / Reject→blacklist from triage or history; records source+timestamp; clears pending state; synchronous commit for SRS-307 immediacy | A | RSK-108 misclassification is reversible in 2 taps; no injury |
| SU-APP-06-01 | ManageListsUseCase | Add/remove/move/edit lists + profiles (name, notes, category); enforces SRS-702 mutual exclusion and SRS-703 precedence inputs | A | List-integrity harm bounded to future ring/reject |
| SU-APP-07-01 | ConfigureSmsTemplateUseCase | Edit/validate/persist template (SRS-503); restore-default; exposes segment count | A | Config harm bounded to future SMS content/cost |
| SU-APP-08-01 | ProtectionStatusUseCase | Evaluates role + permission + OS-version state; drives blocking UI + deep-links (SRS-202/203/1005/1004) | A | Failure misreports protection (RSK-102/RSK-105 UX harm); calls still fail-open |

### 5.3 Infrastructure Layer

All I/O. Each adapter implements exactly one port defined by the Application layer; adapters never embed decision policy (policy lives in §5.1).

| SU ID | Name | Responsibility | IEC 62304 Class | Rationale |
|---|---|---|---|---|
| SU-INF-01-01 | CallScreeningAdapter | `CallScreeningService.onScreenCall` host; timeout-safe entry/exit; snapshot read; disconnect/silence actuation; diagnostics without PII | A | Platform-boundary failure = fail-open (RSK-102); no injury |
| SU-INF-02-01 | ContactsLookupAdapter | Read-only contacts presence check (`READ_CONTACTS`); snapshot builder; denied-permission path (feature-gate per SRS-203) | A | Missing lookup degrades to unknown-handling; operational only |
| SU-INF-03-01 | SmsSenderAdapter | `SmsManager` send + delivery result mapping; dialability/short-code guard enforcement point; idempotency-key carrier | A | Send failure maps to RSK-107 ledger state; cost harm only |
| SU-INF-04-01 | SmsInboxReaderAdapter | Foreground SMS-provider query scoped to history numbers; denied-permission path; never a background listener unless SDS justifies it against RSK-105 | A | Read failure shows guidance (SRS-901); delay harm only |
| SU-INF-05-01 | LocalStoreAdapter | Room DAOs + transactions (history, lists, profiles, triage flags) + prefs (template, blacklist-SMS flag); migration handling; reboot/update durability | A | RSK-106 durability; loss harm is re-classification effort |
| SU-INF-06-01 | PlatformChannelBridge | Versioned MethodChannel contract (methods, args, codecs, error codes); synchronous classification writes; PII-safe error mapping | A | Bridge failure surfaces as explicit UI error; no silent divergence allowed |
| SU-INF-07-01 | FlutterPresentation | Six surfaces: protection onboarding, blocked history, SMS triage, whitelist, blacklist, template settings + profile detail; filter/sort (SRS-801); confirm+undo on CTAs (RSK-108) | A | UX-layer failure is mis-tap/reversible; no injury |
| SU-INF-08-01 | DiagnosticsLogger | Structured diagnostics with mandatory PII scrub (hash/truncated-prefix only); screening/SMS outcome counters without identifiers | A | Logger failure is itself an RSK-103 finding; no direct user harm |

### 5.4 Software Items Summary

| SI ID | SI Name | SU Count | Layer | Highest SU Class |
|---|---|---|---|---|
| SI-DOM-01 | Number Identity & Screening Policy | 3 (SU-DOM-01-01, SU-DOM-02-01, SU-DOM-02-02) | Domain | A |
| SI-DOM-02 | Records & Trust Model | 3 (SU-DOM-03-01, SU-DOM-03-02, SU-DOM-04-01) | Domain | A |
| SI-APP-01 | Screening & Messaging Use Cases | 4 (SU-APP-01-01, SU-APP-02-01, SU-APP-03-01, SU-APP-04-01) | Application | A |
| SI-APP-02 | Classification & Configuration Use Cases | 4 (SU-APP-05-01, SU-APP-06-01, SU-APP-07-01, SU-APP-08-01) | Application | A |
| SI-INF-01 | Native Platform Adapters | 5 (SU-INF-01-01…SU-INF-05-01) | Infrastructure | A |
| SI-INF-02 | Bridge, Presentation & Diagnostics | 3 (SU-INF-06-01, SU-INF-07-01, SU-INF-08-01) | Infrastructure | A |

Whole-product highest class: **A**. No SU may be promoted to B/C without a clinical-harm justification and a re-qualification of CG-OVW-001 §2.3.

### 5.5 SOUP / OTS Integration Points

Versions are pinned at build time and recorded exactly in SDS; the table below fixes the consumption map.

| SOUP ID | Library | Version | Consuming SU | Layer |
|---|---|---|---|---|
| SOUP-01 | Android OS + SDK (API 29–35, `CallScreeningService`, `SmsManager`, SMS provider, contacts provider) | API 29 min; target/compile pinned in SDS | SU-INF-01-01, SU-INF-02-01, SU-INF-03-01, SU-INF-04-01 | Runtime/platform |
| SOUP-02 | Kotlin stdlib + coroutines (no blocking on screening path) | Pinned in SDS | All native SUs | Runtime |
| SOUP-03 | AndroidX Room (SQLite) + DataStore/SharedPreferences | Pinned in SDS | SU-INF-05-01 | Persistence |
| SOUP-04 | Flutter SDK + Material widgets | Pinned in SDS | SU-INF-06-01, SU-INF-07-01 | Presentation |
| SOUP-05 | Gradle + Android Gradle Plugin (build only) | Pinned in SDS | Build of SI-INF-01/SI-INF-02 | Build |

No Node.js, no MongoDB driver, no DAS client, no HTTP framework: the H.Core SOUP rows do not apply and must not appear in the SDS dependency list.

---

## 6. Interface & API Contracts

There is no HTTP API. This section is the complete external-interface inventory. Wire-level codecs, method-name strings, and field schemas are normative in SDS; this section fixes the inventory and the ownership.

### 6.1 Android framework callbacks (OS → app)

| Direction | Interface | Auth / Gate | Description |
|---|---|---|---|
| OS → app | `CallScreeningService.onScreenCall(Call.Details)` | `ROLE_CALL_SCREENING` held; else never invoked | Pre-ring notification with caller number/presentation; app must return decision within platform timeout (SRS-301) |
| App → OS | `CallResponse.Builder.setDisallowCall(true/false).setSkipNotification(skip).build()` | Same role | Disconnect/silence actuation for reject; pass-through for contacts/whitelist/anonymous (SRS-302…306) |
| App → OS | `SmsManager.sendTextMessage / sendMultipartTextMessage` + sent/delivery intents | `SEND_SMS` granted | Exactly-once auto-reply transport (SRS-501); result maps to SRS-402 ledger |
| App → OS | Contacts query (`ContactsContract.PhoneLookup`) | `READ_CONTACTS` granted | Presence check for SRS-302/303; denied → feature-gate message (SRS-203) |
| App → OS | SMS provider query (inbox, foreground only) | `RECEIVE_SMS`/`READ_SMS` granted (minimal scope per RSK-105) | Triage input for SRS-601; denied → guidance state, no silent classification |

### 6.2 Platform-channel contract (native ↔ Flutter)

| Direction | Method | Description |
|---|---|---|
| Flutter → native | `getProtectionStatus` | Returns role + permission + OS-support state for SU-APP-08-01 / SRS-202/203/1005 |
| Flutter → native | `requestScreeningRole` | Opens system role request; result returns to `getProtectionStatus` |
| Native → Flutter (via store + query) | `getBlockedHistory(filter, sort)` | Paged blocked-call rows for SRS-401/403/801 |
| Flutter → native | `classifyNumber(numberRef, verdict, profile)` | Synchronous commit for SRS-603/604/704 + SRS-307 immediacy; returns new membership + effect statement |
| Flutter → native | `manageList(op, list, entry)` | CRUD/move for SRS-701/702/705 |
| Flutter → native | `getSmsTriage()` | Pending-classification SMS set for SRS-601/602 |
| Flutter → native | `getSmsTemplate` / `setSmsTemplate(text)` | Validated read/write for SRS-101/102/503 (non-empty + length rule) |
| Flutter → native | `getBlacklistSmsFlag` / `setBlacklistSmsFlag(bool)` | SRS-103/502 toggle, default false |
| Flutter → native | `retrySms(historyRecordId)` | Single manual retry for SRS-902; refused if already sent or already retried |
| Either → either | Error return `{code, message}` | Codes from §9.4 registry; messages static, no PII, no stack traces |

Channel rules (binding): one canonical codec; normalised-number form on the wire is E.164-or-national as validated by SU-DOM-01-01; no duplicate screening logic on the Dart side — Dart renders decisions the native layer committed.

### 6.3 Explicitly absent interfaces

No REST/HTTP routes, no `/health`, no `/metrics`, no auth scopes, no tenant headers, no M2M. A future proposal to add any networked interface is a scope Change Request (CG-OVW-001 §8.3).

---

## 7. High-Level Sequence Diagrams

Detail (numbered steps, unhappy paths, timeouts, codecs) is normative in SDS. This section fixes the phase order and the layering invariants.

### 7.1 Inbound-call screening — happy path (unknown visible number)

```
Carrier → Android OS: incoming call (visible number)
Android OS → SU-INF-01-01.onScreenCall: Call.Details (pre-ring)
SU-INF-01-01 → snapshot (memory): blacklist? contacts/whitelist? (no I/O, no network)
SU-INF-01-01 → SU-APP-01-01 → SU-DOM-02-01: decide (blacklist → pass-check → unknown-reject)
SU-APP-01-01 → Android OS: CallResponse(disallow=true, silence)  [within timeout]
SU-APP-01-01 → SU-APP-02-01 → SU-INF-05-01: persist CallRecord (off-path, transactional)
SU-APP-01-01 → SU-DOM-02-02 → SU-APP-03-01 → SU-INF-03-01: eligibility → exactly-once SmsManager send
SU-INF-03-01 → SU-INF-05-01: ledger SMS status sent/failed/skipped+reason (SRS-402)
```

Invariants: decision returns before any Room write or SMS send; exactly one SMS attempt per event ID; anonymous/non-dialable never reaches the sender.

### 7.2 Trusted / banned short-circuits

```
Contacts/whitelist hit → CallResponse(disallow=false); no record, no SMS (SRS-303).
Blacklist hit → CallResponse(disallow=true); SMS only if SRS-103 flag true, else ledger skipped/blacklisted (SRS-306/502).
Hidden/empty ID → pass-through; never SMS (SRS-304).
Short-code / non-dialable → pass-or-reject per decision, but never SMS (SRS-305).
```

### 7.3 Foreground SMS triage + classification (app open)

```
User → SU-INF-07-01: opens app
SU-INF-07-01 → SU-APP-04-01 → SU-INF-04-01: query inbox (foreground) scoped to history numbers
SU-INF-04-01 → SU-INF-05-01: link SMS ↔ CallRecord; compute pending set
SU-INF-07-01: render dedicated view (number, datetime, body, linked record) + exactly two CTAs (SRS-601/602)
User → CTA → SU-APP-05-01 → SU-INF-05-01: synchronous commit (whitelist/blacklist + source + timestamp)
SU-INF-05-01 → snapshot refresh: next call from that number uses new verdict (SRS-307)
```

### 7.4 Configuration (template + lists)

```
User → template editor → SU-APP-07-01 (SU-DOM-04-01 validation) → SU-INF-05-01 persist;
  next auto-reply uses new text (SRS-102/503). Empty/over-limit saves rejected, prior text kept.
User → list/profile edit → SU-APP-06-01 (SRS-702 exclusion) → SU-INF-05-01 synchronous commit;
  effect statement shown ("will now ring normally" / "will now always be rejected").
```

---

## 8. Deployment Topology

| Component | Type | Notes |
|---|---|---|
| `call-guard` APK (native module + Flutter engine + Room DB + prefs) | Single-device install, Android 10+ (API 29 min) | Offline-first; stateless across devices (no account); stateful on-device (history, lists, template). OEM/API 29–35 test matrix per RSK-102. Battery-optimisation exemption guidance in onboarding. |
| Decision snapshot (in-memory blacklist/whitelist/contacts presence) | In-process cache rebuilt on every list write and on boot | Sole input to the screening path; guarantees SRS-307 immediacy without blocking I/O |
| App-private store (`/data/data/<pkg>/databases` + prefs) | Room/SQLite + DataStore/SharedPreferences | `allowBackup=false` (or encrypted backup only); no exported provider; survives reboot/update; schema versioned with migration tests (RSK-106) |
| Platform attachments | None beyond Android OS + carrier | No K8s Deployment/ReplicaSet, no ConfigMap, no edge, no mesh, no DAS, no sidecars. Resource limits are device constraints (timeout, SMS segments, storage cap TQ-01 in §11) |

---

## 9. Cross-Cutting Concerns

### 9.1 Security

| Concern | Mechanism | SRS / RSK Reference |
|---|---|---|
| Permission minimisation | Only `READ_CONTACTS`, `READ_PHONE_STATE`, `SEND_SMS`, scoped SMS-read declared; each feature gated with explicit message when denied | SRS-203; RSK-105 |
| Screening-role gate | Boot + resume check of `ROLE_CALL_SCREENING`; blocking state + system-request action; never claim protection when inactive | SRS-202; RSK-102/RSK-105(AM) |
| PII confinement | Numbers/SMS/notes only in app-private Room/prefs; contacts read-only; no network; no share/export; explicit per-entry and wipe-all deletion | SRS-1002; RSK-104 |
| Log hygiene | SU-INF-08-01 scrubs all identifiers (hash/truncated prefix); lint + log-inspection test fails build on PII leak | SRS-1003/SRS-901; RSK-103 |
| Anti-spoof posture | Triage view links SMS to originating rejected-call record; unlinked SMS shown as unlinked with manual-only classification | SRS-601; RSK-108 |
| No identity provider in-app | Single-user device; no login, no tenant, no edge auth. "Identity context" is the Android role/permission grant state consumed, never re-hosted | CG-OVW-001 §3; UN-111 |

### 9.2 Audit & Compliance

| Concern | Mechanism |
|---|---|
| Decision trace | Every history row carries decision origin (unknown/blacklist) + SMS status + timestamps; every list entry carries source (manual/SMS-classification/call-history) + date-added/last-move |
| No silent mutation | One row per rejected call, never merged/overwritten; list removal never deletes history; retention is keep-until-user-deletes (cap, if introduced per TQ-01, must be explicit, user-visible, and newest-preserving — SDS to specify) |
| Play-policy audit | Permission declaration + demo video + degraded no-SMS mode prepared before UI freeze; release checklist gates submit (RSK-105) |
| PII lifecycle | Deletion per entry; uninstall wipes store; no off-device copies to reconcile |

### 9.3 Observability

| Concern | Mechanism |
|---|---|
| Structured diagnostics | SU-INF-08-01 emits operation-linked events (screened-call ID, SMS-event ID) with PII redaction; counters for screening OK / role-missing / timeout / SMS sent-failed-skipped |
| No PII telemetry | No analytics, no crash-reporting with identifiers; any future crash tool requires scrubber + opt-in + re-review (scope CR) |
| User-visible status | Protection status, SMS ledger state, and pending-triage badge are the operational dashboard; no hidden background state |

### 9.4 Error Handling Strategy

No HTTP server exists; the "HTTP Status" column of the template is replaced by the in-app surfacing contract. Codes are `SCREAMING_SNAKE_CASE`, each bound to one static user message (no stack traces, no PII beyond already-displayed list context) and one corrective action. Full message strings are normative in SDS.

| Error Code | Surfacing | Behaviour |
|---|---|---|
| `ROLE_MISSING` | Blocking banner + "Open system settings" action | Calls pass through; no claim of protection (SRS-202/1004) |
| `PERMISSION_DENIED_CONTACTS` | Inline notice on screening/history | Unknown-handling without contacts match; link to grant (SRS-203) |
| `PERMISSION_DENIED_SMS_SEND` | History row ledger "SMS not sent — permission missing" + settings link | No send attempted; one manual retry after grant (SRS-402/902) |
| `PERMISSION_DENIED_SMS_READ` | Triage view "SMS access missing" + settings link | No classification on unread data (UC-06 unhappy path) |
| `SCREENING_TIMEOUT` | Diagnostic counter only (no user blame); protection-status hint if recurrent | Fail-open: call rang; record not marked as app-rejected (UC-02 unhappy path) |
| `SMS_SEND_FAILED_RADIO` | Ledger "SMS not sent" + one manual-retry affordance on the row | No background auto-retry (SRS-902) |
| `SMS_SKIPPED_BLACKLIST_POLICY` | Ledger "rejected from blacklist, SMS disabled" | Correct skip, not a failure (SRS-502) |
| `SMS_SKIPPED_NON_DIALABLE` | Ledger "SMS not applicable" | Never attempted (SRS-304/305) |
| `STORE_UNWRITABLE` | Blocking notice on next open + retry-save | Record never silently dropped (UC-03 unhappy path) |
| `VALIDATION_EMPTY_TEMPLATE` / `VALIDATION_TEMPLATE_TOO_LONG` / `VALIDATION_INVALID_NUMBER` | Field-level error, prior value kept | Reject save, no partial write (SRS-503, SRS-701) |
| `OS_UNSUPPORTED` | Incompatibility message, protection stays off | SRS-1005 |

### 9.5 Architectural Risk Control Measures

| RSK ID | Risk | Architectural Control |
|---|---|---|
| RSK-101 | False-positive rejection of legitimate/urgent call (initial 12 ALTO) | P-04 fixed precedence; contacts+whitelist always pass (SU-DOM-02-01/SRS-302/303/306/703); blacklist never auto-fed; instant history row with 1-tap callback (SU-APP-02-01); onboarding critical-contact whitelist |
| RSK-102 | Screening timeout / missing role / OEM kill (10 MEDIO) | P-02/P-03: snapshot-only decision, no I/O on path (SU-APP-01-01/SU-INF-01-01); boot/resume role gate (SU-APP-08-01); documented fail-open; OEM/API test matrix |
| RSK-103 | PII in logs (12 ALTO) | P-05 + SU-INF-08-01 scrub mandate; build-failing log-inspection test; offline-by-design (no sink for PII) |
| RSK-104 | Local-store disclosure (9 MEDIO) | App-private Room/prefs; no exported provider; `allowBackup=false`/encrypted; explicit deletion (SU-INF-05-01) |
| RSK-105 | Play rejection on restricted SMS permissions (10 MEDIO) | Minimal-scope request + feature gates (SRS-203); degraded no-SMS mode; early declaration + Consent/Retriever evaluation (AD-03); release gate in §11 |
| RSK-106 | Persistence loss on reboot/update (6 MEDIO) | Transactional Room + prefs; synchronous decision-path writes; idempotent SMS ledger; migration + reboot tests (SU-INF-05-01) |
| RSK-107 | Uncontrolled SMS (cost/loops/wrong target) (8 MEDIO) | Exactly-once per event ID; blacklist default OFF (SRS-103); SRS-304/305 guards; single-segment default verification + segment counter; one manual retry only |
| RSK-108 | Triage misclassification (8 MEDIO) | Confirm + immediate undo on CTAs; record-linked detail; reversible 2-tap correction; explicit CTA labels (SU-INF-07-01) |
| RSK-109 | Deferred triage (foreground-only read) (10 MEDIO) | Local notification + badge + deep-link on rejection; recency-ordered pending set; documented limitation; background-listener future weighed against RSK-105 (AD-04) |

---

## 10. Bidirectional Traceability Matrix

Every SRS maps to at least one SU; every SU traces to at least one SRS. RF and RSK columns ground the business justification.

| SRS ID | Requirement Summary | SU(s) | Notes |
|---|---|---|---|
| SRS-101 | Default SMS pre-populated | SU-DOM-04-01, SU-APP-07-01, SU-INF-05-01 | Constant + first-launch seed |
| SRS-102 | Template persisted, used until changed | SU-APP-07-01, SU-INF-05-01 | Kill/restart + update durability |
| SRS-103 | Blacklist-SMS flag, default false | SU-DOM-02-02, SU-APP-03-01, SU-INF-05-01, SU-INF-07-01 | AMB-01 resolution |
| SRS-201 | Screening exclusively in native Kotlin, Android 10+ | SU-INF-01-01, SU-APP-01-01 | P-02; Flutter never screens |
| SRS-202 | Blocking state when role missing | SU-APP-08-01, SU-INF-07-01, SU-INF-01-01 | Deep-link to system request |
| SRS-203 | Minimal permissions with feature gates | SU-APP-08-01, SU-INF-02-01, SU-INF-03-01, SU-INF-04-01, SU-INF-07-01 | RSK-105 surface |
| SRS-301 | Pre-ring interception within timeout | SU-APP-01-01, SU-INF-01-01 | Snapshot-only path; SRS-1001 |
| SRS-302 | Reject iff visible + not contacts + not whitelist + role held | SU-DOM-01-01, SU-DOM-02-01, SU-APP-01-01 | Core rule; RF-2/RF-5 |
| SRS-303 | Contacts pass with no log/SMS | SU-DOM-02-01, SU-INF-02-01, SU-APP-01-01 | Implicit whitelist |
| SRS-304 | Hidden/empty IDs pass, never SMS | SU-DOM-01-01, SU-DOM-02-01, SU-DOM-02-02 | AMB-02 resolution |
| SRS-305 | Never SMS short-codes/alpha/non-dialable | SU-DOM-01-01, SU-DOM-02-02, SU-INF-03-01 | Cost guard |
| SRS-306 | Blacklist always rejects, even over contacts | SU-DOM-02-01, SU-APP-01-01 | AMB-04 resolution |
| SRS-307 | Decisions effective on very next call | SU-APP-05-01, SU-APP-06-01, SU-INF-05-01, SU-INF-01-01 | Snapshot refresh; RF-10 |
| SRS-401 | One history record per rejection (5 fields) | SU-DOM-03-01, SU-APP-02-01, SU-INF-05-01 | Never aggregated |
| SRS-402 | SMS status + failure reason on record | SU-APP-02-01, SU-APP-03-01, SU-INF-05-01 | Template ref only, no body copy beyond link |
| SRS-403 | History survives restart/update, newest-first | SU-INF-05-01, SU-INF-07-01 | No backend |
| SRS-501 | Exactly one auto-SMS per rejection (with stated exceptions) | SU-APP-03-01, SU-INF-03-01, SU-DOM-02-02 | Idempotency key = event ID |
| SRS-502 | Skip SMS for blacklist when flag false | SU-DOM-02-02, SU-APP-03-01, SU-INF-05-01 | Ledger `skipped/blacklisted` |
| SRS-503 | Template edit with non-empty + length validation | SU-DOM-04-01, SU-APP-07-01, SU-INF-07-01 | Restore-default included |
| SRS-601 | Foreground SMS read + dedicated linked view | SU-APP-04-01, SU-INF-04-01, SU-INF-07-01 | AMB-03 resolution |
| SRS-602 | Exactly two CTAs per unclassified SMS | SU-INF-07-01 | No nested menus |
| SRS-603 | Accept → whitelist + clear pending | SU-APP-05-01, SU-DOM-03-02, SU-INF-05-01 | Source + timestamp recorded |
| SRS-604 | Reject → blacklist + clear pending | SU-APP-05-01, SU-DOM-03-02, SU-INF-05-01 | Symmetric |
| SRS-701 | List CRUD + profile (6 fields) | SU-DOM-03-02, SU-APP-06-01, SU-INF-05-01, SU-INF-07-01 | Normalised number = key |
| SRS-702 | Mutual exclusion whitelist/blacklist | SU-DOM-03-02, SU-APP-06-01 | Move, never duplicate |
| SRS-703 | Precedence blacklist > pass > reject | SU-DOM-02-01, SU-APP-01-01 | Testable form of AMB-04 |
| SRS-704 | Promote directly from history (1 action/choice) | SU-APP-05-01, SU-INF-07-01 | Extends RF-7/RF-8 |
| SRS-705 | Lists survive restart/update | SU-INF-05-01 | Critical regression surface |
| SRS-801 | Three lists with substring filter + date-desc sort | SU-INF-07-01, SU-INF-05-01 | Readability NFR |
| SRS-802 | Profile detail with linked records + edit | SU-INF-07-01, SU-DOM-03-02 | Name/notes/category editable |
| SRS-901 | Failures surfaced with action; no PII/stack traces | SU-INF-07-01, SU-INF-08-01, SU-APP-08-01 | §9.4 registry |
| SRS-902 | At most one manual retry, never background auto-retry | SU-APP-03-01, SU-INF-07-01 | Preserves exactly-once auto invariant |
| SRS-1001 | Decision uses on-device lookups only, no network | SU-APP-01-01, SU-INF-01-01 | Tested with network disabled |
| SRS-1002 | All data stays on-device, no transmitting backup/sync/analytics | SU-INF-05-01, SU-INF-08-01 | Mandatory principle; CR for any change |
| SRS-1003 | No PII in any log | SU-INF-08-01 | Hash/prefix only; build gate |
| SRS-1004 | Graceful degradation, fail-open calls, no partial state | SU-APP-08-01, SU-APP-01-01, SU-INF-07-01 | Fail-open + fail-explicit |
| SRS-1005 | Android 10+ only, explicit incompatibility message | SU-APP-08-01, SU-INF-07-01 | iOS/<10 out of scope |

Reverse check: every SU appears above at least once. SU-DOM-01-01 (302/304/305), SU-DOM-02-01 (302/303/304/306/703), SU-DOM-02-02 (103/304/305/501/502), SU-DOM-03-01 (401/402), SU-DOM-03-02 (603/604/701/702/802), SU-DOM-04-01 (101/503), SU-APP-01-01 (201/301/302/303/306/703/1001/1004), SU-APP-02-01 (401/402), SU-APP-03-01 (103/501/502/902), SU-APP-04-01 (601), SU-APP-05-01 (307/603/604/704), SU-APP-06-01 (307/701/702), SU-APP-07-01 (101/102/503), SU-APP-08-01 (202/203/901/1004/1005), SU-INF-01-01 (201/301/307/1001), SU-INF-02-01 (203/302/303), SU-INF-03-01 (203/305/501), SU-INF-04-01 (203/601), SU-INF-05-01 (101/102/103/307/401/402/403/502/603/604/701/705/801/1002), SU-INF-06-01 (§6.2 contract carrier for 307/603/604/902 flows), SU-INF-07-01 (103/202/203/503/602/701/704/801/802/901/902/1004/1005), SU-INF-08-01 (901/1002/1003).

---

## 11. Open Decisions & Implementation Readiness

### AD-01 — Canonical home of pure domain policy (Kotlin vs Dart)

**Decision:** Single canonical home for SU-DOM-*-*-* (no duplicated precedence/normalisation on both sides of the channel). Recommended: Kotlin `pure` module as source of truth for the screening path, with Dart reusing validated results via the channel; the SDS must record the choice and the duplication ban.
**Rationale:** P-01/P-02 — duplicated policy drifts and breaks the timeout and precedence guarantees.
**Status:** Resolved in principle; binding choice recorded in SDS.
**Impact:** SU-DOM-01-01, SU-DOM-02-01, SU-DOM-02-02; SRS-302/703.

### AD-02 — Room as on-device store; prefs for template + flag

**Decision:** Room/SQLite for history, lists, profiles, triage flags; app-private prefs for template text and blacklist-SMS flag; `allowBackup=false` unless SDS justifies encrypted backup.
**Rationale:** Transactional durability for RSK-106 with minimal SOUP surface; template/flag are single-value settings.
**Status:** Resolved.
**Impact:** SU-INF-05-01; SRS-102/103/401/403/705.

### AD-03 — SMS-read scope: full `RECEIVE_SMS`/`READ_SMS` vs User-Consent/Retriever API

**Decision:** TBD in SDS with Play-policy evidence. Default posture: request the minimal scope that satisfies SRS-601 foreground triage; evaluate SMS User Consent / Retriever API as lower-scrutiny alternatives before claiming full read.
**Rationale:** RSK-105 — over-scoped SMS permission is the likeliest Store-rejection cause.
**Status:** [WARN] Open — must be resolved before SDS sign-off (blocks §6.1 and permission UX).
**Owner:** TA + PM.
**Target Date:** Before SDS authoring completes.

### AD-04 — Background SMS listener vs foreground-only triage

**Decision:** Baseline remains foreground-only read per SRS-601/AMB-03 (accepted ALARP cost: RSK-109 residual MEDIO). A background `RECEIVE_SMS` listener with notification is a future option only, weighed against RSK-105.
**Rationale:** Minimises battery, complexity, and policy surface.
**Status:** Resolved as baseline; future option tracked.
**Impact:** SU-INF-04-01, SU-APP-04-01; RSK-109.

### AD-05 — Disconnect vs silence fallback per OEM/carrier (Q-01)

**Decision:** TBD in SDS after device/SIM verification (AMB-05 open). Architecture mandates: attempt standards-compliant disconnect; defined silence fallback; ledger records which actuation was used.
**Rationale:** RSK-102/RSK-04 — refusal reliability varies by OEM/carrier.
**Status:** [WARN] Open — device-matrix test required before release; SDS must define the fallback branch deterministically.
**Owner:** TA + Android dev.
**Target Date:** Before implementation complete.

### TQ-01 — History/SMS retention cap (Q-04) — OPEN

Architecture currently mandates keep-until-user-deletes (§9.2). If a cap is introduced for readability/performance, it must be explicit, user-visible, newest-preserving, and must never silently delete history. Unresolved; SDS must not invent silent pruning.

### TQ-02 — Anonymous-number handling option (Q-02) — OPEN, default fixed

Default is fixed by SRS-304 (anonymous passes, no SMS). Any user option to silence anonymous callers is a requirements change, not an SDS自由 choice.

### TQ-03 — Category vocabulary (Q-05) — OPEN, non-blocking for ARCH

Closed vs free category list for number profiles. SDS must isolate it as a single enum-or-text field so either choice fits without re-architecture.

### Implementation readiness

Ready for SDS authoring on: SI/SU decomposition, precedence, idempotency, persistence choice, channel inventory, error registry shape, traceability. Blocked before SDS sign-off: AD-03 (permission scope evidence) and AD-05 (OEM fallback branch). Release gates (must be green before approval): role/timeout matrix (RSK-102), PII-in-logs inspection (RSK-103), Play declaration + fallback demo (RSK-105), migration/reboot tests (RSK-106).

---

## 12. Authoring & Approval

Author and technical reviewer is the Software Architect & SaMD Compliance Lead (Onofrio, TA) per pipeline role definition. Facts vs opinions: decomposition, precedence, persistence choice, and traceability above are factual derivations from the approved parents; AD-01 recommendation (Kotlin canonical home) is an opinion and is labelled as such with its criterion (single-source-of-truth for time-critical policy). No upstream business input was rewritten: AMB-01…AMB-04 resolutions and RF-1…RF-10 are consumed verbatim; AMB-05/Q-01…Q-05 remain open and are tracked in §11, not decided here. Approval requires QA/RA sign-off and green release gates listed in §11.

| Role | Name | Date | Signature |
|---|---|---|---|
| Author (Software Architect) | Onofrio (TA) | 2026-10-10 | Onofrio |
| Technical Reviewer | Onofrio (TA) | 2026-10-10 | Onofrio |
| Approver (QA/RA) | TBD | — | — |

---

## 13. Change History

| Version | Date | Author | Summary of Change |
|---|---|---|---|
| 0.1.0 | 2026-10-10 | Onofrio (TA) | Initial draft: full SI/SU breakdown (Class A with rationale), adapted C4/container/deployment for on-device Android (no DAS/K8s/edge/HTTP), channel + framework interface inventory, sequence phases, cross-cutting controls, full SRS↔SU matrix, RSK→control map, open decisions AD-01…AD-05/TQ-01…TQ-03 |

---

*End of Document — CG-ARCH-001 v0.1.0*
*Next in package: CG-SDS-001 — Software Design Specification*
