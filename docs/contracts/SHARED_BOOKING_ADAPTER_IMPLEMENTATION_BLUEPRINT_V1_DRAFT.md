# DOJO WALK — Shared Booking Adapter Implementation Blueprint v1

**Status:** DRAFT — ARCHITECTURE REVIEW ONLY — NOT IMPLEMENTED  
**Date:** 2026-10-30  
**Target:** Customer / Admin / Partner / Firebase booking compatibility  
**Depends on:** Shared Booking Data Contract v1 Draft; Cross-App Booking Compatibility Audit v1; Legacy Booking Migration Compatibility Plan v1 Draft; Booking Compatibility Test Fixtures v1 Draft.

> This blueprint defines a safe read-only compatibility architecture. It does not authorize runtime code, Firestore writes, Rules changes, data migration, assignment changes, payment changes, deployment or PR merge.

## 1. Decision summary

Adopt a **shared, language-neutral contract and fixture suite first**, with app-local read adapters only after the contract is approved. Do not assume a shared Dart package or a new repository exists. The same versioned fixtures and expected classifications must be used by Customer, Admin and Partner adapter tests.

The adapter is a read projection only. It must preserve source evidence, classify legacy/unknown documents conservatively, and never create trusted booking, payment, service-zone, assignment or walk state.

**Recommended first implementation gate:** approve the contract vocabulary, schema detection rules, status mapping table and fixture expectations across the four system owners. Only then implement a pure read adapter in an agreed location.

## 2. Architecture boundaries

### 2.1 Source of truth

- Firebase/backend remains authoritative for persisted booking data and trusted lifecycle transitions.
- The approved shared booking contract defines cross-app meaning, field names, allowed enums and compatibility expectations.
- Shared JSON fixtures define portable test inputs and expected outputs.
- Each app adapter converts source documents into an in-memory read model for its own UI.
- UI components render the read model; they do not reinterpret legacy fields independently.
- Adapter output is never written back to Firestore and is never accepted as proof of server authorization.

### 2.2 Logical flow

```text
Firebase booking document
        |
        v
Schema detector + source validator
        |
        +--> Canonical v1 parser (only approved schema versions)
        |
        +--> Legacy parser (known legacy shapes)
        |
        +--> Unknown / malformed result (preserve evidence)
        |
        v
Lossless parsed source + classification + issue codes
        |
        v
Normalized read-only BookingReadModel
        |
        +--> Customer presentation adapter
        +--> Admin operations presentation adapter
        +--> Partner work presentation adapter
```

No presentation adapter may upgrade an unknown state into a trusted state. No adapter performs assignment, payment verification, zone eligibility checks or lifecycle writes.

## 3. Schema detection and classification

Detection order must be deterministic:

1. If `schemaVersion` is present, parse only through the parser registered for that exact supported version. An unknown version returns `unsupported_schema_version`; do not fall back to legacy based on coincidental fields.
2. If `schemaVersion` is absent and the recognized legacy discriminator pair is present, classify as legacy and validate its exact shape.
3. If neither condition matches, return `unknown_schema` with raw source preserved.
4. If canonical markers conflict with legacy markers, return `schema_conflict`; do not choose whichever parser succeeds first.

Suggested classification values:

- `already_canonical` — supported canonical schema passes all required invariants.
- `legacy_supported` — known legacy shape can be safely represented without claiming canonical product semantics.
- `needs_review` — ambiguous semantics, missing critical evidence or conflicting fields.
- `unsupported` — unknown schema version or unsupported document shape.
- `malformed` — structural/type validation failure.

Classification is not a booking lifecycle status and must be displayed separately.

## 4. Legacy mapping policy

| Observed legacy discriminator | Adapter interpretation | Canonical mapping |
|---|---|---|
| `one_time` + `temporary_walk` | Candidate single/one-time legacy record; verify immediate vs scheduled and exactly-one-walk semantics | Candidate `single_walk` only after approved mapping evidence |
| `regular` + `regular_walk` | `legacy_regular_unclassified` | None; never guess Monthly Package or Daily Continuous |
| `customize` + `custom_walk` | `legacy_custom_dates`; inspect dates and schedules | Candidate `temporary_booking` only when trusted inclusive start/end bounds are explicit and recoverable |
| Unknown or mismatched pair | `legacy_unknown_or_conflicting` | None |

Rules:

- `frequency=daily`, `walksPerWeek=7` and `dailyWalkTemplate` do not establish a 28-day Monthly Package or calendar-based Daily Continuous term.
- A list of selected dates is not proof of an inclusive date range.
- Never infer a booking type from display labels, service name, price, amount or a UI route.
- Preserve unknown discriminator values exactly.
- Mapping tables require Product/Founder and Backend approval before being treated as normative.

