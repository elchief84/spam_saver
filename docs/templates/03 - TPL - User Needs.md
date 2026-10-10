# [Service Name] — User Needs

**Document ID:** [SVC]-UN-001
**Version:** 0.1.0
**Status:** Draft
<!-- Status options: Draft | Pending Review | Draft — Revised | Pending Approval | Approved | Superseded -->
**Service:** `[service-name]`
**Last Updated:** [YYYY-MM-DD]
**Trace Parent:** [SVC]-UC-001

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

## Document Scope

<!-- Describe the purpose of this document.
     User Needs represent the high-level intentions, expectations, and constraints of all stakeholders
     — before any technical solution is defined.
     Each need is traceable to one or more Use Cases and will be decomposed into testable Software Requirements. -->

This document captures the User Needs (UN) for the [Service Name]. User Needs represent the high-level intentions, expectations, and constraints of all stakeholders — before any technical solution is defined. Each need is traceable to one or more Use Cases and will be decomposed into testable Software Requirements in the next phase.

---

<!--
AUTHORING INSTRUCTIONS FOR USER NEEDS

Each UN entry follows this exact structure:

## UN-[NNN]

**Text:** [The need statement — one sentence, written from a stakeholder perspective.
          Use "must" for mandatory needs. Avoid technical terms, API names, field names, or implementation details.
          Subject should be a stakeholder role (e.g., "Authorised operators", "Platform services", "The system").
          Format: "[Subject] must be able to [achieve goal], so that [outcome/value]."
          OR for system properties: "The system must [provide property] such that [outcome]." ]

**Note:** [Optional clarifying context. Explain the regulatory/safety rationale, define important boundaries, or flag
          what must NOT happen. Keep stakeholder perspective — do not specify how the system achieves the need.
          Reference relevant tags (GxP, GDPR, ISO 13485, Patient-Safety) where applicable.]

**Tags:** `[Tag-1]`, `[Tag-2]`, `[Tag-3]`
<!-- Tag vocabulary: Content-Authoring | Publishing | Operator-Workflow | Patient-Safety | Data-Retention |
     Data-Integrity | GxP | ISO-13485 | Audit | Compliance | Search | Pagination | Access-Control |
     Synchronisation | Offline-Support | Performance | Taxonomy | Security | Asset-Management |
     File-Upload | Schema-Driven | Integration | Publishing | Scheduling | Platform-Integration |
     Multi-Tenancy | Tenant-Isolation | GDPR | ISO-27001 | Data-Governance | Architecture-Constraint |
     Configurability | Operability | Observability | Logging | Privacy | Analytics | Future-Phase -->
**Trace UC:** [UC-NN, UC-NN]

-->

---

## UN-101

**Text:** [Authorised operators must be able to [create/read/update/retire] [entity], so that [outcome].]

**Note:** [Clarifying context, safety rationale, or boundary condition. For example: "Records must not be visible to patients upon creation — a deliberate publishing step must exist."]

**Tags:** `[Tag-1]`, `[Tag-2]`
**Trace UC:** UC-01

---

## UN-102

**Text:** [Authorised operators must be able to [modify] existing [entity] records [to achieve goal], without [undesirable side effect].]

**Note:** [Clarifying context.]

**Tags:** `[Tag-1]`, `[Tag-2]`
**Trace UC:** UC-02

---

## UN-103

**Text:** [Authorised operators must be able to retire [entity] records that are no longer valid, without permanently destroying the underlying data.]

**Note:** Regulatory frameworks (GxP, ISO 13485) require that [data type] be retained even after it is no longer in active use. Retired records must be invisible to [consumers] but preserved for audit and regulatory inspection.

**Tags:** `Data-Retention`, `GxP`, `ISO-13485`, `Audit`
**Trace UC:** UC-03

---

<!-- PATIENT SAFETY USER NEEDS — mandatory for all services that deliver content or data to patients -->

## UN-[NNN] — Publish Gate / Access Control

**Text:** Any authorised consumer must only receive [records/data/content] that [have been explicitly approved for delivery / meet the defined access criteria].]

**Note:** [Patient-facing consumers must never receive unreviewed or unpublished content. This is a patient safety control. The system must apply this restriction unconditionally — it must not be bypassable by any caller-supplied parameter.]

**Tags:** `Publishing`, `Patient-Safety`, `Access-Control`
**Trace UC:** UC-[NN]

---

<!-- DATA INTEGRITY / AUDIT — mandatory for all services under ISO 13485 / GxP -->

## UN-[NNN] — Versioning and Audit History

**Text:** The system must maintain a complete, immutable change history for all [entity] records, enabling full reconstruction of [entity] state at any point in time for regulatory inspection.

**Note:** Required for GxP compliance and ISO 13485 traceability. Every create, update, retire, and [publish/status change] operation must produce a permanent snapshot. Change history must be retained indefinitely.

**Tags:** `Versioning`, `GxP`, `ISO-13485`, `Audit`, `Compliance`
**Trace UC:** UC-[NN]

---

<!-- TENANT ISOLATION — mandatory for all multi-tenant services -->

## UN-[NNN] — Cross-Tenant Isolation

**Text:** The system must enforce strict tenant isolation such that no consumer — regardless of access level — can access, modify, or infer the existence of data belonging to a different tenant.

**Note:** The tenant context for every operation must be derived exclusively from the authenticated session. It must never be accepted as a parameter supplied by the caller. Cross-tenant leakage is a critical security and regulatory risk under GDPR and ISO 27001.

**Tags:** `Multi-Tenancy`, `Tenant-Isolation`, `Security`, `GDPR`, `ISO-27001`
**Trace UC:** UC-01, UC-02, UC-03 <!-- extend to all relevant UCs -->

---

<!-- ERROR HANDLING — mandatory for all services -->

## UN-[NNN] — Consistent Error Handling

**Text:** The system must respond to all invalid, malformed, or unauthorised requests with consistent, clearly structured responses that do not expose internal system details.

**Note:** Error responses must be informative enough for integration teams to diagnose problems, but must never reveal internal infrastructure details, system topology, or implementation specifics.

**Tags:** `Error-Handling`, `Security`, `ISO-27001`
**Trace UC:** UC-[NN]

---

<!-- LOGGING — mandatory for all services -->

## UN-[NNN] — Traceable Logging with PII Protection

**Text:** The system must produce structured, traceable logs for every operation and every interaction with other platform components, enabling operational monitoring and incident investigation, without exposing personally identifiable information in log outputs.

**Note:** Each log entry must be linkable across distributed services for end-to-end tracing. User identifiers are classified as personal data under GDPR and must be anonymised in log outputs. Full identifiers are retained only in controlled audit systems, not in general operational logs.

**Tags:** `Observability`, `Logging`, `GxP`, `GDPR`, `ISO-27001`, `Privacy`
**Trace UC:** UC-[NN]

---

<!-- Add additional UNs as needed. Number sequentially starting from UN-101. -->

---

## Traceability Matrix

| UN ID | Summary | UC Trace |
|---|---|---|
| UN-101 | [Brief summary] | UC-01 |
| UN-102 | [Brief summary] | UC-02 |
| UN-103 | [Brief summary] | UC-03 |

---

*End of Document — [SVC]-UN-001 v0.1.0*
*Next in package: [SVC]-RSK-001 — Risk Analysis*
