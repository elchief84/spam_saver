# [Service Name] — Software Requirements Specifications

**Document ID:** [SVC]-SRS-001
**Version:** 0.1.0
**Status:** Draft
<!-- Status options: Draft | Pending Review | Draft — Revised | Pending Approval | Approved | Superseded -->
**Service:** `[service-name]`
**Last Updated:** [YYYY-MM-DD]
**Trace Parents:** [SVC]-UC-001 · [SVC]-UN-001 · [SVC]-RSK-001

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

<!-- Describe what this document contains and how it relates to the other documents in the package.
     State:
     - That requirements are atomic, unambiguous, and independently testable
     - Any platform components or concepts that are referenced (e.g., **DAS** (MongoDB Wire proxy), `model.map`, edge identity context)
     - How requirements trace to User Needs and Risks
-->

This document defines all Software Requirements Specifications (SRS) for the `[service-name]`. Each requirement is singular, unambiguous, atomic, and independently testable. Requirements are organised by functional area and every item traces to at least one User Need and one Risk where applicable.

---

## Ambiguities & Clarifications

<!-- Log any ambiguities identified during requirements authoring or review.
     Each item must record its status — Open items must be resolved before architecture design begins.
     Reference the decision record (AD-NNN in the Architecture Document) once resolved. -->

| ID | Item | Status |
|---|---|---|
| AMB-01 | [Description of the ambiguity and where it appears — e.g., "SRS-[NNN] uses term X but SRS-[NNN] uses term Y for the same concept"] | Open / Resolved — [Resolution description and reference to AD-NNN] |

---

<!--
AUTHORING INSTRUCTIONS FOR REQUIREMENTS

Each requirement entry follows this exact structure:

### SRS-[NNNNN]
**Text:** The system shall [specific, measurable behaviour].
         Use "shall" for mandatory requirements.
         Use "should" for recommended (non-mandatory) requirements.
         Use "may" for optional capabilities.
         One behaviour per requirement. Do not combine multiple conditions into one requirement.
         Avoid vague terms: never use "appropriate", "adequate", "as needed", "timely" without a defined criterion.
**Note:** [Optional clarification — explain why this requirement exists, what edge cases it covers,
          or what must NOT happen. Reference relevant risk items.]
**Tags:** `[functional-area]`, `[cross-cutting-concern]`
**Trace:** UN-[NNN] · RSK-[NNN]
         Always trace to at least one User Need. Trace to a Risk where the requirement implements a risk control.

Numbering convention:
SRS-1xx  Schema / Configuration Registry
SRS-2xx  Session Context & Domain Isolation (Security)
SRS-3xx  Create Record
SRS-4xx  Update Record
SRS-5xx  Retire / Soft Delete
SRS-6xx  Search / Filter / Paginate
SRS-7xx  Single Record Retrieval
SRS-8xx  Dump / Synchronisation
SRS-9xx  Tag Management
SRS-10xx File / Asset Upload
SRS-11xx Publish / Schedule
SRS-12xx Publishing Gate (patient-facing access control)
SRS-13xx Versioning / Audit History
SRS-14xx Error Handling
SRS-15xx [Additional functional area]
SRS-16xx [Additional functional area]
SRS-17xx Platform / Cross-Cutting (health probe, logging, SOUP restrictions)
-->

---

## 1. Schema Registry
<!-- Include this section if the service uses configuration-driven schemas (model.map or equivalent).
     Delete if not applicable. -->

### SRS-101
**Text:** The system shall load all schema configuration files from the designated configuration directory at service boot before accepting any inbound requests.
**Note:** The service must not become available to callers until all schema files are successfully parsed and registered.
**Tags:** `Schema`, `Boot`
**Trace:** UN-[NNN]

---

### SRS-102
**Text:** The system shall validate each schema configuration file at boot; if any file fails validation, the service shall abort startup and emit a critical log entry identifying the invalid file and the specific validation error.
**Note:** Fail-fast at boot prevents a corrupt schema from silently corrupting validation behaviour at runtime.
**Tags:** `Schema`, `Boot`, `Validation`
**Trace:** UN-[NNN] · RSK-[NNN]

---

### SRS-[NNN]
**Text:** [Requirement text]
**Note:** [Optional note]
**Tags:** `[Tag-1]`
**Trace:** UN-[NNN]

---

## 2. Session Context & Domain Isolation

### SRS-201
**Text:** The system shall derive the tenant domain value for every operation exclusively from the **platform-injected identity context** (see [SVC]-ARCH-001 / [SVC]-SDS-001); the system shall never accept domain as a caller-supplied request parameter or request body field.
**Note:** Core tenant isolation control. Any deviation is a compliance violation. See RSK-[NNN].
**Tags:** `Domain-Isolation`, `Security`, `Multi-Tenancy`
**Trace:** UN-[NNN] · RSK-[NNN]

---

### SRS-202
**Text:** The system shall include the caller's domain as a mandatory, non-overridable filter on every query that reads from or writes to a data collection.
**Note:** This filter must be applied by the service layer; it must not be delegated to the caller or left optional.
**Tags:** `Domain-Isolation`, `Security`
**Trace:** UN-[NNN] · RSK-[NNN]

---

## 3. [Create Record / Primary Write Operation]

