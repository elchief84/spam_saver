# [Service Name] — Risk Analysis (ISO 14971)

**Document ID:** [SVC]-RSK-001
**Version:** 0.1.0
**Status:** Draft
<!-- Status options: Draft | Pending Review | Draft — Revised | Pending Approval | Approved | Superseded -->
**Service:** `[service-name]`
**Standard:** ISO 14971:2019
**Last Updated:** [YYYY-MM-DD]
**Trace Parents:** [SVC]-UC-001 · [SVC]-UN-001

---

## Document Control

| Role | Name | Date | Signature |
|---|---|---|---|
| Author | | | |
| Reviewer | | | |
| Approver (QA/RA) | | | |

### Change Log

| Version | Date | Author | Summary of Change |
|---|---|---|---|
| 0.1.0 | [YYYY-MM-DD] | | Initial draft |

---

## Evaluation Matrix

<!-- This matrix defines the risk acceptability regions used for all risk items in this document.
     Risk Score = Probability (1–6) × Severity (1–4).
     Do NOT modify this matrix without QA/RA approval — it must be consistent across all risk documents
     in the H.Core SaMD framework. -->

| **Probability \ Severity** | **Catastrophic (4)** | **Critical (3)** | **Marginal (2)** | **Negligible (1)** |
|---|---|---|---|---|
| **Frequent (6)** | [ALTO] 24 | [ALTO] 18 | [ALTO] 12 | [MEDIO] 6 |
| **Probable (5)** | [ALTO] 20 | [ALTO] 15 | [MEDIO] 10 | [MEDIO] 5 |
| **Occasional (4)** | [ALTO] 16 | [ALTO] 12 | [MEDIO] 8 | [BASSO] 4 |
| **Remote (3)** | [ALTO] 12 | [MEDIO] 9 | [MEDIO] 6 | [BASSO] 3 |
| **Unlikely (2)** | [MEDIO] 8 | [MEDIO] 6 | [BASSO] 4 | [BASSO] 2 |
| **Unbelievable (1)** | [BASSO] 4 | [BASSO] 3 | [BASSO] 2 | [BASSO] 1 |

**Severity Scale:**
| Level | Label | Description |
|---|---|---|
| 4 | Catastrophic | Risk of death or permanent disability |
| 3 | Critical | Risk of serious consequences that may involve hospitalisation or prolonged hospitalisation |
| 2 | Marginal | Risk of mild consequences that may involve minor care (bandages, minor medications, non-invasive diagnostic investigations) |
| 1 | Negligible | Discomfort to the patient or consequences that do not involve the need for medical and/or nursing care |

**Probability Scale:**
| Level | Label | Description |
|---|---|---|
| 6 | Frequent | Could happen immediately or within a short period |
| 5 | Probable | Likely to happen; could happen several times in 1 or 2 years |
| 4 | Occasional | Is likely to happen; could happen a few times over a period of 2 to 5 years |
| 3 | Remote | Not expected to happen; could happen in a period between 5 and 30 years |
| 2 | Unlikely | It would arouse amazement that the problem would occur |
| 1 | Unbelievable | It would arouse great amazement that the problem would occur |

**Risk Score = Probability × Severity**

**Acceptability:**
| Colour | Region | Score Range | Action Required |
|---|---|---|---|
| [ALTO] Red | Intolerable | ≥ 12 | Risk reduction measures mandatory before release |
| [MEDIO] Yellow | Conditionally Tolerable | 5 – 11 | ALARP review required; benefit–risk comparison; accepted with justification |
| [BASSO] Green | Broadly Tolerable | ≤ 4 | Residual risk acceptable; no further action required |

> **ALARP note:** Conditionally Tolerable risks that cannot be further reduced must be compared against clinical benefit. If benefit exceeds risk, the risk is accepted as tolerable. If risk exceeds benefit, it escalates to Intolerable.
> Residual risk must NOT remain [ALTO] Intolerable. If it does, additional mitigations are required before this document can be approved.

---

<!--
AUTHORING INSTRUCTIONS FOR RISK ITEMS

Each risk item follows this exact structure:

## RSK-[NNN]

