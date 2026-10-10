# Call Guard — Software Design Specification

**Document ID:** CG-SDS-001
**Version:** 0.1.0
**Status:** Draft
**IEC 62304 Phase:** 5.4 — Software Detailed Design (proportional application; product is not a medical device per CG-OVW-001 §2.3)
**Service:** `call-guard`
**Date:** 2026-10-10

**Trace Parents:**
- CG-OVW-001 — Service Overview v0.1.0
- CG-UC-001 — Use Cases v0.1.0
- CG-UN-001 — User Needs v0.1.0
- CG-RSK-001 — Risk Analysis v0.1.0
- CG-SRS-001 — Software Requirements Specifications v0.1.0
- CG-ARCH-001 — Software Architecture v0.1.0
- CG-TP-001 — Test Plan v0.1.0

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
| 0.1.0 | 2026-10-10 | Onofrio (TA) | Initial draft from approved CG-OVW-001, CG-UC-001, CG-UN-001, CG-RSK-001, CG-SRS-001 and parent CG-ARCH-001; deterministic SU design for all 22 SUs |

---

## Table of Contents

1. [Purpose & Scope](#1-purpose--scope)
2. [Document Conventions](#2-document-conventions)
3. [Data Models](#3-data-models)
4. [Configuration Specification](#4-configuration-specification)
5. [Identity Context (platform)](#5-identity-context-platform)
6. [Platform-Channel Contract (HTTP N/A)](#6-platform-channel-contract-http-na)
7. [Error Code Registry](#7-error-code-registry)
8. [Domain Layer — Software Unit Design](#8-domain-layer--software-unit-design)
9. [Application Layer — Software Unit Design](#9-application-layer--software-unit-design)
10. [Infrastructure Layer — Software Unit Design](#10-infrastructure-layer--software-unit-design)
11. [Configuration Parameters](#11-configuration-parameters)
12. [SRS-to-SU Traceability Matrix](#12-srs-to-su-traceability-matrix)

---

## 1. Purpose & Scope

### 1.1 Purpose

This Software Design Specification (SDS) is the IEC 62304 §5.4 detailed design record for `call-guard` (Call Guard, Android-only call-filter app). It translates the architectural decomposition defined in CG-ARCH-001 §5 (6 Software Items, 22 Software Units, all Class A) into precise, implementable specifications that a developer can implement without interpretation.

Specifically, this document defines:

- **Data models** for all **Room/SQLite tables** and **app-private preferences** this app reads or writes on-device. There is no server, no MongoDB, no DAS Wire Protocol. §3 replaces the H.Core template's MongoDB/BSON shapes with normative Room entity definitions.
- **Behavioural algorithms** for each domain SU (§8) and each application use-case SU (§9) — exact logic, branching conditions, unhappy paths, and idempotency rules.
- **Interface contracts** (input types, output types, error types) for every port and adapter, including the normative **platform-channel codec** (§6, §10.6).
- **Configuration parameters** including keys, types, defaults, and validation rules (§4, §11).
- **The error code registry** (§7) mapping every domain/platform error to its in-app surfacing. There is no HTTP surface; the template's HTTP-status column is replaced by the surfacing contract per CG-ARCH-001 §9.4.

Normative rule: where this SDS and CG-ARCH-001 conflict, CG-ARCH-001 governs decomposition and layering; where this SDS and CG-SRS-001 conflict, CG-SRS-001 governs required behaviour. Any deliberate deviation from a Trace Parent is recorded explicitly in the affected section — no silent reinterpretation.

### 1.2 Relationship to Other Documents

| Document | Relationship |
|---|---|
| CG-ARCH-001 | Parent — architecture defines SI/SU decomposition, layering (Clean/Hexagonal, dependency inward), container topology, channel inventory, error-registry shape; this document specifies the implementation detail of each SU |
| CG-SRS-001 | Grandparent — each SU specification satisfies at least one SRS requirement (SRS-101…SRS-1005, 38 items); §12 proves bidirectional traceability |
| CG-TP-001 | Sibling — test cases TP-101…TP-1203 reference table names, field names, channel method names, and error codes defined in this document |
| CG-RSK-001 | Grandparent (risk) — each architectural risk control (RSK-101…RSK-109) is bound to a deterministic mechanism in §8–§10 |
| CG-OVW-001, CG-UC-001, CG-UN-001 | Great-grandparents — business scope (RF-1…RF-10, UC-01…UC-08, UN-101…UN-114); this document introduces no new business behaviour |

### 1.3 Template deviations (binding)

The H.Core SDS template assumes a server microservice (Node.js 20+, TypeScript strict/ESM, MongoDB via DAS, edge identity headers, HTTP API). None of these apply to Call Guard per CG-ARCH-001 §2.2 row 8 and §8. Deviations are deliberate and recorded once here:

| Template assumption | Call Guard reality (normative) | Defined in |
|---|---|---|
| MongoDB collections via DAS Wire Protocol, BSON shapes | Room/SQLite tables (app-private) + DataStore/SharedPreferences; no network, no DAS, no MongoDB | §3, §10.5 |
| TypeScript strict/ESM domain types | Kotlin (native + pure domain module) as canonical home per ARCH AD-01; Dart renders only committed results, duplicates no policy | §2.2, §8 |
| Edge/mesh identity headers (`sub`, `domain`, `scopes`, `client_id`) | Single-user device: identity context = Android role + permission grant state + OS version, consumed not re-hosted | §5 |
| HTTP API contract (`/api/...`, `/health`) | N/A — no HTTP surface. Sole bridge is the versioned `MethodChannel` contract | §6, §10.6 |
| Env-var configuration (`[SVC]_PORT`, `[SVC]_DAS_HOST`) | N/A — app-private prefs keys + `BuildConfig` constants; no server ports, no DAS endpoints | §4, §11 |
| HTTP-status error mapping | In-app surfacing mapping (banner / inline / ledger / field error), static messages, no PII, no stack traces | §7 |

---

## 2. Document Conventions

### 2.1 Naming Conventions

| Convention | Rule | Example |
|---|---|---|
| SU class names | PascalCase, English, matching CG-ARCH-001 §5 | `ScreeningDecision`, `ScreenIncomingCallUseCase` |
| Port interfaces | `I` + PascalCase (Kotlin `interface`) | `IRejectedCallRepository`, `ISmsSender` |
| Adapter / DAO names | PascalCase + role suffix | `CallScreeningAdapter`, `RejectedCallDao` |
| Error codes | SCREAMING_SNAKE_CASE, from §7 registry only | `ROLE_MISSING`, `SMS_SKIPPED_BLACKLIST_POLICY` |
| Room tables / columns | `snake_case` | `rejected_calls.normalized_number` |
| Preference keys | `snake_case` with `cg_` prefix | `cg_sms_template_text` |
| Platform-channel methods | `camelCase`, versioned prefix `cg/v1/` | `cg/v1/classifyNumber` |

### 2.2 Type System

Canonical implementation language is **Kotlin** (JVM/Android). All domain SUs (§8) live in a `pure` Kotlin module with **zero** `android.*`, `androidx.*`, `io.flutter.*` imports. Nullability is explicit via Kotlin nullable types (`String?` vs `String`); no platform-type leakage (all platform returns are wrapped at the adapter boundary). Immutability: domain value objects are Kotlin `data class` with `val` properties only (equivalent of `Object.freeze` in the pipeline policy); any "update" returns a copy via `copy()`.

Dart/Flutter is presentation-only: it MUST NOT re-implement `PhoneNumber` normalisation, `ScreeningDecision` precedence, or `SmsEligibility`. Dart receives validated values over the channel and renders them. Any shared enum (e.g., `SmsStatus`, `DecisionOrigin`) is defined normatively in §6.3 and mirrored 1:1 in Dart with an exhaustive `switch`; unknown future values map to an explicit `unknown` fallback that surfaces `INTERNAL_ERROR`.

Static analysis gates: Kotlin `strict` null checks (no `!!` in Domain/Application layers — adapters may use guarded `!!` only after explicit null check with justification comment), `Detekt` complexity limits, and a forbidden-import check that fails the build if `android.*` appears under `domain/` or `application/`.

### 2.3 Timestamp Representation

All timestamps are stored as **INTEGER milliseconds since Unix epoch (UTC)** in Room (`Long`, `System.currentTimeMillis()` at the adapter boundary only; Domain/Application receive time via injected `IClock.nowUtcMillis()`). Over the platform channel and in diagnostics they are rendered as **UTC ISO 8601 strings** (`"2026-10-10T09:41:00.000Z"`). Ordering is by the integer column; the ISO form is display-only. No local-timezone storage; no second-precision truncation.

### 2.4 Identifier Format

- History records and triage links: **UUIDv4 strings** (RFC 4122, lowercase, e.g. `"3f6a9c2e-1b4d-4f8a-9c2e-7d1a5b3c9e0f"`), generated with `java.util.UUID.randomUUID().toString()` in `RecordRejectedCallUseCase` only. This is the **idempotency key** for exactly-once SMS (SRS-501).
- List entries: natural key = **`normalized_number`** (E.164-or-national canonical form from §8.1), UNIQUE. No surrogate UUID for list rows — normalisation collisions collapse by design (TP-701).
- Correlation IDs in diagnostics: UUIDv4 per screening event (`screening_event_id`), propagated from decision to record to SMS ledger; never contains PII.

### 2.5 Domain Error Model

Domain and application errors are typed `DomainError` (Kotlin sealed class):

```kotlin
sealed class DomainError(val code: String, val message: String, val context: Map<String, String> = emptyMap()) {
  // context carries ONLY PII-free machine data: e.g. "reason" -> "blacklisted", "template_chars" -> "512".
  // Never: phone numbers, contact names, SMS bodies.
}
```

Domain errors are never exposed raw to the user or the channel. Infrastructure maps each `code` to the static user-facing string and corrective action in §7. Logging of a `DomainError` goes through `DiagnosticsLogger.scrub()` (§10.8) which drops `context` keys not on an allowlist.

---

## 3. Data Models

Persistence is **Room/SQLite (app-private internal storage)** for relational data and **DataStore/SharedPreferences (app-private)** for two scalar settings. Database name: `call_guard.db`, schema version `1`, `exportSchema = true` (schema JSON checked into VCS). `allowBackup = false` (per ARCH AD-02) — no backup transport of PII. No exported `ContentProvider`. All tables use `IMMEDIATE` transactions for decision-path writes.

Conventions for all tables: primary key `id INTEGER PRIMARY KEY AUTOINCREMENT` (internal row handle, never exposed over the channel); business identity in a UNIQUE column; `created_at_ms INTEGER NOT NULL`; no soft-delete flag — history rows are never deleted except by explicit user "delete entry / delete all" (which hard-deletes the row; list removal never deletes history — ARCH §9.2); no `domain`/`tenant` column (single-user device, no multi-tenancy by design).

### 3.1 Rejected-call history — `rejected_calls`

One row per rejected call (SRS-401). Never aggregated, never overwritten. Written transactionally by `RecordRejectedCallUseCase`; SMS status updated once by `SendAutoReplyUseCase` and at most once more by manual retry (SRS-902).

| Column | Type | Required | Description | Mutability |
|---|---|---|---|---|
| `id` | INTEGER PK AI | Yes | Internal row handle | System-assigned, immutable |
| `event_id` | TEXT UNIQUE | Yes | UUIDv4 idempotency key for exactly-once SMS | System-assigned, immutable |
| `normalized_number` | TEXT | Yes | Canonical number from SU-DOM-01-01; indexed | System-assigned, immutable |
| `display_number` | TEXT | Yes | As-received caller string for display in list context only | System-assigned, immutable |
| `called_at_ms` | INTEGER | Yes | Call time, UTC ms | System-assigned, immutable |
| `outcome` | TEXT | Yes | Always `"rejected"` in v1 (reserved: `"rejected_blacklist"`, `"rejected_unknown"`) | System-assigned, immutable |
| `decision_origin` | TEXT | Yes | Enum: `unknown` \| `blacklist` | System-assigned, immutable |
| `actuation` | TEXT | Yes | Enum: `disconnect` \| `silence_fallback` \| `none_role_missing` (for ledger honesty per AD-05) | System-assigned, immutable |
| `sms_status` | TEXT | Yes | Enum: `pending` \| `sent` \| `failed` \| `skipped` | System-updated (send completion / manual retry) |
| `sms_skip_reason` | TEXT NULL | No | Non-null iff `sms_status='skipped'`: `blacklisted` \| `non_dialable` \| `hidden` | System-updated, immutable after set |
| `sms_fail_reason` | TEXT NULL | No | Non-null iff `sms_status='failed'`: `no_permission` \| `no_service` \| `null_pdu` \| `radio_error` \| `store_unwritable` | System-updated (retry may overwrite once) |
| `sms_sent_at_ms` | INTEGER NULL | No | Send-completion time | System-updated, immutable after set |
| `template_ref` | TEXT NULL | No | Hash (`SHA-256 hex, first 16 chars`) of template text used; never the body (SRS-402) | System-assigned, immutable |
| `retry_count` | INTEGER | Yes | `0` at create; max `1` (SRS-902 enforced by CHECK) | System-updated, monotonic |
| `notes` | TEXT | Yes | Free text, default `""` | User-editable |
| `created_at_ms` | INTEGER | Yes | Row creation time | System-assigned, immutable |

Constraints: `CHECK (retry_count BETWEEN 0 AND 1)`; `CHECK (outcome = 'rejected')`; `CHECK (sms_status IN ('pending','sent','failed','skipped'))`.

**Indexes:**

| Index | Columns | Type | Purpose |
|---|---|---|---|
| `uq_rejected_calls_event` | `event_id` | UNIQUE | Idempotency + retry lookup |
| `ix_rejected_calls_number_time` | `normalized_number`, `called_at_ms DESC` | Non-unique | Profile detail linkage (SRS-802), triage join (SRS-601) |
| `ix_rejected_calls_time` | `called_at_ms DESC` | Non-unique | History list ordering (SRS-403/801) |

SQL (normative, Room `@Entity` must generate an equivalent schema):

```sql
CREATE TABLE rejected_calls (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id TEXT NOT NULL UNIQUE,
  normalized_number TEXT NOT NULL,
  display_number TEXT NOT NULL,
  called_at_ms INTEGER NOT NULL,
  outcome TEXT NOT NULL CHECK (outcome = 'rejected'),
  decision_origin TEXT NOT NULL CHECK (decision_origin IN ('unknown','blacklist')),
  actuation TEXT NOT NULL CHECK (actuation IN ('disconnect','silence_fallback','none_role_missing')),
  sms_status TEXT NOT NULL CHECK (sms_status IN ('pending','sent','failed','skipped')),
  sms_skip_reason TEXT CHECK (sms_skip_reason IN ('blacklisted','non_dialable','hidden')),
  sms_fail_reason TEXT,
  sms_sent_at_ms INTEGER,
  template_ref TEXT,
  retry_count INTEGER NOT NULL DEFAULT 0 CHECK (retry_count BETWEEN 0 AND 1),
  notes TEXT NOT NULL DEFAULT '',
  created_at_ms INTEGER NOT NULL
);
CREATE UNIQUE INDEX uq_rejected_calls_event ON rejected_calls(event_id);
CREATE INDEX ix_rejected_calls_number_time ON rejected_calls(normalized_number, called_at_ms DESC);
CREATE INDEX ix_rejected_calls_time ON rejected_calls(called_at_ms DESC);
```

### 3.2 Trust lists — `trusted_entries`

Single table for whitelist + blacklist with `list` discriminator; mutual exclusion (SRS-702) enforced by UNIQUE on `normalized_number` (a number exists in at most one list — moving = UPDATE of `list`, never two rows).

| Column | Type | Required | Description | Mutability |
|---|---|---|---|---|
| `id` | INTEGER PK AI | Yes | Internal row handle | System-assigned, immutable |
| `normalized_number` | TEXT UNIQUE | Yes | Canonical key (SU-DOM-01-01) | Immutable (change = delete + insert) |
| `display_number` | TEXT | Yes | Display form | Set at create |
| `list` | TEXT | Yes | Enum: `whitelist` \| `blacklist` | User-controlled (move = update) |
| `display_name` | TEXT | Yes | Default `""` | User-editable |
| `notes` | TEXT | Yes | Default `""` | User-editable |
| `category` | TEXT | Yes | Free text in v1 (TQ-03 open: closed vocabulary must fit this column without migration) | User-editable |
| `source` | TEXT | Yes | Enum: `manual` \| `sms_classification` \| `call_history` | Set at create/move, immutable per row-version |
| `date_added_ms` | INTEGER | Yes | First insertion time, preserved across moves | Immutable |
| `last_modified_ms` | INTEGER | Yes | Last move/edit time | System-updated on every mutation |

```sql
CREATE TABLE trusted_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  normalized_number TEXT NOT NULL UNIQUE,
  display_number TEXT NOT NULL,
  list TEXT NOT NULL CHECK (list IN ('whitelist','blacklist')),
  display_name TEXT NOT NULL DEFAULT '',
  notes TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT '',
  source TEXT NOT NULL CHECK (source IN ('manual','sms_classification','call_history')),
  date_added_ms INTEGER NOT NULL,
  last_modified_ms INTEGER NOT NULL
);
CREATE INDEX ix_trusted_entries_list_modified ON trusted_entries(list, last_modified_ms DESC);
```

Snapshot rule (binding): on every commit to this table (`insert`/`update`/`delete`), `LocalStoreAdapter` rebuilds the in-memory decision snapshot (`blacklistSet`, `whitelistSet`) synchronously in the same transaction scope before returning (SRS-307). The screening path reads only the snapshot, never this table directly.

### 3.3 SMS triage state — `sms_triage`

Foreground-read SMS metadata linked to history numbers (SRS-601). Body text is stored (it is user data the user explicitly asked to see — CG-OVW-001 §2.1) in app-private storage only; bodies never enter logs (§10.8). Rows are derived (recomputable by re-query); `pending` clears on classification.

| Column | Type | Required | Description | Mutability |
|---|---|---|---|---|
| `id` | INTEGER PK AI | Yes | Internal handle | System-assigned |
| `provider_msg_id` | TEXT UNIQUE | Yes | Android SMS provider `_id` + `thread_id` composite string (dedup key) | Immutable |
| `normalized_number` | TEXT | Yes | Sender, canonicalised | Immutable |
| `body` | TEXT | Yes | Message body (app-private) | Immutable |
| `received_at_ms` | INTEGER | Yes | Provider `date` column | Immutable |
| `linked_event_id` | TEXT NULL | No | FK → `rejected_calls.event_id` when sender matches history; null = `unlinked` | System-updated on re-link |
| `triage_state` | TEXT | Yes | Enum: `pending` \| `classified` \| `unlinked` | System-updated on classify |
| `classified_to` | TEXT NULL | No | `whitelist` \| `blacklist` when `classified` | Set on classify |

```sql
CREATE TABLE sms_triage (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  provider_msg_id TEXT NOT NULL UNIQUE,
  normalized_number TEXT NOT NULL,
  body TEXT NOT NULL,
  received_at_ms INTEGER NOT NULL,
  linked_event_id TEXT,
  triage_state TEXT NOT NULL CHECK (triage_state IN ('pending','classified','unlinked')),
  classified_to TEXT CHECK (classified_to IN ('whitelist','blacklist'))
);
CREATE INDEX ix_sms_triage_state_time ON sms_triage(triage_state, received_at_ms DESC);
```

### 3.4 Scalar settings — app-private prefs

Stored in `DataStore` (Proto or Preferences) or `SharedPreferences` file `call_guard_prefs` (`MODE_PRIVATE`), keys:

| Key | Type | Default | Description |
|---|---|---|---|
| `cg_sms_template_text` | String | `"La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione."` (SRS-101, §4.1) | Auto-reply body (SRS-102/503) |
| `cg_blacklist_sms_enabled` | Boolean | `false` (SRS-103) | Send SMS to blacklist numbers (SRS-502) |

First-launch seed is transactional: if `cg_sms_template_text` absent → write default before any send path can read (TP-101). No other settings exist in v1; adding one requires a §11 row and a migration note.

### 3.5 What is NOT stored

Contact contents are never copied (presence boolean only, in-memory snapshot). Full SMS bodies never appear in `rejected_calls` (only `template_ref` hash). No network credentials, no tokens, no analytics IDs. Schema JSON (`schemas/call_guard.db.v1.json`, Room `exportSchema`) is the authoritative migration baseline; v1→v2 requires an explicit `Migration` object with a test (TP-1201/TP-705).

---

## 4. Configuration Specification

No external config files, no `model.map`, no schema registry. Configuration surface is exactly the two prefs keys in §3.4 plus build constants. This section normatively defines the SMS-template value rules.

### 4.1 SMS template value specification

```json
{
  "key": "cg_sms_template_text",
  "type": "string",
  "required": true,
  "default": "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione.",
  "validation": {
    "non_empty_after_trim": true,
    "max_chars": 480,
    "segment_accounting": "GSM-7 vs UCS-2 per 3GPP 23.038; editor shows segment count; default must fit 1 GSM-7 segment (verified in build, TP-1102)",
    "forbidden": ["empty", "whitespace-only", "over-limit"]
  },
  "restore_default": true
}
```

Validation algorithm (in `AutoReplyTemplate`, §8.6): `1. trim(text); 2. if empty → VALIDATION_EMPTY_TEMPLATE; 3. if length > 480 → VALIDATION_TEMPLATE_TOO_LONG; 4. compute encoding = GSM-7-encodable ? GSM-7 : UCS-2; segments = ceil(chars / (encoding==GSM-7 ? 160 : 70)) with concatenated limits (153/67) for multi-segment display; 5. accept and persist`. Rejected saves keep the prior value (SRS-503, UC-08 unhappy path).

### 4.2 Blacklist-SMS flag value specification

```json
{
  "key": "cg_blacklist_sms_enabled",
  "type": "boolean",
  "required": true,
  "default": false,
  "validation": { "allowed": [true, false] }
}
```

---

## 5. Identity context (platform)

There is no multi-tenant identity, no login, no edge/mesh headers, no `sub`/`domain`/`scopes`/`client_id`. The authoritative "identity context" for all application logic is the **Android device grant state**, read exclusively through platform APIs at the adapter boundary and passed inward as a plain value object. The service trusts what the platform reports per SRS and never accepts role/permission claims from the Flutter layer or from any caller-controlled field.

```kotlin
data class ProtectionContext(
  val osApiLevel: Int,              // Build.VERSION.SDK_INT
  val isOsSupported: Boolean,       // osApiLevel >= 29 (SRS-1005)
  val hasScreeningRole: Boolean,    // RoleManager.isRoleHeld(ROLE_CALL_SCREENING) (SRS-202)
  val permContacts: Boolean,        // READ_CONTACTS granted (SRS-203)
  val permPhoneState: Boolean,      // READ_PHONE_STATE granted
  val permSendSms: Boolean,         // SEND_SMS granted (SRS-203)
  val permReadSms: Boolean          // READ_SMS or RECEIVE_SMS granted, minimal scope per AD-03 (SRS-203/601)
)
```

Rules: (1) `ProtectionContext` is constructed only in `SU-INF-01-01` / `SU-APP-08-01` from live platform queries, refreshed on every app resume and on every `onScreenCall`; (2) screening requires `isOsSupported && hasScreeningRole` — otherwise fail-open pass-through (SRS-1004); (3) contacts lookup requires `permContacts`, SMS send requires `permSendSms`, triage read requires `permReadSms` — each denied bit degrades its feature with an explicit message, never with a silent assumption (SRS-203); (4) no PII is part of the context; (5) any future account/sync would invalidate this section and requires a scope Change Request (CG-OVW-001 §2.2 mandatory principle).

---

## 6. Platform-Channel Contract (HTTP N/A)

**HTTP status: N/A.** `call-guard` exposes no HTTP server, no REST routes, no `/health`, no `/metrics`, no auth scopes. This section documents the sole bridge — the versioned Flutter `MethodChannel` — which replaces the template's §6. Wire-level strings, argument codecs, and error shapes here are normative; TP-201 asserts no screening logic exists on the Dart side.

### 6.1 Channel identity and codec rules

- Channel name: `"call_guard/bridge_v1"`. All method names carry the `cg/v1/` prefix (table §6.2). A future breaking change requires `bridge_v2` — no silent method overloading.
- Codec: Flutter standard `MethodCodec` (binary). Numbers on the wire are **always** the canonical `normalized_number` string (validated by SU-DOM-01-01); raw `display_number` is an additional display-only field, never a lookup key.
- Timestamps on the wire: UTC ISO 8601 strings (§2.3). Enums on the wire: exact lowercase strings from §6.3; unknown values → Dart `unknown` fallback → `INTERNAL_ERROR` surfacing.
- Synchronous immediacy: `classifyNumber` and `manageList` return only after the Room transaction + snapshot rebuild commit (SRS-307). No optimistic UI that precedes the commit.
- PII on the wire stays in method arguments/results (needed for display); it MUST NOT be logged on either side (§10.8).

### 6.2 Method routing table

| Method | Direction | Args | Result | SRS | Description |
|---|---|---|---|---|---|
| `cg/v1/getProtectionStatus` | Flutter → native | `{}` | `ProtectionStatus{osSupported, hasRole, contacts, phoneState, sendSms, readSms, protectionActive}` | SRS-202/203/1005 | Protection-state for onboarding banner (SU-APP-08-01) |
| `cg/v1/requestScreeningRole` | Flutter → native | `{}` | `{requested: bool}` then re-query via `getProtectionStatus` | SRS-202 | Opens system role request |
| `cg/v1/getBlockedHistory` | Flutter → native | `{numberFilter?: string, limit: int, offset: int}` | `{rows: BlockedRow[], total: int}` newest-first | SRS-401/403/801 | Paged history (SU-APP-02-01 via store) |
| `cg/v1/getSmsTriage` | Flutter → native | `{}` | `{items: TriageItem[]}` pending-first, recency-ordered | SRS-601 | Triage set (SU-APP-04-01) |
| `cg/v1/classifyNumber` | Flutter → native | `{normalizedNumber: string, verdict: "whitelist"\|"blacklist", displayName?: string, notes?: string, category?: string}` | `{membership: "whitelist"\|"blacklist", effect: string}` | SRS-603/604/704/307 | Synchronous commit; clears pending |
| `cg/v1/manageList` | Flutter → native | `{op: "add"\|"remove"\|"move"\|"edit", list: "whitelist"\|"blacklist", entry: TrustedEntryWire}` | `{membership: "whitelist"\|"blacklist"\|"none", effect: string}` | SRS-701/702/705 | CRUD/move with exclusion |
| `cg/v1/getNumberProfile` | Flutter → native | `{normalizedNumber: string}` | `{entry: TrustedEntryWire\|null, historyRefs: BlockedRow[]}` | SRS-802 | Profile detail |
| `cg/v1/getSmsTemplate` | Flutter → native | `{}` | `{text: string, segments: int, encoding: "GSM-7"\|"UCS-2"}` | SRS-101 | Read persisted template |
| `cg/v1/setSmsTemplate` | Flutter → native | `{text: string}` | `{text: string, segments: int}` or channel error | SRS-503 | Validated write; rejects empty/over-limit |
| `cg/v1/restoreSmsTemplateDefault` | Flutter → native | `{}` | `{text: string}` (the §4.1 default) | SRS-503 | Restore default |
| `cg/v1/getBlacklistSmsFlag` | Flutter → native | `{}` | `{enabled: bool}` | SRS-103 | Read flag |
| `cg/v1/setBlacklistSmsFlag` | Flutter → native | `{enabled: bool}` | `{enabled: bool}` | SRS-103/502 | Write flag |
| `cg/v1/retrySms` | Flutter → native | `{eventId: string}` | `{smsStatus: "sent"\|"failed", retryCount: 0\|1}` or channel error | SRS-902 | Single manual retry; refused if `sent` or `retry_count==1` |
| `cg/v1/updateNotes` | Flutter → native | `{eventId: string, notes: string}` | `{eventId: string}` | SRS-401 | Annotate history row |

Channel error envelope (all failures): `{code: SCREAMING_SNAKE_CASE from §7, message: static user string, action: "open_settings"\|"grant_role"\|"retry"\|"edit"\|"none"}`. No stack traces, no PII beyond the already-displayed list context (SRS-901).

### 6.3 Shared wire types (normative)

```
BlockedRow = { eventId: string(UUIDv4), normalizedNumber: string, displayNumber: string,
  calledAt: string(ISO8601), outcome: "rejected", decisionOrigin: "unknown"|"blacklist",
  actuation: "disconnect"|"silence_fallback"|"none_role_missing",
  smsStatus: "pending"|"sent"|"failed"|"skipped", smsReason: string|null,
  retryCount: 0|1, notes: string }
TriageItem = { providerMsgId: string, normalizedNumber: string, receivedAt: string(ISO8601),
  body: string, linkedEventId: string|null, state: "pending"|"classified"|"unlinked" }
TrustedEntryWire = { normalizedNumber: string, displayNumber: string, list: "whitelist"|"blacklist",
  displayName: string, notes: string, category: string,
  source: "manual"|"sms_classification"|"call_history",
  dateAdded: string(ISO8601), lastModified: string(ISO8601) }
ProtectionStatus = { osSupported: bool, hasRole: bool, contacts: bool, phoneState: bool,
  sendSms: bool, readSms: bool, protectionActive: bool /* osSupported && hasRole */ }
```

---

## 7. Error Code Registry

Authoritative source for test assertions (CG-TP-001) and UI strings. Codes are `SCREAMING_SNAKE_CASE`. Each row binds one static user message (Italian, matching TP expectations) and one corrective action. No HTTP status exists (N/A column retained only to record the deviation explicitly). No PII in messages; no stack traces on any surface (SRS-901).

| Error Code | HTTP Status | User Message (static) | Corrective Action | Triggering Condition |
|---|---|---|---|---|
| `ROLE_MISSING` | N/A (no HTTP) | "Protezione non attiva — tocca per assegnare il ruolo" | Open system role request (`requestScreeningRole`) | `hasScreeningRole == false` at resume or screening (SRS-202) |
| `OS_UNSUPPORTED` | N/A | "Dispositivo non compatibile — richiesta Android 10+" | None (protection stays off) | `osApiLevel < 29` (SRS-1005) |
| `PERMISSION_DENIED_CONTACTS` | N/A | "Accesso rubrica mancante — il confronto contatti è disattivato" | Open app settings | Contacts lookup attempted without `READ_CONTACTS` (SRS-203) |
| `PERMISSION_DENIED_SMS_SEND` | N/A | "SMS non inviato — permesso mancante" (ledger + inline) | Open app settings; one manual retry after grant | Send attempted without `SEND_SMS` (SRS-203/402) |
| `PERMISSION_DENIED_SMS_READ` | N/A | "Accesso SMS mancante" (triage view) | Open app settings | Triage read without SMS-read grant (UC-06 unhappy path) |
| `SCREENING_TIMEOUT` | N/A | (No user blame; diagnostic counter only + protection hint if recurrent) | None per-event | Decision not returned within platform timeout — fail-open, event not recorded as app-rejected (UC-02 unhappy path) |
| `SMS_SEND_FAILED_RADIO` | N/A | "SMS non inviato" + retry affordance on the row | One manual retry (`retrySms`) | `SmsManager` `RESULT_ERROR_NO_SERVICE` / `NULL_PDU` / generic radio error (SRS-402/902) |
| `SMS_SKIPPED_BLACKLIST_POLICY` | N/A | "Rifiutata da blacklist, SMS disabilitato" (ledger, not a failure) | Toggle in settings if desired | Blacklist rejection with `cg_blacklist_sms_enabled == false` (SRS-502) |
| `SMS_SKIPPED_NON_DIALABLE` | N/A | "SMS non applicabile" (ledger) | None | Hidden/empty/short-code/alpha/non-dialable target (SRS-304/305) |
| `SMS_DUPLICATE_SUPPRESSED` | N/A | (Silent ledger marker, no UI error) | None | Second screening event on same `event_id` — no second send (SRS-501) |
| `RETRY_REFUSED_ALREADY_SENT` | N/A | "SMS già inviato" | None | `retrySms` on record with `sms_status == sent` |
| `RETRY_REFUSED_EXHAUSTED` | N/A | "Retry già utilizzato" | None | `retrySms` with `retry_count == 1` (SRS-902) |
| `VALIDATION_EMPTY_TEMPLATE` | N/A | Field error: "Il testo non può essere vuoto" | Edit; prior value kept | `setSmsTemplate` with blank text (SRS-503) |
| `VALIDATION_TEMPLATE_TOO_LONG` | N/A | Field error: "Testo troppo lungo (max 480 caratteri)" | Edit; prior value kept | `setSmsTemplate` over limit (SRS-503) |
| `VALIDATION_INVALID_NUMBER` | N/A | Field error: "Numero non valido" | Edit | `manageList`/`classifyNumber` with non-normalisable number (SRS-701) |
| `STORE_UNWRITABLE` | N/A | "Salvataggio non riuscito — riprova" | Retry save | Room/prefs write failure incl. disk-full (UC-03 unhappy path) |
| `INTERNAL_ERROR` | N/A | "Si è verificato un errore — riprova" | Retry / reopen | Unhandled exception; logged scrubbed with correlation ID only |

Adding a code requires a registry row + a TP case + a surfacing string — no ad-hoc strings in UI code.

---

## 8. Domain Layer — Software Unit Design

Canonical home: Kotlin `pure` module `:domain` (ARCH AD-01 resolved here — **opinion with criterion**: single-source-of-truth; placing policy in Kotlin keeps the time-critical screening path allocation-light and avoids channel-duplication drift; Dart MUST NOT duplicate). Zero Android/Flutter imports. Clock injected via `IClock`. All value objects immutable (`val` + `copy()`).

### 8.1 SI-DOM-01 — Number Identity & Screening Policy

#### SU-DOM-01-01 — PhoneNumber

**Purpose:** Canonicalises caller identity and decides visibility/dialability — the single gate every SMS and lookup decision depends on.

**IEC 62304 Class:** A — failure yields wrong pass/reject or wrong SMS skip; worst case is a missed call or unwanted SMS cost (operational), no health injury possible.

**Responsibilities:**
- Normalise E.164/national display variants to one canonical `normalized_number`.
- Discriminate visible vs hidden/empty (`presentation` from `Call.Details`).
- Judge SMS-dialability: reject short codes, alphanumeric sender IDs, non-dialable strings.

**Input:** `RawCallerId { raw: String?, presentation: Presentation }` where `Presentation ∈ {ALLOWED, RESTRICTED, UNKNOWN, PAYPHONE}` (Android `Call.Details` presentation constants).

```kotlin
data class RawCallerId(val raw: String?, val presentation: Presentation)
data class PhoneNumber(val normalized: String, val display: String, val dialableForSms: Boolean)
```

**Output:** `PhoneNumberResult = Visible(PhoneNumber) | Hidden | Empty`.

**Algorithm:**
1. If `presentation == RESTRICTED || presentation == UNKNOWN` → return `Hidden` (SRS-304; never SMS — enforced downstream).
2. Let `s = raw?.trim() ?: ""`. If `s.isEmpty()` → return `Empty` (SRS-304).
3. Strip visual separators: remove `[ spaces, '-', '.', '(', ')', '/' ]`. Keep leading `+`.
4. If `s` matches `^[A-Za-z][A-Za-z0-9]*$` (alpha sender, e.g. `BANCA`) → return `Visible(PhoneNumber(normalized=s, display=raw, dialableForSms=false))` (SRS-305).
5. If `s` matches `^[0-9]{3,6}$` with no `+` and no area structure (short code heuristic: length ≤ 6 AND not a valid national subscriber prefix per national plan table pinned in code) → `dialableForSms=false` (SRS-305). Exact short-code list is not enumerated — the length+plan rule is the normative test (TP-305 fixture `40400` must classify non-dialable).
6. Else if `s` matches `^\+?[0-9]{6,15}$` → `dialableForSms=true`, `normalized = s` with `+`-preserved canonical form (leading `00` → `+`; national trunk `0` preserved as-received but lookup uses both forms — see step 8).
7. Else → return `Visible(PhoneNumber(normalized=s, display=raw, dialableForSms=false))` (non-dialable catch-all; never throws — invalid numbers degrade to no-SMS, rejected-save only at list-entry time via `VALIDATION_INVALID_NUMBER`).
8. Contacts/lookup equivalence (used by callers, stated here for determinism): two strings are the same number iff their digit sequences after stripping non-digits are equal OR equal after stripping one leading national trunk `0` OR equal after stripping country prefix `+39`/`0039` (configurable per device locale in v1: Italy-first table; other country prefixes pass through as distinct — documented limitation, no silent merge).

**Error conditions:** none thrown — this SU never throws; unparseable input yields `dialableForSms=false` or `Empty`/`Hidden`. Rationale: screening path must be total (no exceptions on the decision path).

**Constraints:** No regex backtracking risk (linear patterns only); no I/O; no locale-dependent `toLowerCase` on numbers.

**SRS Trace:** SRS-302, SRS-304, SRS-305.

#### SU-DOM-02-01 — ScreeningDecision

**Purpose:** Pure precedence function: blacklist → contacts/whitelist-pass → unknown-reject; anonymous-pass.

**IEC 62304 Class:** A — false positive/negative (RSK-101) worst case is a lost urgent call handled as operational risk, not clinical injury.

**Input:** `ScreeningFacts { visibility: PhoneNumberResult, inContacts: Boolean, inWhitelist: Boolean, inBlacklist: Boolean, roleHeld: Boolean }`.

**Output:** `ScreeningVerdict { action: PASS | REJECT, origin: CONTACTS | WHITELIST | BLACKLIST | UNKNOWN | ANONYMOUS | NO_ROLE, actuation: RING | DISCONNECT | SILENCE_FALLBACK }`.

**Algorithm:**
1. If `roleHeld == false` → return `PASS/RING/NO_ROLE` (fail-open; SRS-302 "if and only if … role is held"; SRS-1004).
2. If `visibility is Hidden || visibility is Empty` → return `PASS/RING/ANONYMOUS` (SRS-304; AMB-02).
3. If `inBlacklist == true` → return `REJECT/DISCONNECT/BLACKLIST` (SRS-306; prevails even over contacts/whitelist — SRS-703, AMB-04).
4. If `inContacts == true || inWhitelist == true` → return `PASS/RING/CONTACTS|WHITELIST` (SRS-302/303; RF-5).
5. Else → return `REJECT/DISCONNECT/UNKNOWN` (SRS-302 core rule).
6. `SILENCE_FALLBACK` is never chosen here — it is an Infrastructure actuation fallback recorded in §10.1 step 4 (AD-05); the domain verdict is `DISCONNECT` and the adapter downgrades + records if the platform rejects disconnect.

**Constraints:** Total function (all 32 input combos defined; steps ordered — order is normative, TP-703 asserts 6 representative combos); no I/O; no SMS knowledge (eligibility is SU-DOM-02-02's job).

**SRS Trace:** SRS-302, SRS-303, SRS-304, SRS-306, SRS-703.

#### SU-DOM-02-02 — SmsEligibility

**Purpose:** Pure eligibility gate for the auto-reply: exactly when an SMS may be attempted.

**IEC 62304 Class:** A — failure causes unwanted cost or missing SMS (economic/nuisance harm only).

**Input:** `SmsFacts { visibility: PhoneNumberResult, dialable: Boolean, decisionOrigin: DecisionOrigin, blacklistSmsEnabled: Boolean }`.

**Output:** `Eligible | Skipped(reason: BLACKLISTED | NON_DIALABLE | HIDDEN)`.

**Algorithm:**
1. If `visibility is Hidden || visibility is Empty` → `Skipped(HIDDEN)` (SRS-304).
2. If `dialable == false` → `Skipped(NON_DIALABLE)` (SRS-305: short codes, alpha IDs, non-dialable).
3. If `decisionOrigin == BLACKLIST && blacklistSmsEnabled == false` → `Skipped(BLACKLISTED)` (SRS-502; AMB-01, default OFF).
4. Else → `Eligible` (SRS-501 path).

**Constraints:** Must be evaluated before every `SmsManager` call without exception; adding a new skip reason requires a registry row (§7) + ledger enum extension (§3.1) + TP case.

**SRS Trace:** SRS-103, SRS-304, SRS-305, SRS-501, SRS-502.

### 8.2 SI-DOM-02 — Records & Trust Model

#### SU-DOM-03-01 — CallRecord

**Purpose:** Rejected-call entity: one-row-per-call invariant with SMS ledger state machine.

**IEC 62304 Class:** A — failure loses trace (RSK-106); recoverability harm, no injury.

**State:** fields per §3.1 row. `sms_status` machine: `pending → sent | failed | skipped`; `failed → sent | failed` (exactly once via manual retry, `retry_count` 0→1); `sent` and `skipped` are terminal (no transitions). `retry_count` monotonic, max 1 (CHECK).

**Algorithm (`create`):**
1. Require `verdict.action == REJECT` (else refuse — contacts-pass never creates rows, SRS-303).
2. Assign `event_id = UUIDv4`, `called_at_ms = clock.nowUtcMillis()`, `sms_status = pending`, `retry_count = 0`, `notes = ""`.
3. Return immutable record; persistence is the Application layer's job (§9.2).

**Algorithm (`applySmsResult`):** `1. if status terminal (sent/skipped) → refuse (RETRY_REFUSED_*); 2. on success → sent + sent_at + template_ref; 3. on failure → failed + fail_reason (no PII); 4. on skip → skipped + skip_reason.`

**Constraints:** No aggregation (two calls = two records even same number/minute — TP-401); body text never stored here (only `template_ref` hash).

**SRS Trace:** SRS-401, SRS-402.

#### SU-DOM-03-02 — TrustedEntry

**Purpose:** Whitelist/blacklist entry with mutual-exclusion invariant and move semantics.

**IEC 62304 Class:** A — contradictory screening bounded to ring/reject behaviour.

**State:** fields per §3.2 row. Invariant: `UNIQUE(normalized_number)` across both lists (SRS-702).

**Algorithm (`addToList`):**
1. Normalise input via SU-DOM-01-01; if un-normalisable → `DomainError(VALIDATION_INVALID_NUMBER)`.
2. If number absent → insert with `source`, `date_added_ms = now`, `last_modified_ms = now`.
3. If present in the *other* list → require explicit caller confirmation flag (`confirmedMove == true`, set by UI confirm dialog per RSK-108); if confirmed → UPDATE `list`, `source`, `last_modified_ms`, preserve `date_added_ms`; record move (TP-702).
4. If present in the *same* list → treat as `edit` (update name/notes/category), never duplicate.

**Algorithm (`remove`):** delete row; history rows untouched (removal never deletes history — ARCH §9.2). Number returns to default handling (unknown → reject+SMS flow).

**Constraints:** `category` is free text in v1 (TQ-03); a future closed vocabulary must validate here without schema change. `display_number` never used as key.

**SRS Trace:** SRS-603, SRS-604, SRS-701, SRS-702, SRS-802.

#### SU-DOM-04-01 — AutoReplyTemplate

**Purpose:** Default constant, validation, and segment accounting for the auto-reply text.

**IEC 62304 Class:** A — empty/oversize SMS is cost/UX harm only.

**Constant (SRS-101, normative — character-exact):**
`"La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione."`

**Algorithm (`validate`):** per §4.1 steps 1–5. `GSM-7-encodable` per 3GPP 23.038 basic + extension table (pinned table in code; test asserts the default is 1 GSM-7 segment — TP-101/TP-1102). Limits: `max_chars = 480` (accepts concatenated SMS while bounding cost).

**Error conditions:** blank → `VALIDATION_EMPTY_TEMPLATE`; over-limit → `VALIDATION_TEMPLATE_TOO_LONG`. Rejected saves keep prior value (no partial write).

**Constraints:** No I/O; default constant duplicated nowhere else (single `DEFAULT_TEMPLATE` const; prefs seed + restore-default + tests all reference it).

**SRS Trace:** SRS-101, SRS-503.

---

## 9. Application Layer — Software Unit Design

Orchestration against ports. No direct `android.*`/`Room` imports. Ports (each implemented by exactly one §10 adapter):

```
IClock, IDecisionSnapshotProvider, IRejectedCallRepository, ITrustedEntryRepository,
ISmsSender, IContactsLookup, ISmsInboxReader, ITemplateStore, IBlacklistSmsFlagStore,
IProtectionStateProvider, IDiagnostics
```

Screening-path rule (binding): `ScreenIncomingCallUseCase` performs **no network, no Room write, no SMS send before returning the decision** — persistence and SMS are scheduled off-path (SRS-301/1001, RSK-102).

### 9.1 SI-APP-01 — Screening & Messaging Use Cases

#### SU-APP-01-01 — ScreenIncomingCallUseCase

**Purpose:** Time-critical orchestrator: snapshot lookup → pure decision → immediate return; schedules record + SMS off-path.

**IEC 62304 Class:** A — timeout/fail-open, no health injury.

**Port Dependencies:** `IProtectionStateProvider`, `IDecisionSnapshotProvider`, `IDiagnostics`.

**Algorithm:**
1. Capture `t0 = clock.nowUtcMillis()`; read `ProtectionContext` (cached ≤ 5 s, else re-query — never block on re-query beyond 100 ms; on timeout use last-known + fail-open).
2. Build `RawCallerId` from `Call.Details` (number + presentation). Evaluate SU-DOM-01-01 → `visibility`.
3. Read in-memory snapshot only: `inBlacklist = snapshot.blacklist.contains(normalized)`, `inWhitelist likewise`, `inContacts = snapshot.contactsPresence(normalized)` (snapshot rebuilt on every list write/boot — §3.2 rule; no provider query here).
4. Evaluate SU-DOM-02-01 with `roleHeld = ctx.hasScreeningRole && ctx.isOsSupported` → `verdict`.
5. Return `verdict.action/actuation` to `CallScreeningAdapter` immediately (target < 500 ms p99 internal; platform timeout is authoritative — TP-301).
6. Off-path (after return, best-effort, never blocking a second call): if `verdict.action == REJECT` → enqueue `{screening_event_id, verdict, visibility}` to `RecordRejectedCallUseCase` (exactly one enqueue per OS callback; duplicate OS callbacks with same telecom `callId` collapse to one `event_id` — TP-501).
7. Unhappy paths: role missing → PASS + `ROLE_MISSING` diagnostic counter (no record, UC-02 unhappy path); timeout before step 5 → PASS + `SCREENING_TIMEOUT` counter, event NOT recorded as app-rejected; exception anywhere in steps 1–4 → PASS (fail-open) + `INTERNAL_ERROR` scrubbed log (SRS-1004).
8. Emit scrubbed diagnostic: `{screening_event_id, verdict_origin, elapsed_ms}` — no number (RSK-103).

**SRS Trace:** SRS-201, SRS-301, SRS-302, SRS-303, SRS-306, SRS-703, SRS-1001, SRS-1004.

#### SU-APP-02-01 — RecordRejectedCallUseCase

**Purpose:** Creates one `CallRecord` per rejection, transactionally.

**IEC 62304 Class:** A.

**Ports:** `IRejectedCallRepository` (transactional `insert`), `IDiagnostics`.

**Algorithm:**
1. Receive `{verdict==REJECT, visibility==Visible, called_at_ms}`. If verdict is PASS → refuse silently (contacts/anonymous never logged — SRS-303/304).
2. Construct via SU-DOM-03-01.create (UUIDv4 `event_id`).
3. `insert` in one Room transaction. On `STORE_UNWRITABLE` → schedule one retry on next app open + surface `STORE_UNWRITABLE` (UC-03 unhappy path); never drop silently.
4. Forward `event_id` to `SendAutoReplyUseCase` (step does not await send).
5. Return `event_id`.

**SRS Trace:** SRS-401, SRS-402.

#### SU-APP-03-01 — SendAutoReplyUseCase

**Purpose:** Exactly-once send per `event_id`; maps result to ledger; at most one manual retry.

**IEC 62304 Class:** A.

**Ports:** `IRejectedCallRepository`, `ISmsSender`, `ITemplateStore`, `IBlacklistSmsFlagStore`, `IDiagnostics`.

**Algorithm (automatic attempt):**
1. Load record by `event_id`; if `sms_status != pending` → mark `SMS_DUPLICATE_SUPPRESSED`, stop (idempotency — SRS-501, TP-501).
2. Evaluate SU-DOM-02-02 with persisted `blacklistSmsEnabled` flag. If `Skipped(reason)` → set ledger `skipped + reason`, stop (no sender call — SRS-502/304/305).
3. If `permSendSms == false` → set ledger `failed/no_permission`, stop (SRS-203; retry allowed after grant).
4. Load persisted template text (never the default constant directly — SRS-102). Compose payload `{destination = normalized_number, body = template}`.
5. Call `ISmsSender.send(event_id, destination, body)` (single attempt, no auto-retry — SRS-902). Map result: success → `sent + sent_at + template_ref=sha16(body)`; `NO_SERVICE/NULL_PDU/radio` → `failed + reason`.
6. Persist ledger update in the same transaction as `retry_count` check. Never attempt a second automatic send for this `event_id`.

**Algorithm (manual retry, `retrySms(event_id)`):**
1. Load record; if `sms_status == sent` → `RETRY_REFUSED_ALREADY_SENT`; if `retry_count >= 1` → `RETRY_REFUSED_EXHAUSTED`; if `skipped` → refuse (skips are policy, not failures — user must change policy first).
2. Else `retry_count++`, re-run steps 2–6 once. No further retries (SRS-902, TP-902). No background polling: zero sends without user tap.

**SRS Trace:** SRS-103, SRS-501, SRS-502, SRS-902.

#### SU-APP-04-01 — TriageInboundSmsUseCase

**Purpose:** On app foreground: fetches inbound SMS, links to history, computes pending set.

**IEC 62304 Class:** A.

**Ports:** `ISmsInboxReader`, `IRejectedCallRepository`, `IDiagnostics`.

**Algorithm:**
1. If `permReadSms == false` → return `{state: SMS_ACCESS_MISSING}` with `PERMISSION_DENIED_SMS_READ` guidance; read nothing (UC-06 unhappy path).
2. Query provider inbox (foreground only, `date >= lastTriageWatermark`, capped at 200 rows newest-first — no full-backup read).
3. For each message: normalise sender via SU-DOM-01-01 (un-normalisable → mark `unlinked`, no CTA); look up `rejected_calls` by `normalized_number` + `trusted_entries` membership.
4. Classify row: sender in history AND in neither list → `pending` (with `linked_event_id` = newest matching rejection); sender in a list → `classified` (excluded from queue, SRS-601); sender never rejected → `unlinked` (shown without destructive CTAs).
5. Upsert `sms_triage` rows (dedup by `provider_msg_id`); update watermark; return pending-first recency-ordered set for the dedicated view (SRS-601/602).

**SRS Trace:** SRS-601.

### 9.2 SI-APP-02 — Classification & Configuration Use Cases

#### SU-APP-05-01 — ClassifyNumberUseCase

**Purpose:** Accept→whitelist / Reject→blacklist from triage or history; synchronous commit for SRS-307 immediacy.

**IEC 62304 Class:** A.

**Ports:** `ITrustedEntryRepository` (transactional), `IDecisionSnapshotProvider` (rebuild), `IDiagnostics`.

**Algorithm:**
1. Input `{normalizedNumber, verdict, displayName?, notes?, category?, confirmedMove}`. Normalise + validate (→ `VALIDATION_INVALID_NUMBER` on failure).
2. In one Room transaction: apply SU-DOM-03-02.addToList (move semantics, `source = sms_classification | call_history`); clear `sms_triage.triage_state → classified` + `classified_to` for all pending rows of this number; rebuild snapshot before commit returns.
3. Return `{membership, effect}` where `effect = "Da ora questo numero squillerà normalmente" | "Da ora sarà sempre rifiutato"` (UC-07 main flow; RF-10).
4. Unhappy paths: number in other list without `confirmedMove` → return `NEEDS_CONFIRM` (UI shows move-confirm, TP-702); store unwritable → `STORE_UNWRITABLE`, no partial state (SRS-1004).

**SRS Trace:** SRS-307, SRS-603, SRS-604, SRS-704.

#### SU-APP-06-01 — ManageListsUseCase

**Purpose:** Add/remove/move/edit lists + profiles with SRS-702 exclusion.

**IEC 62304 Class:** A.

**Ports:** `ITrustedEntryRepository`, `IDecisionSnapshotProvider`.

**Algorithm:** Same transactional core as SU-APP-05-01 with `source = manual`, plus: `remove` (delete row, history untouched); `edit` (update name/notes/category only — number immutable, SRS-802); every mutation rebuilds snapshot synchronously and returns an effect statement. Validation identical (invalid → `VALIDATION_INVALID_NUMBER`, no partial row — UC-07 unhappy path).

**SRS Trace:** SRS-307, SRS-701, SRS-702.

#### SU-APP-07-01 — ConfigureSmsTemplateUseCase

**Purpose:** Edit/validate/persist template; restore-default; segment count.

**IEC 62304 Class:** A.

**Ports:** `ITemplateStore`.

**Algorithm:**
1. `get`: return `{text = persisted, segments, encoding}`.
2. `set(text)`: SU-DOM-04-01.validate → on error return field error, keep prior (SRS-503); on success persist, return new `{text, segments}`; next auto-reply uses new text (SRS-102).
3. `restoreDefault`: persist `DEFAULT_TEMPLATE` const, return it (UC-08 unhappy path recovery).

**SRS Trace:** SRS-101, SRS-102, SRS-503.

#### SU-APP-08-01 — ProtectionStatusUseCase

**Purpose:** Evaluates role + permission + OS-version state; drives blocking UI + deep-links.

**IEC 62304 Class:** A.

**Ports:** `IProtectionStateProvider`.

**Algorithm:**
1. Query `osApiLevel`, `isRoleHeld`, each permission (live, no cache older than resume).
2. Compute `protectionActive = isOsSupported && hasScreeningRole`; `degraded = active but any SMS/contacts bit denied`.
3. Return `ProtectionStatus` (§6.3) + ordered issue list: `OS_UNSUPPORTED` first, then `ROLE_MISSING`, then per-permission denials — each with its deep-link action (SRS-202/203/1005, UC-01).
4. Never claim protection when inactive (SRS-202; TP-202 asserts banner wording).

**SRS Trace:** SRS-202, SRS-203, SRS-901, SRS-1004, SRS-1005.

---

## 10. Infrastructure Layer — Software Unit Design

All I/O. Adapters implement exactly one Application port; adapters never embed decision policy (policy lives in §8 — violation fails review).

### 10.1 SI-INF-01 — Native Platform Adapters

#### SU-INF-01-01 — CallScreeningAdapter

**Purpose:** `CallScreeningService.onScreenCall` host; timeout-safe entry/exit; snapshot read; disconnect/silence actuation; PII-free diagnostics.

**IEC 62304 Class:** A. **SOUP:** SOUP-01 (Android SDK API 29–35, `CallScreeningService`), SOUP-02 (Kotlin stdlib/coroutines — no blocking on path).

**Design:**
- `class CallGuardScreeningService : CallScreeningService()`; `onScreenCall(details)` delegates to SU-APP-01-01 steps 1–5 on the calling thread (no `Dispatchers.IO`, no `runBlocking`, no Room, no `SmsManager` before `respondToCall`).
- Response mapping: `REJECT → CallResponse.Builder().setDisallowCall(true).setSkipCallLog(false).setSkipNotification(true)`; `PASS → setDisallowCall(false)`. Disconnect vs silence fallback (AD-05 resolved here deterministically): attempt `setDisallowCall(true)` + `disconnect=true` path where API supports; if `TelecomManager.endCall()`-equivalent unavailable on the OEM (caught `SecurityException`/no-op), fall back to silence (`setSilenceCall(true)`) and record `actuation = silence_fallback` in the ledger (TP-1202). The branch taken is always recorded — no silent downgrade.
- Manifest: `ROLE_CALL_SCREENING` intent filter, `minSdk 29`; battery-optimisation exemption guidance in onboarding (RSK-102).
- Diagnostics via SU-INF-08-01 only (hash/prefix, never number).

**SRS Trace:** SRS-201, SRS-301, SRS-307, SRS-1001.

#### SU-INF-02-01 — ContactsLookupAdapter

**Purpose:** Read-only contacts presence check; snapshot builder; denied-permission path.

**IEC 62304 Class:** A. **SOUP:** SOUP-01 (`ContactsContract.PhoneLookup`).

**Design:** Implements `IContactsLookup` + snapshot contribution. Query: `PhoneLookup.CONTENT_FILTER_URI` with encoded number, projection `[ _ID ]`, limit 1 (presence boolean only — no name/photo fetch). Snapshot build at boot + on `CONTACTS_CHANGED` broadcast (debounced 30 s): builds `BloomSet + exact HashSet` of normalised contacts for O(1) path lookups (TP-301 with 10k contacts). Denied (`permContacts == false`) → snapshot reports `false` for all + `PERMISSION_DENIED_CONTACTS` guidance; screening treats as unknown-handling (SRS-203), never crashes.

**SRS Trace:** SRS-203, SRS-302, SRS-303.

#### SU-INF-03-01 — SmsSenderAdapter

**Purpose:** `SmsManager` send + delivery-result mapping; dialability guard enforcement; idempotency-key carrier.

**IEC 62304 Class:** A. **SOUP:** SOUP-01 (`SmsManager`, sent/delivery `PendingIntent`s).

**Design:** Implements `ISmsSender.send(event_id, destination, body)`. Pre-send re-checks SU-DOM-02-02 (defence in depth — adapter refuses even if use case erred). Send: `sendTextMessage` for ≤1 segment else `sendMultipartTextMessage`; registers one-shot sent-intent receiver keyed by `event_id`; maps `RESULT_OK → sent`, `RESULT_ERROR_NO_SERVICE → failed/no_service`, `RESULT_ERROR_NULL_PDU → failed/null_pdu`, others → `failed/radio_error`. No retry here (retry lives in SU-APP-03-01). Payload (destination+body) never logged (RSK-103).

**SRS Trace:** SRS-203, SRS-305, SRS-501.

#### SU-INF-04-01 — SmsInboxReaderAdapter

**Purpose:** Foreground SMS-provider query scoped to history numbers; denied-permission path; never a background listener in v1.

**IEC 62304 Class:** A. **SOUP:** SOUP-01 (SMS provider `Telephony.Sms.Inbox`).

**Design:** Implements `ISmsInboxReader.querySince(watermark_ms, limit=200)`. Projection `[ _id, thread_id, address, date, body ]`, selection `date > ?`, order `date DESC`. Called only from `TriageInboundSmsUseCase` on foreground (AD-04 baseline — no manifest `RECEIVE_SMS` background receiver in v1; adding one is a scope + AD-03 decision, weighed against RSK-105). Returns raw rows; linking/scope-filtering happens in Application (§9.1), not here. Denied → empty + `PERMISSION_DENIED_SMS_READ`.

**SRS Trace:** SRS-203, SRS-601.

#### SU-INF-05-01 — LocalStoreAdapter

**Purpose:** Room DAOs + transactions + prefs + migrations; reboot/update durability.

**IEC 62304 Class:** A. **SOUP:** SOUP-03 (Room, DataStore/SharedPreferences — versions pinned in §11).

**Design:**
- `@Database(entities=[RejectedCallEntity, TrustedEntryEntity, SmsTriageEntity], version=1, exportSchema=true)`; DAOs: `RejectedCallDao (insert, updateSmsStatus, listNewestFirst, byNumber, byEventId)`, `TrustedListDao (upsert, move, delete, snapshotAll)`, `TriageDao (upsertAll, pendingOrdered, markClassified)`.
- Transactional annotations: `@Transaction` on `classifyCommit` (list write + triage clear + snapshot rebuild token) and `recordWithLedgerInit`.
- Prefs: `TemplateStoreDataStore` for §3.4 keys with first-launch seed transaction.
- Migrations: explicit `Migration(1,2)`-style objects required for any schema change; destructive fallback prohibited in release builds (`fallbackToDestructiveMigration()` test-only). Reboot/kill-during-write tests per TP-1201 (rollback, never half-row).
- No exported provider; `allowBackup=false`; DB file in app-private `databases/` (RSK-104).

**SRS Trace:** SRS-101, SRS-102, SRS-103, SRS-307, SRS-401, SRS-402, SRS-403, SRS-502, SRS-603, SRS-604, SRS-701, SRS-705, SRS-801, SRS-1002.

### 10.2 SI-INF-02 — Bridge, Presentation & Diagnostics

#### SU-INF-06-01 — PlatformChannelBridge

**Purpose:** Versioned MethodChannel contract carrier; synchronous classification writes; PII-safe error mapping.

**IEC 62304 Class:** A. **SOUP:** SOUP-04 (Flutter engine `MethodChannel` — version pinned in §11).

**Design:** `MethodChannel("call_guard/bridge_v1")` handler in Kotlin; one handler per §6.2 method, each: `1. parse args (type-checked, missing → INTERNAL_ERROR); 2. normalise numbers via SU-DOM-01-01 (never trust Dart form); 3. invoke the owning use case; 4. serialise result per §6.3; 5. map DomainError → channel error envelope (§6.1)`. `classifyNumber`/`manageList`/`retrySms`/`setSmsTemplate` await the Room commit before replying (SRS-307 immediacy is a bridge guarantee, asserted by TP-307). Channel arguments/results are never logged above `Log.DEBUG` and never with PII (§10.8 rule).

**SRS Trace:** channel carrier for SRS-307/603/604/902 flows; error mapping for SRS-901.

#### SU-INF-07-01 — FlutterPresentation

**Purpose:** Six surfaces + profile detail; filter/sort; confirm+undo on CTAs; error surfacing with corrective actions.

**IEC 62304 Class:** A. **SOUP:** SOUP-04 (Flutter SDK + Material widgets).

**Surfaces (routes normative):**
1. `/protection` — onboarding: `ProtectionStatus` banner, per-prerequisite rows, single role-request action, incompatibility message on API <29 (SRS-202/1005, UC-01; TP-202/TP-1005).
2. `/history` — blocked-call list newest-first, substring filter on number, row shows number/date/origin/SMS-ledger/notes-preview; tap → detail with notes edit + `retrySms` affordance (iff `failed` + `retry_count==0`) + promote-to-list actions (SRS-401/402/403/801/704/902; TP-401/402/704/801/902).
3. `/triage` — pending SMS view: number/datetime/body/linked record + exactly two CTAs `Accetta (whitelist)` / `Rifiuta (blacklist)` (labels character-exact, TP-602), confirm + immediate undo snackbar (RSK-108), badge count (SRS-601/602/603/604; TP-601/602/603/604/1103).
4. `/whitelist`, `/blacklist` — lists with substring filter + date-desc sort, add/remove/move/edit, effect statement on every commit (SRS-701/702/705/801).
5. `/settings/sms-text` — template editor with segment counter + encoding label, field errors, restore-default (SRS-503; TP-503).
6. `/settings/general` — blacklist-SMS toggle (default OFF) with explanation (SRS-103).
7. `/profile/:number` — detail: membership, linked history, name/notes/category edit (number immutable), dates + source (SRS-802; TP-802).
- Empty states explicit ("Nessuna chiamata bloccata"); error states per §7 with action buttons; no nested-menu CTAs (SRS-602); all filtering client-side over channel pages (no undeclared filter fields — TP-801).

**SRS Trace:** SRS-103, SRS-202, SRS-203, SRS-503, SRS-602, SRS-701, SRS-704, SRS-801, SRS-802, SRS-901, SRS-902, SRS-1004, SRS-1005.

#### SU-INF-08-01 — DiagnosticsLogger

**Purpose:** Structured diagnostics with mandatory PII scrub (hash/truncated-prefix only).

**IEC 62304 Class:** A.

**Design:**
- Single entry point `log(event: String, screeningEventId: UUID?, attrs: Map<String,String>)`. Scrub rules (binding, TP-1003 gate): allowlisted keys only (`verdict_origin`, `actuation`, `sms_status`, `reason`, `elapsed_ms`, `os_api`, `event_id`); any value matching `\+?[0-9]{6,}` or longer than 160 chars is replaced with `SHA-256(value).take(8)` or `<redacted>`; SMS bodies, contact names, raw numbers never pass. `PhoneNumber`, `body`, `displayName` are compile-time-forbidden parameter types here (overload resolution fails review).
- Sinks: `logcat` (tag `CallGuard`), in-memory ring buffer (200 entries, PII-free, attachable to bug reports). No file log with PII, no analytics, no crash SDK with identifiers (RSK-103/104; SRS-1002).
- Counters: `screened_ok / role_missing / timeout / sms_sent / sms_failed / sms_skipped_blacklist / sms_skipped_nondialable` — the operational dashboard for RSK-102/107 without identifiers.
- Build gate: log-inspection test (TP-1003) runs the full IT+E2E suite with canary numbers and fails on any cleartext match.

**SRS Trace:** SRS-901, SRS-1002, SRS-1003.

---

## 11. Configuration Parameters

No env vars, no server ports, no DAS endpoints. Parameters are app-private prefs keys + build constants. Adding a parameter requires a row here + validation in §8/§9 + a TP case.

| Parameter | Key / Constant | Type | Default | Validation | Description |
|---|---|---|---|---|---|
| SMS template text | `cg_sms_template_text` (prefs) | string | §4.1 default (SRS-101) | Non-empty after trim; ≤ 480 chars; else field error, prior kept | Body used by every auto-reply until changed (SRS-102/503) |
| Blacklist SMS enabled | `cg_blacklist_sms_enabled` (prefs) | boolean | `false` | Must be bool | Send auto-reply to blacklist numbers (SRS-103/502) |
| Min / target SDK | `minSdk 29`, `targetSdk` + `compileSdk` pinned at build (e.g. 34; exact recorded in release notes) | int | 29 / pinned | `minSdk == 29`; protection off below 29 | Android 10+ only (SRS-1005; C-01) |
| Kotlin / coroutines | `org.jetbrains.kotlin:kotlin-stdlib`, `kotlinx-coroutines-android` pinned (e.g. Kotlin 2.0.x) | version | pinned | Recorded in SBOM; no blocking on screening path | SOUP-02 runtime |
| Room / DataStore | `androidx.room:room-*`, `androidx.datastore:*` pinned | version | pinned | `exportSchema=true`; migration tests green | SOUP-03 persistence (SU-INF-05-01) |
| Flutter / Material | Flutter stable pinned (e.g. 3.2x.x) + `flutter_lints` | version | pinned | No `telecom` imports in Dart (TP-201) | SOUP-04 presentation |
| Gradle / AGP | Gradle + Android Gradle Plugin pinned | version | pinned | Reproducible build | SOUP-05 build only |
| Triage query cap | `TRIAGE_QUERY_LIMIT = 200` (code const) | int | 200 | 1–1000 | Foreground inbox page size (§9.1) |
| Snapshot re-query budget | `SNAPSHOT_QUERY_BUDGET_MS = 100` | int | 100 ms | > 0 | Max block for grant-state refresh on screening path before fail-open (§9.1) |

Template rows for `[SVC]_PORT`, `[SVC]_DAS_HOST/PORT`, `[SVC]_MONGO_URI`, file-upload limits: **N/A — no server, no DAS, no uploads.** Any future network/sync parameter requires a scope Change Request + privacy re-review (CG-OVW-001 §2.2).

---

## 12. SRS-to-SU Traceability Matrix

Every SRS maps to at least one SU; every SU traces to at least one SRS (IEC 62304 §5.4 bidirectional requirement). Test references point to CG-TP-001 cases that assert the §8–§10 detail.

| SRS ID | Requirement Summary | Implementing SU(s) | Test ref |
|---|---|---|---|
| SRS-101 | Default SMS pre-populated | SU-DOM-04-01 (constant), SU-APP-07-01 (seed), SU-INF-05-01 (persist) | TP-101, TP-1102 |
| SRS-102 | Template persisted, used until changed | SU-APP-07-01, SU-INF-05-01 | TP-102, TP-1201 |
| SRS-103 | Blacklist-SMS flag default OFF | SU-DOM-02-02 (rule), SU-APP-03-01 (enforce), SU-INF-05-01 (persist), SU-INF-07-01 (toggle) | TP-103, TP-502 |
| SRS-201 | Screening exclusively native Kotlin, Android 10+ | SU-INF-01-01 (host), SU-APP-01-01 (orchestrator) | TP-201 |
| SRS-202 | Blocking state when role missing | SU-APP-08-01 (evaluate), SU-INF-07-01 (banner), SU-INF-01-01 (fail-open) | TP-202, TP-1004 |
| SRS-203 | Minimal permissions with feature gates | SU-APP-08-01, SU-INF-02-01, SU-INF-03-01, SU-INF-04-01, SU-INF-07-01 | TP-203, TP-1203 |
| SRS-301 | Pre-ring interception within timeout | SU-APP-01-01 (snapshot-only path), SU-INF-01-01 (entry/exit) | TP-301, TP-1202 |
| SRS-302 | Reject iff visible + not contacts + not whitelist + role | SU-DOM-01-01 (visible), SU-DOM-02-01 (rule), SU-APP-01-01 (execute) | TP-302, TP-1101 |
| SRS-303 | Contacts pass, no log/SMS | SU-DOM-02-01, SU-INF-02-01, SU-APP-01-01 (no-record branch) | TP-303, TP-1101 |
| SRS-304 | Hidden/empty pass, never SMS | SU-DOM-01-01 (Hidden/Empty), SU-DOM-02-01 (pass), SU-DOM-02-02 (skip) | TP-304 |
| SRS-305 | Never SMS short-codes/alpha/non-dialable | SU-DOM-01-01 (dialable), SU-DOM-02-02 (skip), SU-INF-03-01 (guard) | TP-305 |
| SRS-306 | Blacklist always rejects incl. over contacts | SU-DOM-02-01 (precedence), SU-APP-01-01 | TP-306, TP-703 |
| SRS-307 | Decisions effective on next call, no restart | SU-APP-05-01, SU-APP-06-01, SU-INF-05-01 (sync commit), SU-INF-01-01 (snapshot read), SU-INF-06-01 (bridge guarantee) | TP-307, TP-603/604/704 |
| SRS-401 | One history record per rejection (5 fields) | SU-DOM-03-01 (entity), SU-APP-02-01 (create), SU-INF-05-01 (insert) | TP-401 |
| SRS-402 | SMS status + reason on record, template-ref only | SU-APP-02-01, SU-APP-03-01, SU-INF-05-01 | TP-402 |
| SRS-403 | History survives restart/update, newest-first | SU-INF-05-01 (Room durability), SU-INF-07-01 (ordering) | TP-403, TP-1201 |
| SRS-501 | Exactly one auto-SMS per rejection | SU-APP-03-01 (idempotency), SU-INF-03-01 (single attempt), SU-DOM-02-02 (gate) | TP-501, TP-1102 |
| SRS-502 | Skip SMS for blacklist when flag OFF | SU-DOM-02-02, SU-APP-03-01, SU-INF-05-01 (ledger) | TP-502 |
| SRS-503 | Template edit with non-empty + length validation | SU-DOM-04-01 (validate), SU-APP-07-01 (persist), SU-INF-07-01 (editor) | TP-503, TP-1102 |
| SRS-601 | Foreground SMS read + dedicated linked view | SU-APP-04-01 (link/pending), SU-INF-04-01 (query), SU-INF-07-01 (view) | TP-601, TP-1104 |
| SRS-602 | Exactly two CTAs per unclassified SMS | SU-INF-07-01 (labels + layout) | TP-602, TP-1103 |
| SRS-603 | Accept → whitelist + clear pending | SU-APP-05-01, SU-DOM-03-02 (move), SU-INF-05-01 (commit) | TP-603 |
| SRS-604 | Reject → blacklist + clear pending | SU-APP-05-01, SU-DOM-03-02 (move), SU-INF-05-01 (commit) | TP-604 |
| SRS-701 | List CRUD + profile (6 fields) | SU-DOM-03-02 (invariant), SU-APP-06-01 (ops), SU-INF-05-01 (store), SU-INF-07-01 (UI) | TP-701 |
| SRS-702 | Mutual exclusion whitelist/blacklist | SU-DOM-03-02 (UNIQUE + move), SU-APP-06-01 | TP-702 |
| SRS-703 | Precedence blacklist > pass > reject | SU-DOM-02-01 (order), SU-APP-01-01 | TP-703, TP-306 |
| SRS-704 | Promote directly from history (1 action) | SU-APP-05-01, SU-INF-07-01 | TP-704 |
| SRS-705 | Lists survive restart/update | SU-INF-05-01 | TP-705, TP-1201 |
| SRS-801 | Three lists with substring filter + date-desc sort | SU-INF-07-01 (filter/sort), SU-INF-05-01 (ordered queries) | TP-801 |
| SRS-802 | Profile detail with linked records + edit | SU-INF-07-01 (detail), SU-DOM-03-02 (editable fields) | TP-802 |
| SRS-901 | Failures with action; no PII/stack traces | SU-INF-07-01 (surfacing), SU-INF-08-01 (scrub), SU-APP-08-01 (state) | TP-901 |
| SRS-902 | At most one manual retry, never background auto-retry | SU-APP-03-01 (retry machine), SU-INF-07-01 (affordance) | TP-902 |
| SRS-1001 | Decision on-device only, no network | SU-APP-01-01 (no-network path), SU-INF-01-01 | TP-1001 |
| SRS-1002 | All data on-device, no transmitting backup/sync/analytics | SU-INF-05-01 (private store), SU-INF-08-01 (no PII sink) | TP-1002 |
| SRS-1003 | No PII in any log | SU-INF-08-01 (scrub + gate) | TP-1003, TP-901 |
| SRS-1004 | Graceful degradation, fail-open, no partial state | SU-APP-08-01 (detect), SU-APP-01-01 (fail-open), SU-INF-07-01 (notify) | TP-1004, TP-1202 |
| SRS-1005 | Android 10+ only, explicit incompatibility message | SU-APP-08-01 (check), SU-INF-07-01 (message) | TP-1005 |

Reverse check (every SU appears above): SU-DOM-01-01 (302/304/305); SU-DOM-02-01 (302/303/304/306/703); SU-DOM-02-02 (103/304/305/501/502); SU-DOM-03-01 (401/402); SU-DOM-03-02 (603/604/701/702/802); SU-DOM-04-01 (101/503); SU-APP-01-01 (201/301/302/303/306/703/1001/1004); SU-APP-02-01 (401/402); SU-APP-03-01 (103/501/502/902); SU-APP-04-01 (601); SU-APP-05-01 (307/603/604/704); SU-APP-06-01 (307/701/702); SU-APP-07-01 (101/102/503); SU-APP-08-01 (202/203/901/1004/1005); SU-INF-01-01 (201/301/307/1001); SU-INF-02-01 (203/302/303); SU-INF-03-01 (203/305/501); SU-INF-04-01 (203/601); SU-INF-05-01 (101/102/103/307/401/402/403/502/603/604/701/705/801/1002); SU-INF-06-01 (307/603/604/902 carrier); SU-INF-07-01 (103/202/203/503/602/701/704/801/802/901/902/1004/1005); SU-INF-08-01 (901/1002/1003). No orphan SU, no uncovered SRS.

RSK→mechanism index (for review convenience; authoritative analysis in CG-RSK-001): RSK-101 → §8.1 precedence + §9.1 fail-open + history 1-tap callback; RSK-102 → §9.1 snapshot-only path + §10.1 actuation fallback + §5 grant state; RSK-103 → §10.8 scrub + §7 static messages + TP-1003 gate; RSK-104 → §3 private store + `allowBackup=false` + no exported provider; RSK-105 → §5 minimal scopes + §10.1 degraded modes + AD-03 posture; RSK-106 → §3 UNIQUE/CHECK + §10.5 transactions + migration tests; RSK-107 → §9.1 idempotency + §4.1 segment accounting + default-OFF flag; RSK-108 → §10.7 confirm+undo + linked detail; RSK-109 → §9.1 foreground triage + notification/badge/deep-link.

Open items carried from ARCH §11 (not decided here): AD-03 SMS-read scope evidence (blocks permission UX sign-off), AD-05 OEM fallback verification matrix (branch defined in §10.1, device evidence pending), TQ-01 retention cap (SDS mandates keep-until-user-deletes; any cap needs SRS change), TQ-02 anonymous handling (fixed pass per SRS-304), TQ-03 category vocabulary (isolated free-text column, §3.2).

---

*End of Document — CG-SDS-001 v0.1.0*
*Next in package: CG-IPB-001 — Implementation Plan Backlog*
