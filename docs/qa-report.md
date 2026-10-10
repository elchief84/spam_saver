# Call Guard — QA Report

**Document ID:** CG-QAR-001
**Version:** 0.1.0
**Status:** Draft
**Service:** `call-guard`
**Date:** 2026-10-11

**Trace Parents:**
- CG-SRS-001 — Software Requirements Specifications (v0.1.0)
- CG-TP-001 — Test Plan (v0.1.0)
- CG-RSK-001 — Risk Analysis (v0.1.0)
- CG-ARCH-001 — Software Architecture (v0.1.0)
- CG-SDS-001 — Software Design Specification (v0.1.0)

---

## Document Control

| Role | Name | Date | Signature |
|---|---|---|---|
| Author | Rosario (QA) | 2026-10-11 | Rosario |
| Reviewer | — | — | — |

### Change Log

| Version | Date | Author | Summary of Change |
|---|---|---|---|
| 0.1.0 | 2026-10-11 | Rosario (QA) | Initial draft — verifica statica eseguita sui documenti; nessuna build disponibile, verifica dinamica non eseguibile |

---

## 1. Purpose

This document records the additional quality verification performed for the
`call-guard` where the QA role is assigned to the project. It complements the
default checks — green CI and technical-architect review — it does not replace them.

Scope and phase: **pre-implementation (document phase)**. No source code, no APK,
no CI pipeline exist in the workspace at the time of writing (workspace contains
only `docs/` + `README.md`; `git status` shows no tracked implementation). All
checks below are therefore **static, reproducible document/artifact verification**
executed locally, plus an explicit declaration of which Test Plan cases could NOT
be executed and why. Nothing is approved "a occhio": every Pass is backed by a
command/output, every Fail has repro steps.

---

## 2. Verification Scope

| Area | In Scope | Notes |
|---|---|---|
| Functional behaviour | Yes | Static: decision rules SRS-302/306/703, precedence, one-record-per-call, exactly-once SMS — verified against SRS/SDS/TP text; dynamic (device) NOT executable, no build |
| Edge cases and error paths | Yes | Static: hidden/empty caller ID, short codes, blacklist-over-contacts, role/permission denied, SMS failure/retry — trace verified; dynamic NOT executable |
| Regression risk | No | No baseline build exists; nothing to regress. Persistence/migration gates (TP-1201/TP-705) flagged as release-blocking when a build lands |
| Non-functional (performance, resilience) | Yes (partial) | Static: timeout/offline/PII-in-logs/off-device rules verified in spec; on-device timing, traffic capture, OEM matrix NOT executable without build |

---

## 3. Additional Verification Performed

Each row was executed on 2026-10-11 against the workspace files. Commands are
reproducible from the repo root.

