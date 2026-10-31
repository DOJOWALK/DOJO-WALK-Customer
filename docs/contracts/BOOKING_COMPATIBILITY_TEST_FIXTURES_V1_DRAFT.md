# DOJO WALK — Booking Compatibility Test Fixtures & Adapter Specification v1

**Status:** DRAFT — CONTRACT REVIEW ONLY — NOT IMPLEMENTED  
**Date:** 2026-10-30  
**Target:** Customer / Admin / Partner / Firebase booking compatibility  
**Depends on:** Shared Booking Data Contract v1 draft; Cross-App Booking Compatibility Audit v1; Legacy Booking Migration Compatibility Plan v1.

> All IDs, names, addresses, dates and values below are synthetic test data. The legacy fixtures are shaped from the currently inspected Customer writer and Firebase `validBookingBase` rules. They are not production documents and have not been executed in the Firebase Emulator. Server timestamp placeholders must be replaced by test SDK timestamp sentinels when running rules tests.

## 1. Purpose

Create one shared fixture vocabulary so all three apps interpret the same booking document consistently. The first implementation target is a read-only adapter. Fixtures must preserve legacy evidence and must never manufacture trusted booking, payment, zone or assignment state.

## 2. Legacy fixture baseline

The inspected Firebase Rules require the following common legacy fields: `bookingId`, `customerId`, `walkType`, `bookingPlan`, `serviceType`, `serviceName`, `petName`, `dogId`, `petDetails`, `pickupAddressId`, `pickupAddress`, `scheduledAt`, `duration`, `preferredTime`, `status`, `walkerId`, `cancelRequest`, `createdAt`, `walkCount`, and `walkSchedules`. The allowlist additionally permits the regular/custom fields listed below.

### 2.1 Legacy one-time fixture — candidate Single Walk

```json
{
  "bookingId": "fixture_single_001",
  "customerId": "customer_fixture_001",
  "walkType": "scheduled",
  "bookingPlan": "one_time",
  "serviceType": "temporary_walk",
  "serviceName": "Dog Walk",
  "petName": "Milo",
  "dogId": "dog_fixture_001",
  "petDetails": {"name": "Milo", "size": "Medium"},
  "pickupAddressId": "address_fixture_001",
  "pickupAddress": {"address": "Test Street", "city": "Noida"},
  "scheduledAt": "TEST_TIMESTAMP",
  "duration": "30 minutes",
  "preferredTime": "06:30",
  "status": "pending",
  "walkerId": null,
  "cancelRequest": null,
  "createdAt": "SERVER_TIMESTAMP",
  "walkCount": 1,
  "walkSchedules": [{"time": "06:30", "duration": "30 minutes"}]
}
```

Expected adapter result: `sourceSchema=legacy`, `classification=needs_review` until immediate-vs-scheduled semantics and one-date/one-walk evidence are checked; candidate type may be `single_walk`. Do not render confirmed, paid or assigned.

### 2.2 Legacy regular fixture — deliberately ambiguous

```json
{
  "bookingId": "fixture_regular_001",
  "customerId": "customer_fixture_001",
  "walkType": "scheduled",
  "bookingPlan": "regular",
  "serviceType": "regular_walk",
  "serviceName": "Regular Dog Walk",
  "petName": "Milo",
  "dogId": "dog_fixture_001",
  "petDetails": {"name": "Milo", "size": "Medium"},
  "pickupAddressId": "address_fixture_001",
  "pickupAddress": {"address": "Test Street", "city": "Noida"},
  "scheduledAt": "TEST_TIMESTAMP",
  "duration": "30 minutes",
  "preferredTime": "06:30",
  "status": "pending",
  "walkerId": null,
  "cancelRequest": null,
  "createdAt": "SERVER_TIMESTAMP",
  "walkCount": 1,
  "walkSchedules": [{"time": "06:30", "duration": "30 minutes"}],
  "frequency": "daily",
  "walksPerWeek": 7,
  "walksPerDay": 1,
  "planStatus": "pending_confirmation",
  "dailyWalkTemplate": [{"time": "06:30", "duration": "30 minutes"}]
}
```

Expected adapter result: `classification=needs_review`, legacy semantic `legacy_regular_unclassified`, canonical `bookingType=null`. It must NOT be guessed as `monthly_package` or `daily_continuous`. The current rule's daily frequency and seven walks/week do not define a package term or billing cadence.

### 2.3 Legacy custom-date fixture — range bounds absent

