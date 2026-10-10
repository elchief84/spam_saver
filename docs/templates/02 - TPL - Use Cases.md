# [Service Name] — Use Cases

**Document ID:** [SVC]-UC-001
**Version:** 0.1.0
**Status:** Draft
<!-- Status options: Draft | Pending Review | Draft — Revised | Pending Approval | Approved | Superseded -->
**Service:** `[service-name]`
**Last Updated:** [YYYY-MM-DD]
**Trace Parent:** [SVC]-OVW-001

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

<!-- Describe the purpose of this document: what actors and operations it covers, at what level of abstraction
     (what the actor needs to accomplish and why — not how the system implements it internally).
     State the parent document and the next document in the package. -->

This document defines all Use Cases (UCs) for the [Service Name]. Use Cases are written from the perspective of the actors who use or depend on the service. They describe *what* each actor needs to accomplish and *why* — not how the system implements it internally.

---

## Actor Definitions

<!-- Define all actors referenced in the Use Cases below.
     Actors may be human users, patient-facing apps, or platform services. -->

| Actor | Description |
|---|---|
| **[Actor 1 — e.g., Operator]** | [Description — e.g., Internal editor responsible for creating and publishing content] |
| **[Actor 2 — e.g., Patient App]** | [Description — e.g., Mobile app acting on behalf of an authenticated patient. Read-only.] |
| **[Actor 3 — e.g., Platform Service]** | [Description — e.g., Another H.Core microservice that reads data programmatically] |

---

## UC-01 — [Use Case Title]

<!-- Naming convention: UC-NN — Verb + Object (e.g., "Create a Content Record", "Retire a Tag") -->

**Actor:** [Actor(s) who trigger this use case]
**Preconditions:**
<!-- List all conditions that must be true before this use case can begin.
     Include: authentication/authorisation state, existence of referenced records, any environmental prerequisite. -->
- The actor is authenticated and authorised to [perform this action].
- [Other precondition — e.g., the target record exists and has not been retired]

**Story:**
<!-- Write 2–4 sentences from the actor's perspective. First-person narrative.
     Include: the actor's goal, the action they take, and the outcome they expect.
     Where there are multiple actors with different views (e.g., operator vs patient app), write a sentence for each.
     Do NOT describe how the system implements the use case — describe what the actor experiences. -->

As an **[Actor]**, I want to [goal] so that [outcome].

**Main Flow:**
<!-- Number each step. Steps should be at the level of "actor does X, system does Y" — not code-level.
     Cover: input submission, validation, system processing, confirmation returned to actor.
     Do not include error handling here — that is covered in Unhappy Paths below. -->

1. [Step 1 — e.g., The actor submits [data] to perform [action].]
2. [Step 2 — e.g., The system validates the submitted data.]
3. [Step 3 — e.g., The system processes the request and returns a confirmation.]

**Unhappy Paths:**
<!-- List all foreseeable failure scenarios and what the system does.
     Format: "Condition → system response"
     Cover: invalid input, missing records, concurrent modification, external service unavailability, authorisation failures. -->

- [Failure condition — e.g., A required field is missing or invalid] → [System response — e.g., the system rejects the request reporting the specific issue; no data is saved]
- [The record does not exist or belongs to a different tenant] → [System returns a not-found response; tenant isolation is not revealed]
- [The platform is temporarily unavailable] → [The actor is informed; no partial state is created]

**Postconditions:**
<!-- List the state of the system after a successful completion of this use case.
     Include: what was created/modified/deleted, what audit entries were created, what notifications were sent. -->

- [Postcondition 1 — e.g., The record is saved in unpublished state attributed to the creating actor]
- [Postcondition 2 — e.g., An audit trail entry is created for the operation]

---

## UC-02 — [Use Case Title]

**Actor:** [Actor(s)]
**Preconditions:**
- The actor is authenticated and authorised to [perform this action].
- [Other precondition]

**Story:**
As an **[Actor]**, I want to [goal] so that [outcome].

**Main Flow:**

1. [Step 1]
2. [Step 2]
3. [Step 3]

**Unhappy Paths:**

- [Failure condition] → [System response]
- [Failure condition] → [System response]

**Postconditions:**

- [Postcondition 1]
- [Postcondition 2]

---

<!-- Repeat the UC block above for each additional use case.
     Minimum expected use cases for a typical H.Core service:
     UC-01 Create
     UC-02 Update
     UC-03 Retire / Soft Delete
     UC-04 Search / List
     UC-05 Retrieve Single Record
     UC-06 Synchronisation / Delta Dump (if applicable)
     UC-07 Tag / Taxonomy Management (if applicable)
     UC-08 File / Asset Upload (if applicable)
     UC-09 Schema Introspection (if applicable)
     UC-10 Publish / Unpublish / Schedule (if applicable)
     UC-11 Machine-to-Machine Access (if applicable)
     UC-12 Error Handling (cross-cutting)
     UC-13 Versioning / Audit History
-->

---

## Traceability Matrix

<!-- Map each UC to the User Needs it satisfies. Populated after CMS-UN-001 is drafted. -->

| UC ID | Title | UN Trace |
|---|---|---|
| UC-01 | [Title] | UN-[NNN] |
| UC-02 | [Title] | UN-[NNN] |

---

*End of Document — [SVC]-UC-001 v0.1.0*
*Next in package: [SVC]-UN-001 — User Needs*