## 5. Normalized read model

The proposed model is an in-memory projection, not a Firestore schema:

- `sourceRef`: repository/document reference and source schema label.
- `rawSource`: immutable raw document snapshot or protected reference; do not log it.
- `classification`: classification enum, reason codes, parser version.
- `identity`: booking/customer/dog identifiers where validated.
- `bookingType`: canonical type only when proven; otherwise null.
- `legacySemantics`: preserved legacy discriminator values.
- `schedule`: canonical dates only when explicit and validated; otherwise typed legacy schedule evidence.
- `pickup`: separate variants for address reference, address text/map, top-level coordinates and GeoPoint source. Do not collapse unlike shapes.
- `serviceZone`: authoritative zone result and boundary/catalogue version only when supplied by trusted backend evidence; otherwise unknown.
- `lifecycle`: independent booking, payment, assignment and walk states, each with raw source value and mapping evidence.
- `quote`: trusted quote reference/value/status only when returned by an authoritative source.
- `issues`: stable machine-readable reason codes and severity.
- `displayCapabilities`: conservative booleans derived from verified evidence, never from UI assumptions.

The complete raw source must remain recoverable for authorized diagnostics, subject to retention and privacy controls. Avoid copying unnecessary PII into logs, analytics or crash reports.

## 6. Lifecycle mapping and fail-closed rules

Booking, payment, assignment and walk execution are separate state machines. A raw legacy `status` string must not be copied into all four.

Until a reviewed mapping table exists:

- Unknown legacy status → normalized state `unknown`; preserve raw value.
- Legacy `pending` → does not mean quote ready, paid, confirmed, assigned or walk started.
- Non-null `walkerId` → evidence that an ID is present only; it is not by itself proof of an eligible, accepted, current assignment.
- Price/amount fields → not proof of payment.
- Payment provider reference → not proof of captured/settled payment without trusted verification.
- Walk completion labels → not proof that required GPS, safety and handover records are complete.

Safety-critical missing or conflicting evidence must block the corresponding action and show a review/unavailable state. It must not crash list screens or silently discard the booking.

## 7. Pickup and service-zone representation

Preserve each observed source shape independently:

1. Address reference and formatted address.
2. Legacy top-level latitude/longitude.
3. Legacy GeoPoint under `location`.
4. Canonical nested pickup object, only for an approved canonical version.

Do not assume an address string is geocoded, or that coordinates from different fields are equivalent. Validate coordinate ranges and accuracy metadata before any location-dependent action.

The adapter must never derive an authoritative service zone from customer text or a client-side map. The backend must resolve pickup against the active, verified zone polygon. Customer UI must not expose a service-zone selector. If no trusted zone decision is present, show eligibility as unknown/pending validation.

## 8. App responsibilities

### Customer app

- Read only bookings authorized for the signed-in customer.
- Render neutral, localized status text based on the read model and its evidence.
- Keep request received, availability checking, payment, confirmation and Walker assignment distinct.
- Do not show paid/confirmed/assigned claims without trusted state.
- Do not show a zone selector; pickup is selected by GPS, address search, map pin or saved address, then resolved by backend.

### Admin app

- Show classification, source schema, raw legacy status and normalized display status to authorized roles.
- Make ambiguous records discoverable for controlled review.
- Keep the adapter read-only; it does not create an assignment action or expand role permissions.
- Assignment must remain a separately approved trusted workflow with eligibility, atomicity, audit and authorization controls.

### Partner app

- Continue to rely on the approved assignment/access query, not on client-side inference from arbitrary booking records.
- Distinguish legacy assigned records from a canonical offer/acceptance workflow.
- Do not interpret a missing canonical pickup object as valid navigation coordinates.
- Adapter does not accept offers, update booking lifecycle or start/complete walks.

### Firebase/backend

- Own canonical writes, schema validation, quote/payment verification, zone resolution, assignment and lifecycle transitions.
- Keep existing legacy create/read/update behavior until a tested migration plan authorizes change.
- Review current broad Admin update permissions before enabling any new trusted assignment endpoint.
- Do not accept app-generated normalized read models as write payloads.

## 9. Shared contract and package strategy

No shared package or dedicated contract repository has been verified as existing. Do not create a dependency or repo by assumption.

Recommended staged strategy:

**Stage A — Portable contract artifacts**
- Maintain the approved contract, JSON fixtures and expected adapter outcomes in version control.
- Assign an explicit semantic version and change log.
- Require all app owners to review changes to field meanings, enums and compatibility expectations.
- Keep synthetic fixtures free of real customer or Walker data.

