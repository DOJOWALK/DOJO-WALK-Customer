# DOJO WALK — Shared Booking Contract v1 Final Decision Register

**Status:** DRAFT — DECISIONS REQUIRED — NOT APPROVED  
**Date:** 2026-10-30  
**Scope:** Customer / Admin / Partner / Backend / Firebase booking compatibility  
**Related documents:**
- `SHARED_BOOKING_DATA_CONTRACT_V1_DRAFT.md`
- `CROSS_APP_BOOKING_COMPATIBILITY_AUDIT_V1.md`
- `LEGACY_BOOKING_MIGRATION_COMPATIBILITY_PLAN_V1_DRAFT.md`
- `BOOKING_COMPATIBILITY_TEST_FIXTURES_V1_DRAFT.md`
- `SHARED_BOOKING_ADAPTER_IMPLEMENTATION_BLUEPRINT_V1_DRAFT.md`

> This register organizes unresolved decisions and recommended defaults. It does not record approvals that have not actually been given. No runtime implementation, Firestore Rules change, migration, payment/assignment change, deployment or PR merge is authorized by this document.

## 1. Decision governance

| Decision area | Accountable approver | Required reviewers | Evidence required before approval |
|---|---|---|---|
| Product meaning and customer promises | Founder/CEO | Product, Customer Experience, Operations | Approved policy wording and examples |
| Canonical data model and API | Backend owner | Customer, Admin, Partner | Versioned schema, API contract and compatibility tests |
| Firestore Rules and trusted writes | Firebase/Security owner | Backend, app owners | Rules diff, emulator tests, authorization matrix |
| Customer UI and legacy read behavior | Customer app owner | Product, Backend | UI states, fixture parity, widget/integration tests |
| Operations display and controls | Admin app owner | Central Operations, Security | Role matrix, audit requirements, UI evidence |
| Walker work and live-walk compatibility | Partner app owner | Operations, Backend, Safety | Assignment/read contract, location tests, lifecycle tests |
| Privacy, retention and diagnostics | Security/Privacy owner | Founder, Backend, app owners | Data-flow review, logging/cache/retention controls |

Approval must be recorded with approver role, date, decision, scope and linked evidence. Silence or document creation is not approval.

## 2. Decision register

### D-01 — Canonical schema versioning

**Question:** How is a canonical booking distinguished from legacy records and future schema versions?

**Recommended decision:** Require an explicit integer `schemaVersion` and canonical `bookingType`. Parse only supported versions. Unknown versions return `unsupported`; conflicting canonical and legacy markers return `schema_conflict`.

**Owner:** Backend. **Reviewers:** Firebase, Customer, Admin, Partner.  
**Status:** Pending approval.  
**Evidence:** JSON Schema (or equivalent), required-field rules, version compatibility policy and fixtures.

### D-02 — Canonical booking types

**Question:** Which booking types are valid in v1?

**Recommended decision:** Exactly four product types:
- `single_walk`
- `temporary_booking`
- `monthly_package`
- `daily_continuous`

Time-of-day slots (Morning/Afternoon/Evening/Night) are schedule attributes, not booking types. Extra Walk and Reschedule are actions/features, not booking types.

**Owner:** Founder/Product. **Reviewers:** Customer, Operations, Backend.  
**Status:** Product direction recorded; formal approval pending.  
**Evidence:** Signed-off POL-006 wording and acceptance examples.

### D-03 — Monthly Package term

**Question:** What is the duration and date inclusivity?

**Current Founder direction:** Calendar-monthly term, not a fixed 28-day package. The booking starts on the selected start date and ends on the day before the same date in the following month (for example, start 7 November → end 6 December), using the agreed service-local date semantics.

**Decision status:** This direction supersedes the 28-consecutive-day recommendation in earlier draft material. Do not implement `startDate + 27 days` as the Monthly Package rule. The final policy/API examples and edge cases (month-end starts such as 29/30/31, February, leap years, and year boundaries) still require explicit written confirmation before cross-app implementation.

**Owner:** Founder/Product. **Reviewers:** Backend, Customer, Finance.  
**Status:** Founder direction recorded; contract/schema/validator alignment required before approval.  
**Evidence:** Updated POL-006/POL-011 wording, deterministic date examples, API date-only semantics and cross-app fixtures.

### D-04 — Daily Continuous cycle and month-end anchor

**Question:** How does a cycle starting on the 29th, 30th or 31st advance into shorter months?

