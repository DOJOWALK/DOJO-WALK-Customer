# DOJO WALK — Legacy Booking Migration & Compatibility Plan v1

**Status:** DRAFT — NOT APPROVED — NOT IMPLEMENTED  
**Date:** 2026-10-30  
**Scope:** Customer, Admin, Partner, Firebase/backend booking records  
**Source of truth:** Notion POL-006; shared contract draft and cross-app compatibility audit are implementation references.

> This plan is documentation only. It does not authorize runtime changes, Firestore Rules changes, Cloud Functions, production data migration, payment/assignment changes, deployment or PR merge.

## 1. Objectives and non-negotiable safeguards

1. Keep every existing legacy booking readable throughout rollout.
2. Preserve original fields and unknown values; never destructively rewrite a legacy document.
3. Do not guess whether a legacy Regular booking means Monthly Package or Daily Continuous.
4. Do not guess missing Temporary Booking start/end bounds.
5. Keep price, payment verification, service-zone eligibility, booking confirmation and Walker assignment server-authoritative.
6. Do not introduce canonical client writes until the shared contract, backend ownership, Rules and all app readers are approved and tested.
7. Prefer a read adapter first, then controlled canonical writes through a trusted backend; avoid uncontrolled dual writes.
8. Every migration step must be observable, retryable, idempotent and reversible.

## 2. Current compatibility baseline

The inspected Customer app still emits legacy enum/payload values: `oneTime`, `regular`, `chooseDates`; booking fields include `bookingPlan`, `serviceType`, `isImmediate`, `isRegular`, `isChooseDates`, `frequency`, `walksPerWeek`, `walkCount`, `walks`, `selectedDates`, and `dateSchedules`. The current review screen writes a pending document directly to Firestore.

The inspected Firebase `main` rules validate a fixed legacy key allowlist and require legacy fields. The proposed v1 fields are not accepted by that create validator. Admin's inspected booking screen displays bookings but does not show an assignment action. Partner consumes assigned legacy records, queries by `walkerId`, and reads legacy date/location fields; its walk-details flow updates `status` to `accepted`.

**Baseline restriction:** do not change the Customer writer, Firebase Rules, production documents or Partner/Admin runtime as part of this plan. GitHub main snapshots are not proof of deployed Rules or external services.

## 3. Legacy classification and mapping policy

| Legacy evidence | Candidate classification | Canonical mapping | Rule |
|---|---|---|---|
| `oneTime` / `one_time` + `temporary_walk` | Candidate Single Walk | `single_walk` | Map only after confirming one service date/one walk and immediate-vs-scheduled semantics. Otherwise `needs_review`. |
| `regular` / `regular` + `regular_walk` | Legacy regular, ambiguous | None automatically | Never infer `monthly_package` or `daily_continuous` from this label alone. Preserve as `legacy_regular_unclassified`. |
| `chooseDates` / `customize` + `custom_walk` | Custom date selection | `temporary_booking` only conditionally | Map only if explicit inclusive start/end bounds and selected dates can be deterministically recovered. Otherwise `legacy_custom_dates` / `needs_review`. |
| Any conflicting/missing/unknown type fields | Unknown legacy record | None | Preserve raw values; classify `needs_review` or `unsupported`. |
| Already has approved `schemaVersion` and canonical `bookingType` | Canonical | Existing canonical ID | Validate schema/version; do not rewrite if valid. |

Additional rules:
- Status values must not be translated into the new independent booking/payment/assignment/walk state machines by name similarity alone.
- A legacy `pending` status does not prove request validation, availability, quote, payment or assignment.
- A non-null `walkerId` does not by itself prove a current eligible/accepted assignment; retain it as legacy evidence and reconcile against authoritative assignment history.
- Never derive a paid state from amount fields, receipt text or client-provided payment metadata.
- Never derive serviceZoneId from locality/PIN/address text alone.
- Never infer missing coordinates, timezone, date bounds or policy version.

## 4. Classification record (proposed, non-authoritative)

A dry-run report may produce a sidecar classification record; it must not alter the source booking during the first phase.

Suggested fields:
- `sourceBookingId`
- `sourceSchema: legacy | canonical | unknown`
- `classification: deterministic | needs_review | unsupported | already_canonical`
- `candidateBookingType` (nullable)
- `confidence: high | medium | low`
- `reasonCodes[]`
- `sourceDocumentHash` or source version marker
- `classifiedAt`, `classifierVersion`
- `reviewStatus`, `reviewedBy`, `reviewedAt` (where manual review is used)

Do not copy unnecessary customer/dog PII into reports. Use booking IDs and restricted access. This sidecar schema itself requires approval before implementation.

## 5. Phased migration strategy