### SRS-301
**Text:** The system shall [create / persist] a new [entity] record only when the request carries a valid authenticated session with [required scope — e.g., write access].
**Tags:** `[Entity]`, `Authentication`
**Trace:** UN-[NNN]

---

### SRS-302
**Text:** The system shall validate all submitted fields against the schema definition; the system shall reject the request if any field fails validation and shall identify the specific failing field(s) in the response.
**Tags:** `Validation`, `Error-Handling`
**Trace:** UN-[NNN]

---

### SRS-303
**Text:** The system shall auto-populate the following system fields at creation time, regardless of caller input: [unique identifier, created_at timestamp, created_by identity, default status, version counter].
**Note:** These fields must not be modifiable by the caller.
**Tags:** `Data-Integrity`, `Audit`
**Trace:** UN-[NNN]

---

## 4. [Update Record]

### SRS-401
**Text:** The system shall update only the fields explicitly included in the request; fields not included in the request shall retain their existing values.
**Tags:** `Data-Integrity`, `Partial-Update`
**Trace:** UN-[NNN]

---

## 5. [Retire / Soft Delete]

### SRS-501
**Text:** The system shall retire a record by marking it with a retired status and recording the retiring actor's identity and the retirement timestamp; the system shall never physically delete the record.
**Note:** Physical deletion of any record is permanently prohibited. Required for ISO 13485 §4.2.5 and GxP data retention.
**Tags:** `Soft-Delete`, `Data-Retention`, `GxP`
**Trace:** UN-[NNN]

---

## 6. [Search / Filter / Paginate]

### SRS-601
**Text:** The system shall support field-level filtering for all filterable fields declared in the schema definition; the system shall reject requests that reference fields not declared as filterable.
**Tags:** `Search`, `Schema-Validation`
**Trace:** UN-[NNN]

---

### SRS-602
**Text:** The system shall restrict search results to records where [published = true AND publication_date ≤ current timestamp] for all callers with read-only scope; this filter shall be applied unconditionally and cannot be bypassed by any caller-supplied parameter.
**Note:** Patient safety control — see RSK-[NNN]. Do not relax.
**Tags:** `Patient-Safety`, `Publishing`, `Access-Control`
**Trace:** UN-[NNN] · RSK-[NNN]

---

## 7. [Single Record Retrieval]

### SRS-701
**Text:** The system shall apply the same publication visibility filter to single-record retrieval as to search and list operations for read-only callers; a read-only caller requesting an unpublished record shall receive the same not-found response as for a non-existent record.
**Note:** The existence of unpublished records must not be revealed to read-only callers.
**Tags:** `Patient-Safety`, `Publishing`
**Trace:** UN-[NNN] · RSK-[NNN]

---

## 8. [Versioning / Audit History]

### SRS-[NNN]
**Text:** The system shall create an immutable version snapshot of a [entity] record after every successful create, update, retire, and publish operation.
**Note:** Snapshots are write-once; they must not be modifiable or deletable after creation.
**Tags:** `Versioning`, `GxP`, `Audit`
**Trace:** UN-[NNN] · RSK-[NNN]

---

### SRS-[NNN]
**Text:** The system shall emit a CRITICAL log entry if a version snapshot write fails; this failure shall not prevent the primary operation (create, update, retire, publish) from completing.
**Note:** Best-effort snapshot design — primary operation must not be blocked by audit subsystem failure. Monitor via alerting rule.
**Tags:** `Versioning`, `Resilience`, `GxP`
**Trace:** UN-[NNN] · RSK-[NNN]

---

## [N]. Error Handling

### SRS-[NNN]
**Text:** The system shall respond to all errors with a structured response containing a machine-readable error code, a human-readable message, and a correlation identifier; the system shall never include stack traces, database identifiers, internal service names, or infrastructure topology details in error responses.
**Note:** Required by ISO 27001 information disclosure controls. See RSK-[NNN].
**Tags:** `Error-Handling`, `Security`, `ISO-27001`
**Trace:** UN-[NNN] · RSK-[NNN]

---

## [N]. Platform / Cross-Cutting

### SRS-[NNN]
**Text:** The system shall expose a health probe endpoint that reports service readiness, including the status of all upstream dependencies; the endpoint shall return a degraded status if any dependency is unreachable.
**Tags:** `Health`, `Observability`, `Kubernetes`
**Trace:** UN-[NNN]

---

### SRS-[NNN]
**Text:** The system shall emit a structured JSON log entry for every inbound request and every outbound upstream call, including correlation and trace identifiers; log entries shall not contain personally identifiable information.
**Tags:** `Logging`, `GDPR`, `Observability`
**Trace:** UN-[NNN] · RSK-[NNN]

---

## Requirements Traceability Summary

| SRS ID | Summary | UN Trace | Risk Trace |
|---|---|---|---|
| SRS-201 | Domain derived from session only | UN-[NNN] | RSK-[NNN] |
| SRS-501 | Soft delete only — no physical deletion | UN-[NNN] | — |
| SRS-602 | Publish gate unconditional for read-only callers | UN-[NNN] | RSK-[NNN] |

---

*End of Document — [SVC]-SRS-001 v0.1.0*
*Next in package: [SVC]-ARCH-001 — Software Architecture*