| ID | Description | SRS Trace | TP Trace | Result |
|---|---|---|---|---|
| QA-V-001 | Default SMS text is character-exact and identical in OVW/SRS/SDS/TP/UN/UC. Checked with `grep -rn 'automaticamente rifiutata' docs/` — all 7 occurrences match the brief text. | SRS-101 | TP-101 | [OK] Pass |
| QA-V-002 | Default SMS length/segment claim. `python3` length check on the exact default string → **183 chars**. TP-101/TP-1102, SDS §4.1/§8.6, RSK-107 claim "1 GSM-7 segment / verified in build". 183 > 160 → **2 segments**. Claim is false; test as written would FAIL on a correct implementation. | SRS-101, SRS-503 | TP-101, TP-1102 | [FAIL] Fail → QF-001 |
| QA-V-003 | GSM-7 encodability of the default text. Non-ASCII chars found: `è`, `é` — both in the GSM 03.38 basic alphabet, so encoding is GSM-7 (no UCS-2 fallback). Only the segment count is wrong, not the encoding. | SRS-503 | TP-1102 | [OK] Pass |
| QA-V-004 | SRS inventory count vs "38 requisiti" claims. `grep -c '^### SRS-'` → **37** items (SRS-101…1005). ARCH §1.2 and TP §1/§5 claim 38. Off-by-one documentation error. | — (doc consistency) | TP §1, §5; ARCH §1.2 | [FAIL] Fail → QF-003 |
| QA-V-005 | Dangling trace check. SRS AMB-01 cites "SRS-502, SRS-710" but no `### SRS-710` exists (`grep` over SRS doc: SRS-710 appears only in that prose line). Dangling reference. | SRS-103, SRS-502 | — | [FAIL] Fail → QF-002 |
| QA-V-006 | Requirements coverage: every SRS-101…1005 appears in TP §5 matrix. Checked by script (all 37 real SRS IDs present in matrix; only phantom SRS-710 missing, which does not exist). | All SRS | TP §5 | [OK] Pass |
| QA-V-007 | Falsifiability spot-check (a test that cannot fail proves nothing): TP-302 (10-combo matrix, rejects exactly 1 combo), TP-305 (5 inputs, exactly 1 dialable), TP-501 (duplicate screening → exactly 1 send), TP-1003 (single canary in clear = red gate). Each has a distinct failing observable. | SRS-302, SRS-305, SRS-501, SRS-1003 | TP-302, TP-305, TP-501, TP-1003 | [OK] Pass |
| QA-V-008 | Edge-case rule completeness in spec: hidden/empty → pass + never SMS (SRS-304); short-code/alpha/non-dialable → never SMS (SRS-305); blacklist prevails over contacts (SRS-306/703); role missing → fail-open + blocking banner (SRS-202/1004); permission denied → per-feature gate (SRS-203); one manual retry only, no background auto-retry (SRS-902). All six rules present in SRS + SDS algorithms + TP cases. | SRS-304, SRS-305, SRS-306, SRS-202, SRS-203, SRS-902, SRS-703 | TP-304, TP-305, TP-306, TP-202, TP-203, TP-902, TP-703 | [OK] Pass |
| QA-V-009 | Privacy-by-spec check: on-device-only (SRS-1002), no PII in logs (SRS-1003), scrubbed diagnostics + build-failing log-inspection test (TP-1003), no exported provider / `allowBackup=false` (ARCH §8, SDS §3). Chain SRS→ARCH→SDS→TP is unbroken. Dynamic proof (logcat grep, traffic capture) NOT executable without build. | SRS-1002, SRS-1003, SRS-901 | TP-1002, TP-1003, TP-901 | [OK] Pass (static only; dynamic blocked → QF-004) |
| QA-V-010 | Immediacy + idempotency chain: SRS-307 (next-call effect) ↔ SDS snapshot-rebuild rule ↔ TP-307/603/604/704; SRS-501 (exactly-once, key = event ID) ↔ SDS `SMS_DUPLICATE_SUPPRESSED` ↔ TP-501/1102. Present and mutually consistent. Dynamic proof NOT executable. | SRS-307, SRS-501, SRS-502 | TP-307, TP-501, TP-502, TP-1102 | [OK] Pass (static only; dynamic blocked → QF-004) |
| QA-V-011 | Dynamic executability gate: attempted to locate any executable artifact (APK, `app/`, `*.kt`, `*.dart`, CI workflow asserting tests). Result: none — `ls` shows only `README.md` + `docs/`; no implementation, no CI. All E2E/PERF/SEC device cases (TP-301, TP-1101, TP-1202, TP-1001, TP-202…) are therefore NOT EXECUTED. | RF-1…RF-10 | TP-301, TP-1101, TP-1201, TP-1202, TP-1203 | [FAIL] Fail (blocked, missing artifact) → QF-004 |
| QA-V-012 | Open-decision hygiene: ARCH §11 leaves AD-03 (SMS-read scope), AD-05 (disconnect vs silence fallback) and TQ-01…TQ-03 open, and SRS AMB-05 (dual-SIM/carrier) is Open. TP correctly gates AD-05/AMB-05 behind device-matrix tests (TP-1202) instead of silently assuming. No silent invention in SDS (TQ-02 default fixed to SRS-304). | SRS-201, SRS-301 | TP-1202, TP-1203 | [OK] Pass (process correct; residual risk stays open → QF-005) |

---

## 4. Findings