**Category:** [Risk category — see vocabulary below]
**Hazard:** [One-sentence description of the hazardous energy or condition — not the harm, not the situation]
**Source of Hazard:** [Root cause: what specific system behaviour, design decision, or external factor could initiate the hazard sequence]
**Hazardous Situation:** [How the hazard reaches the patient or user — the intermediate scenario]
**Potential Harm:** [The final harm to the patient/user if the hazardous situation is not interrupted]

Risk Category vocabulary:
- Patient Safety — Content Integrity
- Patient Safety — Premature [Data/Content] Exposure
- Data Security — Cross-Tenant Data Leakage
- Data Security — Malicious File Upload
- Data Security — Information Disclosure
- Data Integrity — Audit Trail Gap
- Data Integrity — Record Corruption
- Availability — Service Unavailability
- Privacy — PII Exposure in Logs
- Privacy — Unauthorised Data Access

**Initial Risk Evaluation:**
Severity: **[N] — [Label]** · Probability: **[N] — [Label]** · Score: **[P×S]** → [ALTO]/[MEDIO]/[BASSO] **[Intolerable/Conditionally Tolerable/Broadly Tolerable]**

**Risk Reduction Measures:**
- [Measure 1 — reference to UC, SRS, UN, or organisational control that mitigates this risk]
- [Measure 2]
- [Measure 3 — if a measure is outside software scope (e.g., organisational SOP), state explicitly]
- Future: [Any risk reduction measures deferred to a future phase]

**Residual Risk Status (Post Mitigation):**
Severity: **[N] — [Label]** · Probability: **[N] — [Label]** · Score: **[P×S]** → [ALTO]/[MEDIO]/[BASSO] **[Intolerable/Conditionally Tolerable/Broadly Tolerable]**

**Benefit–Risk Justification (required if residual risk is [MEDIO] Conditionally Tolerable):**
[Describe the clinical or operational benefit that justifies accepting the residual risk at ALARP level]

**Traceability:** UN-[NNN], UN-[NNN] · UC-[NN], UC-[NN]
-->

---

## RSK-101

**Category:** Patient Safety — [Category]
**Hazard:** [One-sentence description of the hazardous condition]
**Source of Hazard:** [Root cause — specific system behaviour or design decision that could initiate this]
**Hazardous Situation:** [How the hazard reaches the patient — the intermediate scenario]
**Potential Harm:** [Final patient harm if the situation is not interrupted]

**Initial Risk Evaluation:**
Severity: **[N] — [Label]** · Probability: **[N] — [Label]** · Score: **[P×S]** → [ALTO] **Intolerable**

**Risk Reduction Measures:**
- [Measure 1 — reference to UC / SRS / UN / architectural control that mitigates this risk]
- [Measure 2]
- Organisational: [Any SOP or process control outside software scope — state explicitly]
- Future: [Any deferred mitigation — state what it is and why it is deferred]

**Residual Risk Status (Post Mitigation):**
Severity: **[N] — [Label]** · Probability: **[N] — [Label]** · Score: **[P×S]** → [MEDIO] **Conditionally Tolerable**

**Benefit–Risk Justification:**
[Describe the clinical or operational benefit that justifies accepting this residual risk at ALARP level]

**Traceability:** UN-[NNN] · UC-[NN]

---

## RSK-102

**Category:** Data Security — Cross-Tenant Data Leakage
**Hazard:** A consumer accesses data belonging to a different tenant
**Source of Hazard:** Tenant context accepted from caller-supplied request parameters rather than derived exclusively from the validated session token
**Hazardous Situation:** An operator or platform service from Tenant A reads or modifies data belonging to Tenant B
**Potential Harm:** Confidential health data exposed to unauthorised parties; GDPR breach; regulatory sanction

**Initial Risk Evaluation:**
Severity: **4 — Catastrophic** · Probability: **3 — Remote** · Score: **12** → [ALTO] **Intolerable**

**Risk Reduction Measures:**
- Domain/tenant is derived **exclusively** from the **platform-injected identity context** (edge) — never accepted as a caller-supplied parameter
- All data access queries include domain as a mandatory, non-overridable filter applied inside the service layer
- Cross-domain access returns the same not-found response as a missing record (prevents tenant enumeration)
- Integration tests must explicitly assert that cross-tenant queries return empty results

**Residual Risk Status (Post Mitigation):**
Severity: **4 — Catastrophic** · Probability: **1 — Unbelievable** · Score: **4** → [BASSO] **Broadly Tolerable**