### Phase 0 — Governance and baseline freeze
- Approve Shared Booking Data Contract v1 field names, type semantics, date-only representation, lifecycle authority and compatibility rules.
- Confirm actual deployed Firestore Rules revision and all production booking writers/readers.
- Identify assignment operator and trusted backend owner; confirm whether any external/manual system writes bookings.
- Inventory Customer, Admin, Partner, Firebase Functions, scheduled jobs, support tools, exports and analytics consumers.
- Record a baseline snapshot of legacy field presence, type pairs, statuses, dates, pickup shapes and payment/assignment references.
- Freeze the current legacy writer/Rules contract as a documented compatibility baseline; no breaking changes.

**Exit gate:** named owners, approved schema and complete writer/reader inventory.

### Phase 1 — Read-only inventory and dry-run classification
- Read production data only through an authorized, least-privilege export/snapshot process.
- Run classification in dry-run mode; no writes to source documents.
- Produce aggregate counts by legacy type, classification, missing fields, conflicting fields and candidate mapping.
- Sample records manually with authorized Operations/Product reviewers.
- Quarantine ambiguous and unsupported records for review; do not force a canonical type.
- Record input snapshot/version, tool version, run ID, counts, per-record reason codes and errors.

**Exit gate:** classification accuracy reviewed; ambiguous records quantified; no unexplained record loss.

### Phase 2 — Read-only compatibility adapters
- Implement a shared adapter/specification that can read canonical and legacy records without changing either.
- Preserve original raw fields and unknown enum values in the in-memory/domain representation.
- Expose an explicit `legacy`/schema-version marker to consumers where needed.
- Admin and Partner must safely display legacy records and canonical records using approved mappings.
- Customer status rendering must not imply payment, confirmation or Walker assignment from legacy `status` alone.
- Partner location adapter must explicitly distinguish saved address, top-level coordinates and GeoPoint legacy location; do not assume these shapes are equivalent.
- Adapter must be tolerant of missing optional fields but fail closed for safety-critical missing fields.

**Exit gate:** unit/contract tests cover legacy fixtures, canonical fixtures, malformed documents and unknown values across Customer/Admin/Partner.

### Phase 3 — Canonical write path (backend decision required)
- Choose and approve a trusted server API/Cloud Function as the owner of canonical booking creation and lifecycle mutations.
- Customer submits customer intent/preferences only; backend validates customer, dog, pickup coordinates, active verified polygon, service configuration, schedule and idempotency.
- Backend owns canonical IDs/version, serviceZoneId, availability result, quote, payment verification, confirmation, assignment and audit events.
- Do not simply widen Firestore Rules to accept the new fields. Rules must deny client writes to trusted quote/payment/zone/confirmation/assignment fields.
- Preserve legacy client writes until the replacement path is fully implemented, tested and rollout-authorized; then switch through a controlled feature flag.
- New canonical records should be single-write through the trusted path. Do not dual-write two competing booking documents.

**Exit gate:** approved API contract, Rules emulator tests, auth tests, idempotency/concurrency tests, audit logging and end-to-end app compatibility.

### Phase 4 — Shadow reads and controlled rollout
- Read canonical and legacy records through adapters while keeping the legacy writer active until explicit cutover approval.
- Compare adapter output with current app output without changing customer-visible behavior.
- Monitor parse failures, unknown statuses, missing schedule/location fields, assignment discrepancies and latency.
- Enable canonical creation only for a controlled internal/pilot cohort after all release gates pass.
- Keep a kill switch that routes new requests back to the approved safe path; do not delete or mutate existing canonical records during rollback.
- Expand cohorts only with recorded approval and stable monitoring.

**Exit gate:** agreed error thresholds, successful regression tests, support readiness and rollback drill.

### Phase 5 — Deterministic backfill (optional; separate approval)
- Backfill only records classified `deterministic` and explicitly approved for backfill.
- Use a sidecar canonical projection or versioned migration metadata; retain the original legacy payload unchanged.
- Dry-run first; produce exact planned changes and counts for approval.
- Make each operation idempotent and checkpointed; persist per-record success/failure and retry safely.
- Use transactions/preconditions to prevent overwriting records changed after the snapshot.
- Never backfill ambiguous Regular/custom records, inferred payment states, inferred zones or inferred assignment history.
- Do not delete legacy fields during the compatibility period. Any later cleanup requires a separate retention/deletion approval.

**Exit gate:** dry-run diff approved, restore/replay tested, sampled records verified and audit evidence retained.

### Phase 6 — Cutover and deprecation
- Stop legacy writes only after all deployed app versions and external consumers are compatible with canonical records.
- Maintain legacy reads for the approved retention/compatibility window.
- Deprecate fields only after measured usage is zero or explicitly waived by owners.
- Remove adapters/legacy fields only under a separate change request, migration evidence and rollback plan.