| ID | Severity | Description | Reproducible | Defect Ref | Status |
|---|---|---|---|---|---|
| QF-001 | MEDIO | **Default SMS does not fit 1 GSM-7 segment — spec claims it does.** Repro: `python3 -c "text='<default>'; print(len(text))"` → `183`. 183 GSM-7 chars = 2 segments (concatenated limit 153/segment). Expected per TP-101/TP-1102, SDS §4.1/§8.6, RSK-107 mitigation, ARCH §9.5: "default entro 1 segmento / verified in build". Observed: 2 segments, so the mitigation "default entro 1 segmento" is factually false and TP-101/TP-1102 as written would go red on a correct implementation. Cost/operator impact (RSK-107): every auto-reply costs 2 segments, not 1. Fix options (PM decision): (a) shorten the default to ≤ 160 GSM-7 chars, or (b) correct all five documents to "2 segments" and re-quantify RSK-107 cost + the 480-char editor limit. | Yes | — (doc defect, pre-code) | Open |
| QF-002 | BASSO | **Dangling trace SRS-710.** Repro: open `docs/software-requirements-specifications.md` AMB-01 row → "vedi SRS-502, SRS-710"; `grep -n 'SRS-710' docs/software-requirements-specifications.md` shows only that prose line, no `### SRS-710` section exists. Expected: every SRS reference resolves to a requirement. Observed: SRS-710 unresolvable. Fix: change reference to the real toggle requirement (SRS-103/SRS-502). | Yes | — (doc defect) | Open |
| QF-003 | BASSO | **Wrong SRS count ("38").** Repro: `grep -c '^### SRS-' docs/software-requirements-specifications.md` → `37`; ARCH §1.2 ("all 38 approved SRS items") and TP §1 ("tutti i 38 requisiti") claim 38. Expected: 37. Observed: 38. Fix: correct the two claims to 37 (or add the missing requirement if one was dropped — QA suspects a plain miscount: 3+3+7+3+3+4+5+2+2+5 = 37). Stile, non comportamento; segnalato per igiene di release. | Yes | — (doc defect) | Open |
| QF-004 | ALTO | **No executable artifact — the entire dynamic Test Plan is unverified.** Repro: `ls` (only `README.md`, `docs/`), `git status --short` (no tracked code), search for `*.kt`/`*.dart`/APK/CI workflow → nothing. Expected per TP gates: TP-301/TP-1202 (timeout/role/OEM), TP-1003 (zero PII in logcat), TP-1201 (reboot/migration), TP-1203 (Play declaration), TP-1101 (false-positive 10/10) green before approval. Observed: 0/44 TP cases executed; observable behaviour (pre-ring reject, SMS send, triage CTAs, persistence) verified by nobody. This is not a code defect — it is a missing-verification blocker. No release approval until at least the five gate cases are green on the device matrix. | Yes | — (missing verification) | Open |
| QF-005 | MEDIO | **Residual risks/design decisions still open at QA time (correctly tracked, but must gate release).** AMB-05 (dual-SIM/carrier refusal reliability) Open in SRS; AD-03 (SMS-read scope vs Consent/Retriever API) and AD-05 (disconnect vs silence fallback per OEM) Open in ARCH §11; RSK-101/105/109 accepted in ALARP (MEDIO residual). Expected: closed or device-verified before release. Observed: open with owners/targets, TP-1202/TP-1203 correctly defined as gates but not yet run (see QF-004). No doc fix needed now; QA requires these gates green (or explicit ALARP sign-off with KPI monitoring) before approval. | Yes | — (process gate) | Open |

No taste/style blocks were raised. Truncation, label wording ("Accetta/Rifiuta"), and category vocabulary (TQ-03) are left to UX review, not QA verdict.

---

## 5. Coverage of Additional Checks

| Metric | Value |
|---|---|
| Additional checks planned | 12 (QA-V-001…QA-V-012) |
| Additional checks executed | 12 (all static; dynamic blocked per QF-004) |
| Passed | 9 (of which 3 static-only: QA-V-009, QA-V-010 dynamic part blocked, QA-V-012 gate open) |
| Failed | 3 (QA-V-002, QA-V-004, QA-V-005 → QF-001/003/002) + 1 blocked (QA-V-011 → QF-004) |

TP execution state (for the record, not counted above): 0/44 TP cases executed — no build exists. The five release gates (TP-301/TP-1202, TP-1003, TP-1201, TP-1203, TP-1101) are all red-by-absence.

---

## 6. Verdict

| Criterion | Result |
|---|---|
| All additional checks passed | [FAIL] — QA-V-002 (QF-001 MEDIO), QA-V-004/QA-V-005 (QF-003/QF-002 BASSO), QA-V-011 (QF-004 ALTO/blocked) |
| No open findings above BASSO | [FAIL] — QF-004 ALTO + QF-001/QF-005 MEDIO open |

**Overall Verdict:** [FAIL] **FAIL** — static specification quality is good (precedence, idempotency, privacy chain, falsifiable tests all verified), but (1) there is no executable artifact so no observable behaviour has been verified — the five TP release gates must go green on the Pixel+OEM/API 29–35 matrix before any approval; (2) QF-001 (2-segment default sold as 1-segment) must be fixed by shortening the default or correcting RSK-107/SDS/TP and re-quantifying SMS cost; (3) QF-002/QF-003 doc references must be corrected; (4) AD-03/AD-05/AMB-05 must be closed with device evidence or explicit ALARP sign-off. Re-submit to QA after the doc fixes + a testable build with gate results attached.

---

*End of Document — CG-QAR-001 v0.1.0*
