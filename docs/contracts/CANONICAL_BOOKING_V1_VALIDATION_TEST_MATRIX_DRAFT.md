# DOJO WALK — Canonical Booking v1 Validation Test Matrix

**Status:** DRAFT — NOT EXECUTED — NOT APPROVED  
**Date:** 2026-10-30  
**Related files:**
- `docs/contracts/schemas/booking-v1.schema.json`
- `docs/contracts/fixtures/booking-v1-validation-fixtures-draft.json`
- `docs/contracts/CANONICAL_BOOKING_V1_JSON_SCHEMA_VALIDATION_SPEC_DRAFT.md`

> This is a planned test matrix. No test runner, JSON Schema validator, Firebase Emulator or app integration suite was executed while authoring it. Expected outcomes are specifications, not test results.

## 1. Test layers

| Layer | Responsibility | Must not be confused with |
|---|---|---|
| L1 — JSON Schema | Shape, required fields, types, enums, basic ranges, unknown properties | Authorization, date arithmetic, availability |
| L2 — Domain validation | Cross-field rules, date bounds, 28-day term, time/slot rules, enabled service limits | Trusted server writes |
| L3 — Security/backend | Ownership, server-only fields, zone resolution, quote/payment/assignment authority, idempotency | Client-side validation |
| L4 — Legacy compatibility | Read legacy records conservatively and preserve raw evidence | Canonical schema validation |
| L5 — Cross-app parity | Same normalized fixture meaning across Customer/Admin/Partner | Each app inventing its own interpretation |
| L6 — Firebase/API integration | Rules and trusted endpoint acceptance/rejection | JSON Schema-only success |

## 2. Positive structural fixture coverage

Use the synthetic examples in `booking-v1-validation-fixtures-draft.json`.

| Fixture | Expected structural result | Additional domain assertions before any approval |
|---|---|---|
| Single Walk | Expected schema-valid | One date, exactly one walk, server eligibility/availability |
| Temporary Booking | Expected schema-valid | start ≤ end; selected dates unique, sorted and within inclusive range |
| Monthly Package | Expected schema-valid | Exactly 28 inclusive dates; end = start + 27 days |
| Daily Continuous | Expected schema-valid as a placeholder | Cycle policy ID must refer to an approved policy; cadence enabled for customer/zone; month-end rule approved |

“Expected schema-valid” is a design expectation only. Run an actual Draft 2020-12 validator and record its name/version before marking it passed.

## 3. Negative test matrix

| ID | Area | Invalid condition | Expected rejection layer |
|---|---|---|---|
| N01 | Version | schemaVersion is not 1 | L1 |
| N02 | Type | Unknown bookingType | L1 |
| N03 | Required | Missing customerId | L1 |
| N04 | Pickup | Latitude outside -90..90 | L1 |
| N05 | Pickup | Coordinates supplied without accuracy | L1 |
| N06 | Schedule | Time is not 24-hour HH:mm | L1 |
| N07 | Schedule | Duration outside 20–60 minutes | L1 |
| N08 | Shape | Unapproved top-level field such as clientCalculatedPrice | L1 |
| N09 | Temporary | Missing endDate | L1 |
| N10 | Monthly | Missing endDate | L1 |
| N11 | Daily Continuous | Missing cyclePolicyId | L1 |
| N12 | Billing | paymentCadence=auto_pay | L1 |
| N13 | Temporary | Selected date outside inclusive bounds | L2 |
| N14 | Monthly | Term is not exactly 28 inclusive dates | L2 |
| N15 | Temporary | Duplicate selected date | L1 structural check; L2 ordering/normalization too |
| N16 | Payment | Client tries to set payment as paid | L3 |
| N17 | Assignment | Client forges walkerId/assigned state | L3 |
| N18 | Zone | Client supplies authoritative service zone | L3 |
| N19 | Ownership | Dog/address belongs to another customer | L3 |
| N20 | GPS | Stale or inaccurate location evidence | L2/L3 after thresholds approved |

The exact expected error codes and user-facing messages are not frozen. Backend/API owners must define stable machine-readable error codes; UI teams localize messages from those codes rather than matching free-text errors.

## 4. Cross-field domain assertions

The following assertions must be executable in a shared domain validator, not scattered across screen widgets:

1. **Single Walk:** exactly one selected local date and one walk instance; immediate/ASAP resolves to a valid server-approved service date/time.
2. **Temporary Booking:** both bounds exist; startDate ≤ endDate; every selected date is inside the inclusive range; no duplicate dates; per-date walk count respects enabled configuration.
3. **Monthly Package:** inclusive end date equals start date plus 27 calendar days; leap-year and year-boundary cases covered.
4. **Daily Continuous:** cycle calculations are blocked until D-04 month-end anchor policy is approved; cadence must be manual and explicitly enabled.
5. **All types:** timezone is explicit; no UTC truncation to derive service date; selected slot/time/duration conforms to active service configuration.
6. **Pickup:** location evidence is valid and sufficiently fresh/accurate under approved thresholds; backend resolves active verified zone geometry.
7. **Availability:** no quote/payment action is enabled until backend confirms availability and issues an unexpired server quote.
8. **Payment:** payment success only after provider/backend verification; duplicate callbacks and retries are idempotent.
9. **Assignment:** customer sees Walker assigned only after trusted acceptance/assignment event.
10. **Lifecycle:** booking/payment/assignment/walk states are validated independently; illegal transitions are rejected.

## 5. Security and authorization tests

| Test | Attempt | Expected result |
|---|---|---|
| SEC-01 | Unauthenticated create/read | Deny |
| SEC-02 | Customer creates booking for another customerId | Deny |
| SEC-03 | Customer references another customer's dog/address | Deny |
| SEC-04 | Customer writes quote or pricing fields | Deny |
| SEC-05 | Customer marks payment paid/refunded | Deny |
| SEC-06 | Customer chooses zoneId or marks zone resolved | Deny |
| SEC-07 | Customer sets walkerId or assignmentStatus=assigned | Deny |
| SEC-08 | Partner reads booking not assigned/offered to that Partner | Deny |
| SEC-09 | Partner modifies quote/payment/customer identity | Deny |
| SEC-10 | Client changes server timestamps or lifecycle illegally | Deny |
| SEC-11 | Duplicate booking request uses same idempotency key | Return same logical result; do not create duplicate |
| SEC-12 | Concurrent availability requests compete for last slot | Server transaction prevents double allocation |

These are required test intentions, not a statement that current Firebase Rules already enforce the proposed canonical contract. Existing Rules currently target the legacy allowlist; do not deploy canonical fixtures against production Rules.

## 6. Legacy adapter regression matrix

| Legacy source shape | Expected classification | Forbidden inference |
|---|---|---|
| Legacy one-time / one walk | Candidate Single Walk; review until semantics verified | Paid, confirmed, zone-resolved, assigned |
| Legacy regular / daily / 7 per week | `legacy_regular_unclassified` | Monthly Package or Daily Continuous |
| Legacy custom dates without explicit bounds | Needs review | Temporary Booking with invented start/end |
| Unknown or malformed fields | Preserve raw record and reason codes | Drop fields or coerce into a valid canonical type |
| Canonical and legacy markers conflict | `schema_conflict` | Silently prefer one marker |

Legacy records must not be fed directly to the canonical JSON Schema validator as if they were canonical v1 records.

## 7. Cross-app fixture parity

Run the exact same fixture set through each app's shared read/normalization layer:

| App | Required parity assertion |
|---|---|
| Customer | No false paid/confirmed/assigned state; correct request/quote/availability messaging |
| Admin | Same type classification and independent lifecycle dimensions; no permission inferred from display state |
| Partner | No work authorization unless trusted assignment/offer evidence exists |
| Firebase/backend | Source of truth for schema version, authorization, zone, quote, payment and assignment |

Compare normalized outputs field-by-field. UI copy may differ by locale, but machine states and reason codes must match.

## 8. Execution evidence template

For each run, record:
- Repository, branch and commit SHA.
- Validator/test framework and exact version.
- Command and environment (local/CI/Firebase Emulator).
- Fixture count and test count.
- Passed, failed, skipped and blocked counts.
- Failure logs/artifacts and issue links.
- Reviewer and execution timestamp.

Do not label the suite PASS if only JSON parsing, formatting or static file read-back was checked.

## 9. Current blockers and release gate

- D-04 Daily Continuous month-end anchor policy unresolved.
- Manual payment cadence, overdue/grace and related financial policy require approval.
- Lifecycle enums/transitions and assignment evidence need backend/product sign-off.
- Pickup GPS freshness/accuracy thresholds need safety/backend sign-off.
- Service catalogue must define enabled duration, walks/day and capacity constraints.
- Timestamp binding, idempotency contract and schema extension strategy need backend agreement.
- Current Firebase Rules are legacy-oriented; canonical schema has not been wired to trusted backend writes.
- No validator/emulator/app tests have been executed for this draft.

**NO-GO:** no canonical production writes, Rules/Functions/API change, migration, payment/assignment rollout or PR merge until approvals, executable tests and security evidence are complete.