**Exit gate:** owner sign-off from Customer, Admin, Partner, Backend, Operations and Founder; deployed-version coverage; no unresolved critical data discrepancies.

## 6. Cross-app ownership boundaries

| Domain | Authoritative owner | Client/app responsibility |
|---|---|---|
| Customer intent, dog choice, pickup preference, schedule preference | Customer submits; backend validates | Collect and display input |
| Pickup coordinates and zone resolution | Backend/location service | Capture GPS/map/search input and accuracy metadata |
| Service availability/capacity | Backend | Display result and safe retry |
| Price/quote/tax/discount policy | Approved pricing policy + backend quote service | Display server quote only |
| Payment status | Payment provider verification + backend | Initiate approved payment and display verified state |
| Booking confirmation | Backend | Render authoritative state |
| Walker assignment/acceptance | Approved assignment service/operator | Display only server-confirmed assignment |
| Walk execution/GPS events | Approved Partner walk execution contract | Capture permitted events; backend validates |
| Admin operations | Role-scoped backend authorization | Display authorized controls and audit outcomes |

## 7. Required test matrix

- Legacy fixture parsing for each known field combination and unknown enum values.
- No automatic mapping of `regular` to either Monthly Package or Daily Continuous.
- Custom dates without explicit bounds remain unclassified.
- Date-only/timezone conversion, midnight boundaries, leap years and month-end dates.
- Legacy pickup map/string, top-level coordinates and GeoPoint fixtures.
- Legacy statuses never render false paid/confirmed/assigned states.
- Customer cannot write canonical trusted fields directly.
- Admin/Partner cannot forge quote, payment, service zone or assignment authority.
- Firestore Rules emulator: legacy create/read/update regression and canonical authorization cases.
- API idempotency, duplicate requests, concurrent updates, partial failure and safe retry.
- Backfill dry-run determinism, checkpoint resume, precondition conflict and no destructive mutation.
- Customer/Admin/Partner integration tests against the same contract fixtures.
- Rollback/kill-switch exercise and monitoring alert tests.

Record commands, commit SHA, environment, test run ID, counts and actual result. An unexecuted test is **not verified**.

## 8. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Misclassifying Regular records | Preserve unclassified legacy type; manual review only |
| Losing custom date bounds | No mapping without explicit recoverable range |
| Breaking older Partner versions | Read adapters and deployed-version inventory before cutover |
| Client forging trusted state | Server-owned write path and restrictive Rules |
| Duplicate bookings during retry/dual-write | One canonical write with server idempotency |
| Incorrect zone/price/payment inference | Never infer; recompute/verify server-side |
| Partial migration or concurrent edits | Snapshot marker, preconditions, checkpoints, per-record audit |
| Rollback corrupts newer records | Non-destructive projections, no blind reverse overwrite |

## 9. Decisions still required

1. Founder/Product approval of Shared Booking Data Contract v1 and the four booking type definitions.
2. Backend decision: trusted API/Cloud Function ownership and canonical ID/idempotency design.
3. Confirm all production writers/readers, deployed Rules revision and any external assignment/payment system.
4. Confirm date-only and timezone contract; Daily Continuous month-end policy remains unresolved.
5. Confirm whether historical Regular bookings have a documented meaning; otherwise leave unclassified.
6. Confirm whether custom historical date records can reliably recover explicit start/end bounds.
7. Approve sidecar classification/backfill approach, retention window and rollback owner.
8. Approve pilot scope, monitoring thresholds and cutover authority.

## 10. Current release posture

**NO-GO for canonical production writes or migration.** The shared contract and this plan are drafts. The current legacy Customer writer and current Firestore Rules must remain unchanged until coordinated approval and implementation. No production data, Firebase Rules, runtime code, deployment or PR merge is changed by this document.

## 11. Evidence references

- Notion: POL-006 — Customer Booking & Eligibility Policy (source of truth).
- Notion: POL-011 — Pricing, Taxes & Customer Terms Policy.
- Notion: POL-005 — Booking & Walker Assignment Policy.
- GitHub: `docs/contracts/SHARED_BOOKING_DATA_CONTRACT_V1_DRAFT.md`.
- GitHub: `docs/contracts/CROSS_APP_BOOKING_COMPATIBILITY_AUDIT_V1.md`.
- GitHub: `docs/architecture/CUSTOMER_UI_STRUCTURE_AUDIT.md`.

## 12. Change history

- 2026-10-30: Initial migration/compatibility plan draft created from inspected Customer, Admin, Partner and Firebase source snapshots. No runtime or production changes.