**Options requiring explicit selection:**
- Preserve original anchor day: Jan 31 → Feb 28/29 → Mar 31.
- Roll forward from previous cycle: Jan 31 → Feb 28/29 → Mar 28/29.

**Recommended decision:** Do not choose by implementation convenience. Founder/Product and Finance must approve one rule and customer-facing examples before cycle calculation is wired to billing.

**Owner:** Founder/Product. **Reviewers:** Finance, Backend, Customer.  
**Status:** Blocked — no approved selection recorded.  
**Evidence:** Written choice, month-end examples, billing/proration treatment.

### D-05 — Daily Continuous payment cadence

**Question:** Which manual payment cadence is offered?

**Current product direction:** Weekly Manual or Monthly Manual where enabled. No Auto-Pay.

**Recommended decision:** Backend must receive an explicit approved cadence and due schedule. No recurring debit or automatic charge. Define due date, grace, overdue, pause and failed-payment behavior separately.

**Owner:** Founder/Product. **Reviewers:** Finance, Backend, Customer Support.  
**Status:** Partial direction recorded; exact commercial rules pending.  
**Evidence:** Approved POL-011/POL-012 terms, server billing schedule, customer notices and test cases.

### D-06 — Temporary Booking date model

**Question:** How are finite booking dates represented?

**Recommended decision:** Require explicit inclusive `startDate` and `endDate`, plus selected service dates/days within the range. Reject selected dates outside the range. A disconnected selected-date list is not enough to infer range bounds.

**Owner:** Product + Backend. **Reviewers:** Customer, Admin, Partner.  
**Status:** Recommended; approval pending.  
**Evidence:** Schema validation, timezone/date-only contract and fixture coverage.

### D-07 — Legacy regular mapping

**Question:** Can existing `regular/regular_walk` documents map to a canonical type?

**Recommended decision:** No automatic mapping. Keep as `legacy_regular_unclassified`. Existing daily frequency and seven walks/week do not establish Monthly Package or Daily Continuous term/payment semantics.

**Owner:** Backend. **Reviewers:** Founder/Product, Customer, Admin, Partner.  
**Status:** Safety default recommended; formal mapping decision pending.  
**Evidence:** Historical source evidence, reviewed mapping table and regression fixtures.

### D-08 — Legacy custom mapping

**Question:** Can `customize/custom_walk` map to Temporary Booking?

**Recommended decision:** Only when trusted evidence explicitly establishes inclusive range bounds and all selected dates fall within them. Otherwise preserve as `legacy_custom_dates`, with no canonical type.

**Owner:** Backend. **Reviewers:** Product, Customer, Admin.  
**Status:** Safety default recommended; formal approval pending.  
**Evidence:** Source-field inventory and deterministic migration examples.

### D-09 — Legacy one-time mapping

**Question:** Does `one_time/temporary_walk` always mean Single Walk?

**Recommended decision:** Treat as a candidate only after immediate-vs-scheduled behavior, one-date semantics and one-walk count are verified. Never claim confirmed or paid from this mapping.

**Owner:** Product + Backend. **Reviewers:** Customer, Firebase.  
**Status:** Pending approval.  
**Evidence:** Historical writer behavior, valid fixture and lifecycle mapping.

### D-10 — Lifecycle state separation

**Question:** Are booking, payment, assignment and walk execution represented independently?

**Recommended decision:** Yes. Four separate state machines. Unknown legacy values remain unknown with original raw value and reason code. A legacy `pending` is not proof of quote, payment, confirmation or assignment.

**Owner:** Backend. **Reviewers:** Founder/Product, Firebase, all app owners.  
**Status:** Architecture recommendation; mapping tables pending.  
**Evidence:** State diagrams, allowed transitions, server event ownership and tests.

### D-11 — Assignment authority

**Question:** What proves a Walker is assigned?

**Recommended decision:** Only a trusted backend assignment record/transition that verifies eligible Walker acceptance and server confirmation. A non-null legacy `walkerId` alone is insufficient for a customer-facing assigned claim until its provenance/history is verified.

**Owner:** Backend/Operations. **Reviewers:** Founder, Firebase/Security, Admin, Partner.  
**Status:** Pending; trusted assignment writer was not located in the bounded source audit.  
**Evidence:** Assignment service/function, eligibility checks, atomic concurrency control, audit log and emulator/integration tests.

### D-12 — Pickup coordinate precedence

**Question:** Which location fields are authoritative for navigation and zone checks?

**Recommended decision:** Preserve address reference/text, top-level latitude/longitude, GeoPoint and canonical nested pickup as distinct source variants. Backend contract must specify the authoritative coordinate source, accuracy threshold, freshness and conflict behavior. Do not infer a precedence in app code.

