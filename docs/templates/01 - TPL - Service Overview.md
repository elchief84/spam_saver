# [Service Name] — Service Overview

**Document ID:** [SVC]-OVW-001
**Version:** 0.1.0
**Date:** [YYYY-MM-DD]
**Status:** Draft
<!-- Status options: Draft | Pending Review | Draft — Revised | Pending Approval | Approved | Superseded -->

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

## Table of Contents

1. [General Project Context](#1-general-project-context)
2. [Clinical Significance & Regulatory Qualification](#2-clinical-significance--regulatory-qualification)
3. [Actors & Stakeholders](#3-actors--stakeholders)
4. [Scope Definition](#4-scope-definition)
5. [Design Guidelines](#5-design-guidelines)
6. [Assumptions](#6-assumptions)
7. [Constraints](#7-constraints)
8. [Open Decisions & Residual Questions](#8-open-decisions--residual-questions)

---

## 1. General Project Context

<!-- Describe what this service does and what H.Core products/therapeutic areas consume it.
     Include:
     - One-paragraph functional summary of the service's responsibility
     - Which H.Core products are consumers (e.g., Amicomed, Recover+)
-->

[Service name] is a [description of responsibility] component of the H.Core SaMD platform. It is consumed by [list of products].

---

## 2. Clinical Significance & Regulatory Qualification

### 2.1 Nature of [Data / Content / Function] Managed

<!-- Describe precisely what data or clinical function this service handles. Be explicit about:
     - Whether this is patient-specific or population-level data/content
     - Whether the service generates, transforms, or infers any clinical information
     - Representative examples of what is managed -->

[Describe the nature of data/function. Examples: informational content, patient measurements, clinical decision support outputs, etc.]

### 2.2 Patient Safety Obligation

<!-- Every service in a SaMD environment carries a patient safety obligation — even infrastructure services.
     Describe:
     - What harm could occur if this service fails or behaves incorrectly
     - The non-negotiable technical controls implemented to address that risk
     - Reference to the ISO 14971 risk analysis ([SVC]-RSK-001) -->

Despite its classification as [describe service type], [service name] carries a patient safety obligation. [Describe the failure mode and potential harm pathway.]

The following non-negotiable technical controls address this obligation:

| Control | Implementation |
|---|---|
| [Control name] | [How it is enforced technically] |
| | |

> **Mandatory principle:** [State the immutable design constraint — e.g., "This service does not generate or infer clinical information. Any feature request that would introduce inferential logic must be escalated for regulatory review."]

### 2.3 Regulatory Qualification

<!-- State the regulatory status of this service:
     - Is it a standalone medical device software item, or a platform infrastructure component?
     - Does it fall under IEC 62304 Class A, B, or C? Justify.
     - Reference to applicable regulatory pathways (EU MDR, FDA 21 CFR 820/QMSR) -->

[Service name] is a [platform infrastructure component / standalone MDSW item]. For H.Core products classified as MDSW, this service is a constituent software item subject to the full IEC 62304 traceability chain.

**IEC 62304 Safety Class:** [A / B / C] — Justification: [state justification based on severity of harm if software fails]

---

## 3. Actors & Stakeholders

<!-- Define all actors (human and system) who interact with this service. For each, describe:
     - Their role and what they do with/through this service
     - Their access scope / permissions
     - Key interactions (what operations they perform)
     Use one sub-section per actor. -->

### 3.1 [Actor Name — e.g., Operators / Editors]

**Description:** [Who they are and their responsibility]

**Access Scope:** [e.g., read/write, specific OAuth 2.0 scopes]

**Key interactions:**
- [Interaction 1]
- [Interaction 2]

---

### 3.2 [Actor Name — e.g., Patients via Patient-Facing App]

**Description:** [Who they are and their responsibility]

**Access Scope:** [e.g., read-only]

**Key interactions:**
- [Interaction 1]

---

### 3.3 [Actor Name — e.g., Platform Services / M2M]

**Description:** [Who they are and their responsibility]

**Access Scope:** [e.g., client credentials, specific scopes]

**Key interactions:**
- [Interaction 1]

---

### 3.4 Quality & Regulatory Affairs

**Description:** QA/RA team responsible for reviewing the SDLC documentation package, approving risk assessments, and ensuring compliance with ISO 13485, IEC 62304, ISO 14971, and applicable data protection regulations.

**Key interactions:** Document review and approval, audit support, regulatory submission preparation.

---

## 4. Scope Definition

### 4.1 In Scope

<!-- List all functional capabilities included in this service's boundary.
     Group by capability area. Be specific — this section drives the Use Cases and SRS. -->

| Capability | Description |
|---|---|
| [Capability 1] | [What it does] |
| [Capability 2] | |

### 4.2 Out of Scope

<!-- Explicitly exclude capabilities that are NOT implemented by this service.
     For each exclusion, state WHY it is excluded (responsibility of another service, deferred, organisational SOP, etc.).
     This section is critical for preventing scope creep during development and audit. -->

| Exclusion | Reason |
|---|---|
| Authentication / Authorisation | Delegated to platform **edge** identity and authorisation (not implemented inside this service) |
| Direct database access (bypassing DAS) | Operational MongoDB is accessed through **DAS** (MongoDB **Wire Protocol** proxy); application code uses the MongoDB client against the **DAS** endpoint. |
| [Other exclusion] | [Reason] |

---

## 5. Design Guidelines

<!-- State the binding architectural and design principles that govern all technical decisions in this service.
     These are enforceable standards, not recommendations. Deviations require sign-off.
     Each principle should have: an ID, a name, and the rationale (including regulatory/standard basis where applicable). -->

| # | Principle | Rationale |
|---|---|---|
| P-01 | [Principle name — e.g., Operational data via DAS] | [Why — e.g., All MongoDB Wire traffic via **DAS**; ISO 27001 centralised access control] |
| P-02 | [Principle name] | |
| P-03 | [Principle name] | |

---

## 6. Assumptions

<!-- List explicit assumptions made during the design of this service.
     Assumptions that prove false may require design changes — flag them for validation. -->

| # | Assumption | Impact if False |
|---|---|---|
| A-01 | [Assumption text] | [What would need to change] |
| A-02 | | |

---

## 7. Constraints

<!-- List non-negotiable constraints imposed by platform, regulatory requirements, technology, or organisational policy.
     Examples: technology stack, deployment environment, data residency, retention periods. -->

| # | Constraint | Source |
|---|---|---|
| C-01 | [Constraint text — e.g., Service must run on Node.js ≥ v20 LTS] | [H.Core platform standard / ISO 13485 §7.3 / etc.] |
| C-02 | | |

---

## 8. Open Decisions & Residual Questions

### 8.1 Decisions Made

<!-- Log architectural and design decisions that were debated and resolved. For each:
     - State the question
     - State the decision taken
     - Provide brief rationale
     Reference from Architecture Document (`[SVC]-ARCH-001` AD-NNN) where applicable. -->

| ID | Question | Decision | Rationale |
|---|---|---|---|
| D-01 | [Decision question] | [Decision taken] | [Why] |

### 8.2 Residual Questions & Open Decisions

<!-- Log unresolved questions that need an answer before design or implementation can proceed.
     Each should be assigned an owner and a target resolution date. -->

| ID | Question | Owner | Target Date | Status |
|---|---|---|---|---|
| Q-01 | [Open question] | | | Open |

### 8.3 Future Considerations

<!-- Document capabilities that are explicitly out of scope for this phase but are anticipated for future phases.
     Include: what the capability is, why it is deferred, and any regulatory/compliance prerequisites
     that must be resolved before design work begins.
     Tag with: Future-Phase, GDPR, ISO 14971, etc. -->

> **[Future capability name] — Out of Scope for this phase.**
> [Describe the capability and why it is deferred. List compliance prerequisites that must be addressed before design begins.]

---

*End of Document — [SVC]-OVW-001 v0.1.0*
*Next in package: [SVC]-UC-001 — Use Cases*