```json
{
  "bookingId": "fixture_custom_001",
  "customerId": "customer_fixture_001",
  "walkType": "scheduled",
  "bookingPlan": "customize",
  "serviceType": "custom_walk",
  "serviceName": "Custom Dog Walk",
  "petName": "Milo",
  "dogId": "dog_fixture_001",
  "petDetails": {"name": "Milo", "size": "Medium"},
  "pickupAddressId": "address_fixture_001",
  "pickupAddress": {"address": "Test Street", "city": "Noida"},
  "scheduledAt": "TEST_TIMESTAMP",
  "duration": "30 minutes",
  "preferredTime": "06:30",
  "status": "pending",
  "walkerId": null,
  "cancelRequest": null,
  "createdAt": "SERVER_TIMESTAMP",
  "walkCount": 1,
  "walkSchedules": [{"time": "06:30", "duration": "30 minutes"}],
  "walksPerDay": 1,
  "selectedDates": ["2026-11-02", "2026-11-04"],
  "dateSchedules": [
    {"date": "2026-11-02", "walks": [{"time": "06:30", "duration": "30 minutes"}]},
    {"date": "2026-11-04", "walks": [{"time": "06:30", "duration": "30 minutes"}]}
  ]
}
```

Expected adapter result: `classification=needs_review`, legacy semantic `legacy_custom_dates`, canonical `bookingType=null` unless explicit inclusive range bounds can be deterministically recovered from trusted source evidence. Selected dates alone are not a range.

### 2.4 Malformed/unknown fixture

Create variants from the above by testing: missing required `dogId`; unknown `bookingPlan`; mismatched `bookingPlan/serviceType`; missing `dateSchedules`; selected/date schedule count mismatch; `walkCount=0`; `walkCount=4`; client-supplied unknown extra keys; invalid timestamp; non-null `walkerId` with pending state.

Expected adapter result: preserve raw input, return structured validation issues, classify `unsupported` or `needs_review`; never silently normalize a malformed source into a valid canonical booking.

## 3. Canonical fixture — proposed only

This shape illustrates the v1 contract and is **not accepted by the inspected current Firebase legacy create rules**. It must be used only in pure adapter/unit fixtures until backend and Rules approve the canonical schema.

```json
{
  "schemaVersion": 1,
  "bookingId": "fixture_v1_single_001",
  "bookingType": "single_walk",
  "customerId": "customer_fixture_001",
  "dogId": "dog_fixture_001",
  "pickup": {
    "addressId": "address_fixture_001",
    "formattedAddress": "Synthetic test address",
    "latitude": 28.0001,
    "longitude": 77.0001,
    "locationAccuracyMeters": 12
  },
  "serviceZoneId": null,
  "schedule": {
    "timeZone": "Asia/Kolkata",
    "startDate": "2026-11-02",
    "endDate": null,
    "selectedDates": ["2026-11-02"],
    "walksPerDay": 1,
    "walks": [{"slot": "morning", "preferredTime": "06:30", "durationMinutes": 30}]
  },
  "bookingStatus": "request_received",
  "paymentStatus": "not_started",
  "assignmentStatus": "not_started",
  "walkStatus": "not_started",
  "quote": null,
  "payment": null,
  "assignment": null
}
```

Expected adapter result: `sourceSchema=canonical`, `classification=already_canonical` only if schema version, required fields, IDs and type-specific invariants validate. Null `serviceZoneId` does not mean eligible or outside-zone; it means no authoritative zone result is present.

## 4. Proposed normalized read model

This is an in-memory/domain projection, not a Firestore write schema:

```json
{
  "source": {
    "schema": "legacy",
    "bookingId": "fixture_regular_001",
    "raw": {"bookingPlan": "regular", "serviceType": "regular_walk"}
  },
  "classification": {
    "status": "needs_review",
    "reasonCodes": ["LEGACY_REGULAR_SEMANTICS_AMBIGUOUS"],
    "candidateBookingType": null
  },
  "identity": {
    "customerId": "customer_fixture_001",
    "dogId": "dog_fixture_001"
  },
  "schedule": {
    "startDate": null,
    "endDate": null,
    "selectedDates": [],
    "timeZone": null,
    "legacyScheduleAvailable": true
  },
  "location": {
    "addressReference": "address_fixture_001",
    "coordinatesAvailable": false,
    "serviceZoneId": null,
    "zoneEligibility": "unknown"
  },
  "lifecycle": {
    "bookingStatus": "unknown",
    "paymentStatus": "unknown",
    "assignmentStatus": "unknown",
    "walkStatus": "unknown"
  },
  "display": {
    "canShowConfirmed": false,
    "canShowPaid": false,
    "canShowWalkerAssigned": false
  },
  "issues": ["LEGACY_REGULAR_SEMANTICS_AMBIGUOUS"]
}
```

Adapter must keep the complete raw source separately (or a safe immutable reference to it) and must not overwrite source values with normalized labels. The lifecycle mapping above is intentionally conservative; a future approved mapping table must define each supported legacy state with evidence.

## 5. Adapter API proposal

Conceptual interface only; language/package is to be selected by the cross-app owners:

- `classifyBookingDocument(rawDocument, sourceId)` → schema detection + classification + reason codes.
- `parseLegacyBooking(rawDocument)` → lossless legacy view; unknown values preserved.
- `parseCanonicalBooking(rawDocument)` → validated v1 view; unsupported schema version returns explicit issue.
- `toBookingReadModel(parsedDocument)` → normalized read projection, no persistence.
- `canDisplayConfirmed(readModel)`, `canDisplayPaid(readModel)`, `canDisplayAssigned(readModel)` → false unless explicit authoritative evidence exists.
- `serializeCanonicalBooking(...)` is out of scope for this read-adapter phase and must not be implemented from this draft alone.

Error handling:
- Missing non-critical optional field: null/unknown plus warning.
- Missing safety-critical field: block the relevant action and return an explicit issue.
- Unknown enum/status: preserve raw value; display a neutral “Status needs review” state, not a guessed state.
- Malformed document: return parse failure plus source reference; do not crash list screens or silently drop the record.

## 6. Cross-app rendering contract

### Customer
- Display only customer-owned bookings.
- Legacy `pending` must not imply quote ready, payment received, confirmed or Walker assigned.
- Provide neutral pending/review language when exact lifecycle cannot be established.
- Never display a customer-selectable service zone; no zone result means zone status is unknown.

### Admin
- Show source schema, raw legacy state, normalized display state and classification/reason code to authorized operations roles.
- Distinguish “legacy walkerId present” from “assignment verified”.
- Do not expose a manual assignment action based solely on this read adapter.

### Partner
- Only show work under the existing authorized assignment query/access contract.
- Distinguish an assigned legacy record from a newly offered/accepted canonical assignment.
- Do not interpret a missing nested canonical pickup object as a valid GPS location; legacy address, top-level coordinates and GeoPoint must remain separate typed source variants.
- No new lifecycle write is defined by this document.

## 7. Shared fixture test matrix

| Fixture | Expected classification | Expected canonical type | Critical assertion |
|---|---|---|---|
| Legacy one-time, all evidence consistent | needs_review until semantics checked | candidate single_walk | no false confirmation/payment/assignment |
| Legacy regular | needs_review | null | never infer monthly/daily continuous |
| Legacy custom dates without bounds | needs_review | null | selected dates are not range bounds |
| Legacy custom with trusted explicit bounds in separate evidence | deterministic only after review | temporary_booking candidate | all dates inside inclusive bounds |
| Canonical v1 single walk valid | already_canonical | single_walk | v1 validation only; current Rules still reject writes |
| Unknown schemaVersion | unsupported | null | preserve source and surface issue |
| Unknown status enum | needs_review | unchanged/unknown | do not map by string similarity |
| Legacy non-null walkerId | needs_review until authoritative history | null/known type only | no “Walker assigned” claim from ID alone |
| Missing GPS coordinates | source-dependent | no type implication | zone eligibility remains unknown |
| Price/payment metadata only | source-dependent | no type implication | no paid state inference |

## 8. Firebase Emulator test plan (not run)

Use isolated emulator fixtures and authenticated identities for customer A, customer B, approved Walker, inactive Walker and active super_admin.

1. Legacy one-time fixture satisfying current `validBookingBase` and `validOneTimeBooking` can be created only by its owning customer, with `createdAt` matching server request time.
2. Legacy regular fixture satisfying `validRegularBooking` is accepted under current rules; adapter still classifies its product meaning as ambiguous.
3. Legacy custom fixture satisfying `validCustomBooking` is accepted; absence of explicit range bounds remains a migration ambiguity.
4. Unknown extra key and canonical v1-only fields are rejected by the current fixed allowlist.
5. Customer B cannot read Customer A's booking.
6. Unapproved/inactive Walker cannot read assigned booking.
7. Customer cannot update trusted price/payment/assignment/status fields.
8. Admin and Partner update permissions are tested against their exact allowlists and role predicates.
9. Test `walkCount` boundaries 1 and 3 accepted where type-specific rules pass; 0 and 4 rejected.
10. Verify `selectedDates` and `dateSchedules` count mismatch is rejected.
11. Verify unknown lifecycle status is preserved by adapter and never presented as confirmed/paid/assigned.
12. Retry test confirms adapter is pure/read-only and causes no writes or duplicate records.

**Execution status:** Not run. No emulator command, run ID or PASS evidence is available in this change.

## 9. Approval and implementation gates

- [ ] Backend owner approves canonical schema and trusted write ownership.
- [ ] Firebase owner approves Rules design and emulator coverage.
- [ ] Customer owner approves legacy input compatibility.
- [ ] Admin owner approves operations display/classification.
- [ ] Partner owner approves assignment and location read compatibility.
- [ ] Founder/Product approves booking type semantics and lifecycle wording.
- [ ] Security/Privacy approves fixture data handling and operational access.
- [ ] Shared fixtures are added to executable tests and actually run in CI.

## 10. Current status and change history

**NO-GO for runtime adapter, canonical writes or Rules changes based on this draft alone.** Documentation only. No source code, Firebase Rules, production data, deployment or merge changed.

- 2026-10-30: Initial fixture catalog and read-adapter specification drafted from inspected source snapshots.