**Owner:** Backend + Safety. **Reviewers:** Partner, Customer, Firebase, Operations.  
**Status:** Pending approval.  
**Evidence:** API schema, GPS accuracy/freshness rules, Partner navigation tests and conflict fixtures.

### D-13 — Service-zone decision

**Question:** Who resolves pickup to a service zone?

**Recommended decision:** Backend only, using active and verified polygon geometry and a versioned location catalogue. Customer selects pickup location; no customer-facing zone selector. Missing result means unknown/pending validation, not eligible.

**Owner:** Backend/Location Operations. **Reviewers:** Founder, Firebase, Customer, Admin.  
**Status:** Product direction recorded; API shape and evidence requirements pending.  
**Evidence:** Zone resolution API, polygon/catalogue version, boundary tests and audit event.

### D-14 — Quote and payment authority

**Question:** What makes a quote or payment state trusted?

**Recommended decision:** Server-generated quote with expiry and policy/pricing version. Payment state only from verified provider/backend event. Client-supplied price or provider reference alone cannot establish paid state. No payment flow until approved price policy and trusted verification exist.

**Owner:** Backend + Finance. **Reviewers:** Founder, Firebase/Security, Customer.  
**Status:** Pending approval and implementation evidence.  
**Evidence:** POL-011 approval, quote API, payment verification, webhook/reconciliation tests.

### D-15 — Shared contract/package ownership

**Question:** Where is shared contract logic maintained?

**Recommended decision:** First approve a language-neutral contract and portable synthetic JSON fixture suite. Run equivalent adapter tests in each app. Decide later whether a shared Dart package, dedicated contract repository or generated schema is justified. Do not assume a shared package/repository already exists.

**Owner:** Architecture/Backend lead. **Reviewers:** all app owners.  
**Status:** Recommended; owner not assigned.  
**Evidence:** ADR, repo ownership, release/versioning policy and CI parity checks.

### D-16 — Raw source, privacy and caching

**Question:** How are raw legacy fields and adapter diagnostics handled?

**Recommended decision:** Preserve source evidence only within authorized access boundaries. Do not log full documents, addresses, coordinates, dog safety notes, contact details or payment references. Clear user-scoped cache on sign-out/account switch; do not let cache override permission changes or server updates.

**Owner:** Security/Privacy. **Reviewers:** Firebase, Backend, all app owners.  
**Status:** Pending review.  
**Evidence:** Data-flow review, retention policy, logging allowlist, cache invalidation tests.

### D-17 — Legacy migration and cutover

**Question:** When can canonical writes/backfill begin?

**Recommended decision:** Not during read-adapter design. Require approved schema, deployed backend writer, restrictive Rules, emulator/integration tests, shadow-read parity, dry-run, checkpoint/rollback and explicit go/no-go approval. Never dual-write without a separately approved consistency design.

**Owner:** Backend + Firebase. **Approver:** Founder/CEO.  
**Status:** NO-GO until gates satisfied.  
**Evidence:** Migration runbook, dry-run report, rollback rehearsal, compatibility metrics and signed approval.

## 3. Cross-cutting invariants — must not be weakened

1. Notion remains the product/policy source of truth; implementation must link to approved policy versions.
2. Firebase/backend is authoritative for booking eligibility, zone, quote, payment, assignment and lifecycle.
3. Customer must not select a service zone.
4. Request received is not confirmed, paid or Walker assigned.
5. No client-calculated authoritative price.
6. No automatic payment debit; manual cadence only where formally approved.
7. Unknown legacy data is preserved, not guessed or silently discarded.
8. Adapters are read-only and side-effect-free.
9. Customer/Admin/Partner authorization remains enforced by backend and Firestore Rules.
10. No production cutover or PR merge based solely on documentation.

## 4. Approval record template

For each decision, record:

- Decision ID:
- Outcome: Approved / Rejected / Deferred
- Approver role:
- Approver identity (in approved internal record only):
- Date and time:
- Exact approved wording/value:
- Scope and exclusions:
- Evidence links:
- Follow-up owner:
- Related contract/policy version:

Do not mark a decision approved until this record is completed by the authorized approver.

## 5. Current release gate

**NO-GO** for canonical runtime writes, Firestore Rules changes, migration/backfill, assignment/payment workflow changes, production rollout or PR merge.

Permitted next work after review: update this register with explicit decisions, then revise the shared contract and fixtures to match approved outcomes. Until then, all artifacts remain drafts.
