# CG-SOUP-001 — SOUP / OTS Register
## call-guard · Call Guard

**Document ID:** CG-SOUP-001
**Version:** 0.1.0
**Status:** Draft
**Service:** `call-guard`
**Last Updated:** 2026-10-10
**Trace Parents:** CG-ARCH-001 §5.5 · CG-RSK-001 · CG-TP-001

---

## Table of Contents

1. [Purpose & Scope](#1-purpose--scope)
2. [Regulatory Basis](#2-regulatory-basis)
3. [Evaluation Criteria](#3-evaluation-criteria)
4. [SOUP Item Registry](#4-soup-item-registry)
5. [IEC 62304 Class Re-evaluation Log](#5-iec-62304-class-re-evaluation-log)
6. [Change Records](#6-change-records)
7. [Authoring & Approval](#7-authoring--approval)
8. [Change Log](#8-change-history)

---

## 1. Purpose & Scope

This document is the authoritative SOUP (Software Of Unknown Provenance) / OTS (Off-The-Shelf) register for **`call-guard`** (Call Guard, Android-only call-filter app).

It fulfils, by proportional application to a non-medical-device product (CG-ARCH-001 §1.2, CG-OVW-001 §2.3):

- **IEC 62304 §8.1.2** — Identify SOUP items.
- **IEC 62304 §8.1.3** — Establish SOUP item requirements (known anomalies, published anomaly list).
- **IEC 62304 §8.3** — Evaluate and document SOUP.
- **ISO 14971 §10** — Post-production information and residual risk monitoring (proportional; decision-trace retention per CG-ARCH-001 §9.2).

**Scope:** All third-party runtime platform, runtime libraries, and build/test tools consumed by `call-guard` as decomposed in CG-ARCH-001 §5 (SI-DOM-01/02, SI-APP-01/02, SI-INF-01/02). This register is synchronised with:

- CG-ARCH-001 §5.5 — SOUP integration table (consumption map; this register is the normative detail).
- CG-RSK-001 (RSK-102 platform reliability, RSK-103 PII in logs, RSK-104 store disclosure, RSK-105 Play permission policy, RSK-106 durability).
- CG-TP-001 — qualification evidence (device matrix, migration/reboot tests, log-inspection gate, permission-gate tests).
- Authoritative version pins at implementation setup: `android/gradle/libs.versions.toml`, `android/build.gradle(.kts)`, `pubspec.yaml` + `pubspec.lock`. No `package.json` exists in this project.

**Recorded deviations from the H.Core template (binding, not omissions):**

1. **No Node.js, no TypeScript, no DAS/MongoDB, no HTTP framework, no K8s/edge/mesh.** CG-ARCH-001 §2.2 and §8 exclude the entire H.Core server stack: there is no server, no network surface, no `/health`, no `/metrics`. The template's SOUP-01 (Node.js) / SOUP-02 (TypeScript) rows therefore do not apply and are not carried into this register.
2. **No CG-SBOM-001 exists yet.** When an SBOM is introduced, its item list must equal SOUP-01…SOUP-08 below, and any version change must update both documents in the same change record.
3. **No implementation artefacts exist yet** (repository contains only `docs/` at v0.1.0). The versions in §4 are the qualified baseline to be frozen verbatim in the pin files above at project setup. Any divergence at setup requires a CR-SOUP-CG entry before build sign-off.
4. **No INTERNET permission is declared by the app.** This is a compliance-by-design control (GDPR minimisation, CG-ARCH-001 P-05): even a compromised SOUP item has no declared network channel for PII exfiltration. Any future request for `INTERNET`, analytics, crash-reporting with identifiers, sync, or backup transmitting PII is a scope Change Request with privacy re-review, not a SOUP bump.

> **Rule:** This document must be updated and a new change record (`CR-SOUP-CG-NNN`) appended to §6 whenever a SOUP item is added, removed, or its version is changed. Any such change must also trigger a re-evaluation entry in §5 if the affected SU's IEC 62304 class may have changed. Parallel updates required: CG-ARCH-001 §5.5, the version-pin files, and the future SBOM.

---

## 2. Regulatory Basis

| Regulation / Standard | Relevant Clause | Obligation | Application to Call Guard |
|---|---|---|---|
| IEC 62304 | §8.1.2, §8.1.3, §8.3 | Identify, document, and evaluate all SOUP items | This register; one entry per runtime library plus platform; build/test tools marked as such |
| IEC 62304 | §5.3 | Architectural decomposition and classification | All consuming SUs are Class A per CG-ARCH-001 §5; §4 records per-item class impact |
| ISO 14971 | §10 | Monitor post-production information; update risk file on new hazards | Anomaly-list URLs in §4 are the monitoring sources; new relevant anomaly → RSK update + CR-SOUP-CG + §5 entry |
| ISO 27001 | A.14.2.1 | Verify integrity of third-party components (secure development) | Pinned versions + lockfiles + log-scrub gate (RSK-103) + no exported provider (RSK-104) |
| GDPR Art. 25/32 | — | Data protection by design; confidentiality/integrity | Per-item confirmation in §4: no SOUP item transmits PII off-device; no INTERNET permission; app-private store only |
| Google Play policy | Restricted permissions (SMS) | `SEND_SMS` / SMS-read scopes require declaration and core-functionality justification | No SOUP item in §4 expands the permission scope; AD-03 (minimal SMS-read scope) is unaffected by any item below |
| ISO 13485 §4.2.5 (proportional) | Record retention | No silent pruning of history | SOUP-04 (Room) configured with keep-until-user-deletes; no auto-vacuum/prune behaviour relied upon |

---

## 3. Evaluation Criteria

Each SOUP item in §4 was assessed against the following criteria. Verdicts are recorded per item; failures block adoption.

| Criterion | Description | Pass threshold applied |
|---|---|---|
| **Functional Fit** | The library does exactly what is required with minimal surface area. Only consumed APIs are listed in Consumed By. | No unused major capability pulled in without justification. |
| **Active Maintenance** | Actively maintained with recent releases and responsive issue triage. | Release within ~12 months of 2026-10-10, or platform LTS patch channel (Android security bulletins). |
| **Published Anomaly List** | Maintainer publishes a changelog / CVE response process. | URL in every §4 entry; bulletins subscribed for SOUP-01. |
| **Known Anomalies** | Open CVEs or known bugs relevant to the consumed surface at the pinned version. | None known relevant at authoring date; any future relevant anomaly triggers §5 + RSK review. Stated explicitly per item. |
| **Dependency Footprint** | Minimal transitive dependencies preferred. | Transitive set reviewed at setup; Room/Dart pulling large graphs noted and accepted only where no smaller fit exists (libphonenumber accepted for correctness). |
| **Licence** | MIT, ISC, Apache-2.0, or BSD-compatible required. GPL/proprietary prohibited, except the unavoidable Android platform SDK (SOUP-01), which is recorded as a platform exception with rationale. | SOUP-02…SOUP-08 all Apache-2.0 / BSD-3-Clause / EPL-1.0 (test-only) / public domain (SQLite). No GPL in the tree. Verified via `gradle dependencies` + `flutter pub deps` at setup. |
| **No-exfiltration** (project-specific, GDPR) | The item, as configured, does not transmit PII off-device and does not require INTERNET. | Verified per item in §4; offline test with network disabled (CG-TP-001) is the qualification proof. |

Fact/opinion separation: the table above and the per-item licence/version facts are verifiable. The judgement "no smaller fit exists" for libphonenumber (§4, SOUP-06) is an opinion; criterion: hand-rolled E.164/short-code parsing has a documented defect history for edge numbering plans, and the cost of a mis-parse (wrong SMS target, RSK-107) exceeds the cost of one Apache-2.0 dependency.

---

## 4. SOUP Item Registry

Baseline context shared by all entries: whole-product highest IEC 62304 class is **A** (CG-ARCH-001 §5: no failure can cause death or clinical serious injury; worst case is a missed urgent call, a privacy breach, unwanted SMS cost, or Store rejection). No SOUP item below changes any SU classification. Any future clinical claim re-opens classification for all affected SUs.

---

### SOUP-01 — Android OS + Android SDK / Platform APIs

| Field | Value |
|---|---|
| **SOUP ID** | SOUP-01 |
| **Name** | Android OS + Android SDK platform APIs (`CallScreeningService`, `CallResponse`, `SmsManager`, SMS provider, `ContactsContract.PhoneLookup`, role/permission framework) |
| **Version (Pinned)** | `minSdk 29` (Android 10); `compileSdk 35`, `targetSdk 35`; device-matrix API 29–35 per CG-ARCH-001 §2.2/§8. Baseline qualified against Android security bulletin level 2026-10-01. Exact `compileSdk`/`targetSdk`/patch level frozen in `libs.versions.toml` at setup. |
| **Licence** | Platform exception: Android SDK Licence Agreement (proprietary) + Apache-2.0 framework components. Unavoidable: only this platform provides pre-ring interception. No GPL. Accepted as platform qualifier, not a selectable library. |
| **Consumed By** | SU-INF-01-01 (screening host, actuation), SU-INF-02-01 (contacts lookup), SU-INF-03-01 (`SmsManager` send), SU-INF-04-01 (SMS-provider query), SU-INF-05-01 (app-private storage paths, backup flags), SU-APP-08-01 (role/permission state) |
| **Layer** | Runtime / Platform |
| **Purpose** | Sole provider of pre-ring call notification, disconnect/silence actuation, SMS transport, contacts presence, and role/permission enforcement. No alternative exists on Android. |
| **Qualification Method** | Device/SIM matrix test per CG-TP-001 (API 29–35, at least 3 OEMs): screening latency within platform timeout, disconnect-vs-silence fallback branch (AD-05), role-missing path, permission-denied paths. OEM deviations recorded as test evidence, not code branches beyond the SDS fallback. |
| **Known Anomalies at Pinned Version** | None known relevant to the consumed surface (screening, `SmsManager`, providers) at bulletin level 2026-10-01. Platform bugs manifest as fail-open (call rings) per CG-ARCH-001 P-08, never fail-closed. |
| **Anomaly List URL** | https://developer.android.com/security/bulletin · https://developer.android.com/sdk/api_diff/35/changes |
| **IEC 62304 Class Impact** | Consuming SUs are Class A. No change. Platform qualifier; OEM variance is controlled operationally via RSK-102, not by reclassification. |
| **No-exfiltration note** | OS itself is the telephony transport (carrier SMS delivery is functional, not data collection). App declares no INTERNET; no OS API used here performs analytics upload. |

---

### SOUP-02 — Kotlin Standard Library

| Field | Value |
|---|---|
| **SOUP ID** | SOUP-02 |
| **Name** | Kotlin Standard Library (`kotlin-stdlib`) |
| **Version (Pinned)** | `2.0.21` (frozen in `libs.versions.toml`; aligned with Kotlin Gradle plugin `2.0.21`) |
| **Licence** | Apache-2.0 |
| **Consumed By** | All native SUs: SU-DOM-01-01, SU-DOM-02-01, SU-DOM-02-02, SU-DOM-03-01, SU-DOM-03-02, SU-DOM-04-01 (if Kotlin is the canonical domain home per AD-01), SU-APP-01-01…SU-APP-08-01 (native side), SU-INF-01-01…SU-INF-06-01 |
| **Layer** | Runtime |
| **Purpose** | Language runtime for the native module and (per AD-01 recommendation) the canonical pure-domain policy: immutable value objects, collections, null-safety. |
| **Qualification Method** | `tsc`-equivalent gate is `kotlinc` warnings-as-errors on release + unit tests for every SU-DOM rule (normalisation, precedence, eligibility) runnable on JVM without a device. No Android imports in Domain module enforced by lint/dependency rule. |
| **Known Anomalies at Pinned Version** | None known relevant to consumed surface (collections, text, ranges). No CVE relevant to stdlib-only usage at authoring date. |
| **Anomaly List URL** | https://github.com/JetBrains/kotlin/releases · https://kotlinlang.org/docs/releases.html |
| **IEC 62304 Class Impact** | Consuming SUs are Class A. No change. |
| **No-exfiltration note** | Pure computation library; performs no I/O, no network. |

---

### SOUP-03 — kotlinx-coroutines (core + android)

| Field | Value |
|---|---|
| **SOUP ID** | SOUP-03 |
| **Name** | kotlinx-coroutines (`kotlinx-coroutines-core`, `kotlinx-coroutines-android`) |
| **Version (Pinned)** | `1.9.0` (frozen in `libs.versions.toml`) |
| **Licence** | Apache-2.0 |
| **Consumed By** | SU-INF-01-01 (off-path scheduling only — screening decision itself is synchronous), SU-INF-03-01 (send off-path), SU-INF-05-01 (transactional writes), SU-APP-01-01 (path separation enforcement) |
| **Layer** | Runtime (concurrency) |
| **Purpose** | Structured off-path execution for Room writes and SMS sends so the screening decision path performs zero blocking I/O (CG-ARCH-001 P-03, SRS-301). |
| **Qualification Method** | Concurrency tests: decision returns before any write/send completes; snapshot-only decision verified with Room and `SmsManager` faked; main-safety and dispatcher-injection tests; no `runBlocking` or blocking call on the screening path (lint rule + code review gate). |
| **Known Anomalies at Pinned Version** | None known relevant to `Dispatchers.IO`/`Main.immediate` usage at 1.9.0. |
| **Anomaly List URL** | https://github.com/Kotlin/kotlinx.coroutines/releases |
| **IEC 62304 Class Impact** | Consuming SUs are Class A. No change. Misuse mode (blocking the screening path) is an application fault, not a SOUP defect, and is guarded by the lint rule above. |
| **No-exfiltration note** | Scheduling only; no I/O, no network. |

---

### SOUP-04 — AndroidX Room + SQLite + DataStore/SharedPreferences

| Field | Value |
|---|---|
| **SOUP ID** | SOUP-04 |
| **Name** | AndroidX Room (`room-runtime`, `room-ktx`, `room-compiler`), bundled SQLite, `datastore-preferences` (fallback: app-private `SharedPreferences`) |
| **Version (Pinned)** | Room `2.6.1`, DataStore Preferences `1.1.1` (Room compiler = build-only code generation; frozen in `libs.versions.toml`) |
| **Licence** | Apache-2.0 (Room, DataStore); SQLite public domain (bundled via platform/Room) |
| **Consumed By** | SU-INF-05-01 (history, lists, profiles, triage flags, template text, blacklist-SMS flag, snapshot-cache source) |
| **Layer** | Persistence (Infrastructure) |
| **Purpose** | Transactional on-device store (history + lists + profiles) and single-value settings (SMS template, blacklist-SMS flag) with reboot/update durability (SRS-102/103/401/403/705, RSK-106). |
| **Qualification Method** | Migration tests (schema N→N+1 with production-shaped data), reboot/update durability tests, synchronous-commit test proving SRS-307 immediacy (write visible to next screening snapshot), no-silent-prune test (row count never decreases except on explicit user delete), `allowBackup=false` manifest assertion. |
| **Known Anomalies at Pinned Version** | None known relevant at Room 2.6.1 for the consumed DAO/transaction surface. Compiler is build-only and does not execute on-device. |
| **Anomaly List URL** | https://developer.android.com/jetpack/androidx/releases/room · https://developer.android.com/jetpack/androidx/releases/datastore |
| **IEC 62304 Class Impact** | SU-INF-05-01 is Class A. No change. Store failure mode is data-loss/re-classification effort (RSK-106), not injury. |
| **No-exfiltration note** | App-private databases/prefs only (`/data/data/<pkg>/`); no exported `ContentProvider`; backup disabled; no sync. Verified by manifest/provider inspection test. |

---

### SOUP-05 — Flutter SDK + Dart SDK + Material

| Field | Value |
|---|---|
| **SOUP ID** | SOUP-05 |
| **Name** | Flutter SDK (engine, `MethodChannel` binary messenger) + Dart SDK + Material widget library |
| **Version (Pinned)** | Flutter stable `3.24.5` / Dart `3.5.4` (minimum; exact channel revision frozen via `pubspec.yaml` + `pubspec.lock` and recorded in SDS at setup; upgrades require CR-SOUP-CG) |
| **Licence** | BSD-3-Clause (Flutter, Dart, Material) |
| **Consumed By** | SU-INF-06-01 (platform-channel client, codec), SU-INF-07-01 (all six UI surfaces: onboarding, blocked history, SMS triage, whitelist, blacklist, template settings + profile detail) |
| **Layer** | Presentation |
| **Purpose** | Renders all user surfaces and transports validated intents/results over the platform channel. Holds zero screening policy: Dart renders decisions the native layer committed (CG-ARCH-001 P-02). |
| **Qualification Method** | Widget tests for triage CTAs (exactly two, correctly labelled), history filter/sort, template editor validation, protection-status states; channel-contract tests (method names, codecs, error-code mapping per CG-ARCH-001 §6.2/§9.4); `flutter analyze` clean; no Dart-side screening-duplication lint (AD-01 duplication ban). |
| **Known Anomalies at Pinned Version** | None known relevant to `MethodChannel` request/response and Material list/form widgets at 3.24.5. Flutter tool telemetry is developer-workstation-only, opt-out, and is not shipped in the APK. |
| **Anomaly List URL** | https://docs.flutter.dev/release/release-notes · https://github.com/flutter/flutter/releases · https://dart.dev/guides/whats-new |
| **IEC 62304 Class Impact** | SU-INF-06-01 and SU-INF-07-01 are Class A. No change. UI failure mode is mis-tap/reversible (RSK-108 confirm+undo), not injury. |
| **No-exfiltration note** | No analytics/crash-reporting SDK is included. Release APK verified to declare no INTERNET permission and to contain no network client for telemetry. Any future crash-reporting tool requires scrubber + opt-in + scope CR (CG-ARCH-001 §9.3). |

---

### SOUP-06 — Google libphonenumber

| Field | Value |
|---|---|
| **SOUP ID** | SOUP-06 |
| **Name** | Google libphonenumber (`com.googlecode.libphonenumber:libphonenumber`) |
| **Version (Pinned)** | `8.13.47` (frozen in `libs.versions.toml`; metadata-only updates treated as version changes requiring CR-SOUP-CG) |
| **Licence** | Apache-2.0 |
| **Consumed By** | SU-DOM-01-01 (E.164/national normalisation, dialability validation, short-code/alphanumeric discrimination) via the native adapters that feed it; enforcement point for SRS-304/305 guards in SU-INF-03-01 |
| **Layer** | Domain helper (pure, no I/O) |
| **Purpose** | Correct phone-number parsing and classification so normalisation, hidden-vs-visible discrimination, and never-SMS rules (SRS-304/305) do not rely on hand-rolled regex. Single smallest-fit library for this risk (RSK-107 cost guard). |
| **Qualification Method** | Unit-test corpus: national/international formats, short codes, alphanumeric senders, empty/hidden IDs, carrier edge cases from CG-TP-001; unknown-region input must resolve to fail-safe (no SMS, explicit ledger reason), never to a guessed dialable number. Offline use only — no metadata download at runtime. |
| **Known Anomalies at Pinned Version** | None known relevant to parse/validate-only usage at 8.13.47. Metadata staleness (new numbering ranges) is the known residual: handled as fail-safe unknown, logged without PII, and refreshed only via pinned library bump (never runtime download). |
| **Anomaly List URL** | https://github.com/google/libphonenumber/releases |
| **IEC 62304 Class Impact** | SU-DOM-01-01 is Class A. No change. Mis-parse worst case is a missed call or an avoided SMS (operational), not injury. |
| **No-exfiltration note** | Offline parser; performs no network access in the consumed configuration. Verified by no-INTERNET manifest + offline test. |

---

### SOUP-07 — Gradle + Android Gradle Plugin (build-only)

| Field | Value |
|---|---|
| **SOUP ID** | SOUP-07 |
| **Name** | Gradle + Android Gradle Plugin (AGP) + Kotlin Gradle plugin |
| **Version (Pinned)** | Gradle `8.9`, AGP `8.5.2`, Kotlin Gradle plugin `2.0.21` (frozen in `gradle/wrapper/gradle-wrapper.properties` + `libs.versions.toml`) |
| **Licence** | Apache-2.0 |
| **Consumed By** | Build of SI-INF-01 and SI-INF-02 only. Does not execute on-device. |
| **Layer** | Build (no runtime presence) |
| **Purpose** | Deterministic APK assembly, Room schema code generation, version-catalog enforcement, release signing pipeline. |
| **Qualification Method** | Clean reproducible build in CI (`--offline` check after first fetch where feasible); wrapper checksum verification; `dependencies` lock verification; Room schema export diff review. Build failure is fail-closed at build time, never a field risk. |
| **Known Anomalies at Pinned Version** | None relevant. Build tools do not execute in production. |
| **Anomaly List URL** | https://docs.gradle.org/8.9/release-notes.html · https://developer.android.com/build/releases/gradle-plugin |
| **IEC 62304 Class Impact** | Build tool only; no runtime SU classification impact. No IEC 62304 class assigned. |
| **No-exfiltration note** | Workstation-only. Gradle plugin-portal fetches at build time carry no device PII. |

---

### SOUP-08 — JUnit + AndroidX Test / Espresso (test-only)

| Field | Value |
|---|---|
| **SOUP ID** | SOUP-08 |
| **Name** | JUnit4 + AndroidX Test (`runner`, `rules`) + Espresso (`espresso-core`) |
| **Version (Pinned)** | JUnit `4.13.2`, AndroidX Test `1.6.1`, Espresso `3.6.1` (frozen in `libs.versions.toml`; `testImplementation` / `androidTestImplementation` scopes only) |
| **Licence** | EPL-1.0 (JUnit4, test scope only — never shipped) / Apache-2.0 (AndroidX Test, Espresso) |
| **Consumed By** | CG-TP-001 evidence only. Not shipped in the release APK (verified via APK dependency inspection). |
| **Layer** | Test (no runtime presence) |
| **Purpose** | Unit, integration, migration, and on-device UI/permission test execution producing the qualification evidence cited in SOUP-01…SOUP-06. |
| **Qualification Method** | Test tooling itself is qualified by green runs on the pinned device matrix; flaky-test quarantine policy in CG-TP-001. A test-tool defect can only hide a defect, never cause a field failure; the log-inspection and matrix gates are independent of any single test library. |
| **Known Anomalies at Pinned Version** | None relevant. Test tools do not execute in production. |
| **Anomaly List URL** | https://github.com/junit-team/junit4/blob/main/doc/ReleaseNotes4.13.2.md · https://developer.android.com/jetpack/androidx/releases/test |
| **IEC 62304 Class Impact** | Test tooling only; no runtime SU classification impact. No IEC 62304 class assigned. |
| **No-exfiltration note** | Test scope only; never present in the signed release APK. |

---

**Deliberately excluded and prohibited without a scope Change Request:** any HTTP client/server framework, any ORM/network sync (including DAS/MongoDB clients), any analytics/crash-reporting SDK, any contacts-upload or spam-database SDK, any ML scoring library. Proposing any of these re-opens CG-OVW-001 §2.2 (on-device-only principle), GDPR review, RSK-103/104/105, and CG-ARCH-001 §5.5.

---

## 5. IEC 62304 Class Re-evaluation Log

> Mandatory per IEC 62304 §8.3. A new entry is added for every SOUP version change that could affect the safety classification of a consuming Software Unit. Baseline rule for this product: every SU is Class A (CG-ARCH-001 §5); a version bump alone cannot promote an SU to B/C without a new clinical-harm justification reopening CG-OVW-001 §2.3.

*No re-evaluations recorded yet (baseline document v0.1.0). The initial classification reference is CG-ARCH-001 §5.1–§5.4 (all SUs Class A with per-SU rationale).*

---

## 6. Change Records

### CR-SOUP-CG-001 — Initial SOUP Register

| Field | Value |
|---|---|
| **Change Record ID** | CR-SOUP-CG-001 |
| **Date** | 2026-10-10 |
| **Author** | Onofrio (TA) |
| **Type** | Initial creation |
| **Items Affected** | SOUP-01 through SOUP-08 |
| **Summary** | Initial baseline of the CG-SOUP-001 register. 6 runtime/platform SOUP items (SOUP-01…SOUP-06) plus 2 non-runtime items (SOUP-07 build-only, SOUP-08 test-only) documented with pinned versions, licences, consuming SUs per CG-ARCH-001 §5.5, qualification methods per CG-TP-001, anomaly-list URLs, and per-item GDPR no-exfiltration confirmations. H.Core Node.js/TypeScript/DAS/MongoDB rows explicitly recorded as not applicable (§1, deviations 1–4). Versions to be frozen verbatim in `libs.versions.toml`, `build.gradle(.kts)`, `gradle-wrapper.properties`, `pubspec.yaml`/`pubspec.lock` at project setup. |
| **Impact on IEC 62304 Classes** | Baseline establishment — no class changes. Whole-product highest class remains A per CG-ARCH-001 §5.4. |

---

## 7. Authoring & Approval

Author and technical reviewer is the Software Architect & SaMD Compliance Lead (Onofrio, TA) per pipeline role definition. Review performed against trace parents CG-ARCH-001 §5.5 (consumption map match), CG-RSK-001 (RSK-102/103/104/105/106 controls preserved), and CG-TP-001 (each runtime SOUP has a stated qualification proof). No upstream business input was rewritten. Approval requires QA/RA sign-off.

| Role | Name | Date | Signature |
|---|---|---|---|
| Author (Software Architect) | Onofrio (TA) | 2026-10-10 | Onofrio |
| Technical Reviewer | Onofrio (TA) | 2026-10-10 | Onofrio |
| Compliance / QA Reviewer | TBD | — | — |
| Approver | TBD | — | — |

---

## 8. Change History

| Date | Author | Summary of Change |
|---|---|---|
| 2026-10-10 | Onofrio (TA) | v0.1.0 — Initial draft. 8 SOUP items registered (SOUP-01 through SOUP-08; 6 runtime + 1 build-only + 1 test-only). Baseline versions set for freezing at project setup. CR-SOUP-CG-001 recorded. H.Core server-stack deviation recorded in §1. |

---

*End of Document — CG-SOUP-001 v0.1.0*
*Next: SDS dependency list must equal SOUP-01…SOUP-06 runtime set; any delta requires CR-SOUP-CG-NNN + §5 entry.*