**Stage B — App-local pure adapters**
- Each app implements a thin parser/projection in its native architecture.
- All implementations run the exact same portable fixtures and assert equivalent normalized outcomes.
- Mapping logic must not be copied into screens or scattered across repositories.
- Adapter versions and supported schema versions must be visible in diagnostics.

**Stage C — Shared package decision**
Evaluate only after Stage A/B evidence:
- A versioned shared Dart package, if all participating apps use compatible Dart/Flutter tooling and release governance.
- A dedicated contract repository/package, if multiple languages or backend consumers need the same schema.
- Generated models from an approved language-neutral schema, if generation can be reproducible and CI-enforced.

Select one option through an architecture decision record. Do not introduce a package solely to avoid agreeing on the contract.

## 10. Fixture and test requirements

Every app adapter must consume the same fixture set and assert:

- Schema detection and conflict handling.
- Legacy one-time candidate remains untrusted until semantics are approved.
- Legacy regular remains unclassified.
- Legacy custom dates without explicit bounds remain unmapped.
- Unknown schema version and unknown enum are preserved.
- Missing or malformed safety-critical fields fail closed.
- Non-null walkerId does not automatically become confirmed assignment.
- Price/payment fields do not create paid state.
- Pickup variants remain distinct and no zone is inferred.
- Parsing is deterministic and side-effect-free.
- PII is not emitted in logs or analytics.

Test layers:

1. Pure parser/unit tests in each app.
2. Cross-app fixture parity tests.
3. Firebase Emulator Rules tests for existing and future schemas.
4. Contract compatibility tests for backend API responses.
5. Widget tests for unknown/review/loading/error states.
6. Integration tests for authorized Customer/Admin/Partner reads.
7. Regression tests against a frozen synthetic legacy corpus.

No test should be marked passed until the command, commit, environment, run identifier and actual result are recorded.

## 11. Performance, pagination, caching and privacy

- Parse only documents already returned by an authorized query; do not widen reads for adapter convenience.
- Keep list rendering bounded and avoid repeated parsing on every widget rebuild; cache projections only within a safe, invalidatable scope.
- Never let a cache override updated server data or permission changes.
- Do not cache sensitive raw documents longer than required; clear user-scoped caches on sign-out/account switch.
- Avoid logging full raw documents, addresses, coordinates, contact details, dog safety notes or payment references.
- Record only non-sensitive reason codes, parser version and aggregate metrics where approved.
- Preserve Firestore pagination and query limits; adapter must not load the full collection to classify records.

## 12. Implementation sequence after approval

1. Product/Founder approves booking semantics and customer-facing lifecycle language.
2. Backend/Firebase approves canonical schema, schema versioning and trusted write ownership.
3. Customer/Admin/Partner owners approve read responsibilities and legacy compatibility.
4. Security/Privacy approves raw-source handling, access boundaries, logging and retention.
5. Publish versioned portable fixtures and expected results.
6. Implement one pure adapter behind tests in an agreed repository/package; no Firestore writes.
7. Run identical fixture parity tests in all three apps.
8. Run Firebase Emulator Rules and API contract tests against approved backend changes.
9. Add UI rendering for review/unknown states without changing trusted lifecycle behavior.
10. Pilot read-only behind a controlled feature flag; compare results and monitor discrepancies.
11. Only after a separate approved migration/cutover plan may canonical writes or data migration be considered.

## 13. Explicit decisions still required

- [ ] Confirm canonical schema version and required-field invariants.
- [ ] Approve exact legacy status-to-lifecycle mapping table.
- [ ] Decide whether and how legacy `walkerId` can be verified against assignment history.
- [ ] Approve one-time semantics and immediate-vs-scheduled mapping.
- [ ] Decide whether custom date range bounds can be recovered from any trusted source.
- [ ] Approve pickup coordinate source precedence and accuracy requirements.
- [ ] Approve backend-owned service-zone result structure and versioning.
- [ ] Choose portable contract repository/package ownership.
- [ ] Approve privacy, diagnostics, retention and cache limits.
- [ ] Assign Customer, Admin, Partner, Backend and Security reviewers.

## 14. Release gate

**NO-GO** for runtime adapter implementation, canonical Firestore writes, Rules changes, backfill, assignment changes, payment changes, production rollout or PR merge until the decisions above are approved and the relevant automated tests are executed with recorded evidence.

This blueprint is documentation only. It is not a declaration that any adapter, backend endpoint, Rules change or cross-app migration exists.