**Traceability:** UN-[NNN] · UC-[NN]

---

## RSK-103

**Category:** Privacy — PII Exposure in Logs
**Hazard:** Personally identifiable information (PII) is written to general operational log streams
**Source of Hazard:** Insufficient log sanitisation — structured log entries include user identifiers, health data fields, or patient content without pseudonymisation
**Hazardous Situation:** PII is accessible to any system or operator with access to the logging infrastructure
**Potential Harm:** GDPR breach; regulatory sanction; loss of patient trust

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **4 — Occasional** · Score: **12** → [ALTO] **Intolerable**

**Risk Reduction Measures:**
- Pseudonymisation / anonymisation of all PII fields before log emission — enforced by **platform logging pipeline**
- Log schema specification ([SVC]-KPI-001) defines which fields are permitted in log output
- PII routing confirmed absent — automated test assertions check that no PII fields appear in log test output
- GDPR Data Protection Impact Assessment (DPIA) to review logging architecture prior to production release

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **1 — Unbelievable** · Score: **3** → [BASSO] **Broadly Tolerable**

**Traceability:** UN-[NNN] · UC-[NN]

---

## RSK-104

**Category:** Data Integrity — Audit Trail Gap
**Hazard:** Version snapshots or audit entries fail silently, producing gaps in the immutable audit history
**Source of Hazard:** [Describe the specific design decision or failure mode — e.g., best-effort non-blocking snapshot writes]
**Hazardous Situation:** During a regulatory inspection, the audit history for a specific record is incomplete
**Potential Harm:** Inability to demonstrate GxP compliance; regulatory finding; potential product suspension

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **2 — Unlikely** · Score: **6** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- [Measure 1 — e.g., monotonically incrementing version counter enables gap detection]
- Snapshot write failure emits a CRITICAL log entry for immediate alerting
- Monitoring alert configured on CRITICAL log entries from the versioning subsystem
- Future: transactional writes to make snapshot and primary write atomic

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **1 — Unbelievable** · Score: **3** → [BASSO] **Broadly Tolerable**

**Traceability:** UN-[NNN] · UC-[NN]

---

<!-- Add additional RSK items as needed. Number sequentially from RSK-101.
     Minimum recommended coverage:
     - Patient safety risks (content/data accuracy, premature exposure)
     - Cross-tenant data leakage
     - Malicious file upload (if file upload is in scope)
     - PII in logs
     - Audit trail gaps
     - Service unavailability impact
     - Schema/configuration validation failure (if config-driven schema is in scope)
-->

---

## Risk Summary Table

| RSK ID | Category | Hazard | Potential Harm | Initial Region | Mitigations | Residual Region |
|---|---|---|---|---|---|---|
| RSK-101 | [Category] | [One-sentence hazard description] | [Final patient harm if situation is not interrupted] | [ALTO] Intolerable | [Measure 1]; [Measure 2] | [MEDIO] Conditionally Tolerable |
| RSK-102 | Data Security — Cross-Tenant Data Leakage | A consumer accesses data belonging to a different tenant | Confidential health data exposed to unauthorised parties; GDPR breach; regulatory sanction | [ALTO] Intolerable | Tenant derived exclusively from session token; mandatory domain filter on all queries; cross-domain requests return not-found; integration test assertions | [BASSO] Broadly Tolerable |
| RSK-103 | Privacy — PII Exposure in Logs | PII written to general operational log streams | GDPR breach; regulatory sanction; loss of patient trust | [ALTO] Intolerable | PII pseudonymisation enforced by **platform logging pipeline**; permitted-field log schema; automated PII-absence test assertions; DPIA prior to release | [BASSO] Broadly Tolerable |
| RSK-104 | Data Integrity — Audit Trail Gap | Version snapshots or audit entries fail silently | Inability to demonstrate GxP compliance; regulatory finding; potential product suspension | [MEDIO] Conditionally Tolerable | Gap-detectable version counter; CRITICAL log on snapshot failure; monitoring alert on CRITICAL entries; future: atomic transactional writes | [BASSO] Broadly Tolerable |

---

*End of Document — [SVC]-RSK-001 v0.1.0*
*Next in package: [SVC]-SRS-001 — Software Requirements Specifications*
