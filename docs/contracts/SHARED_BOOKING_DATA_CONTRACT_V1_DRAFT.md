# DOJO WALK — Shared Booking Data Contract v1 (DRAFT)

**Status:** Draft for cross-app review — NOT approved for production  
**Scope:** Customer App, Admin App, Partner App, Firebase/backend  
**Source of truth:** Notion POL-006 Customer Booking & Eligibility Policy  
**Compatibility target:** Existing legacy booking documents must remain readable.

> This document proposes a canonical contract. It does not authorize Firebase rules, Cloud Functions, payment, availability or assignment implementation. Do not migrate production writes until all app owners approve the schema and backend ownership.

## 1. Contract principles

1. One canonical booking document represents the customer's booking request/package.
2. Use stable machine IDs, not UI labels or translated strings.
3. Customer UI submits intent and preferences; server validates availability, zone, quote, payment and assignment.
4. Booking, payment, assignment and walk execution are independent state dimensions.
5. Server-generated values are authoritative. Client-calculated price, zone, eligibility or assignment must never be trusted.
6. New documents carry `schemaVersion: 1`; legacy documents are read through an adapter, not silently rewritten.
7. No Auto-Pay. Payment method/collection remains manual and subject to approved payment integration.
8. Do not expose internal service-zone selection to customers. Pickup coordinates/address are submitted; backend derives the active verified zone.

## 2. Canonical booking type IDs

| ID | Meaning | Term representation |
|---|---|---|
| `single_walk` | One individual walk | One local service date and one walk schedule |
| `temporary_booking` | Finite date-range booking | Explicit inclusive `startDate` and `endDate`, selected service dates |
| `monthly_package` | Fixed 28-day package | Inclusive end date = start date + 27 days |
| `daily_continuous` | Recurring calendar-cycle service | Start-date-anchored cycle; month-end rollover policy still requires approval |

Morning/Afternoon/Evening/Night are time-slot labels, not booking types. Extra Walk and Reschedule are operations/features, not booking types.

## 3. Proposed Firestore document

Collection: `bookings/{bookingId}`

### 3.1 Common request fields

```json
{
  "schemaVersion": 1,
  "bookingId": "server-or-client-idempotent-id",
  "bookingType": "single_walk | temporary_booking | monthly_package | daily_continuous",
  "customerId": "uid",
  "dogId": "dog-document-id",
  "pickup": {
    "addressId": "saved-address-id",
    "formattedAddress": "customer-visible address",
    "latitude": 0.0,
    "longitude": 0.0,
    "locationAccuracyMeters": 0
  },
  "serviceZoneId": null,
  "schedule": {
    "timeZone": "Asia/Kolkata",
    "startDate": "YYYY-MM-DD",
    "endDate": null,
    "selectedDates": ["YYYY-MM-DD"],
    "walksPerDay": 1,
    "walks": [
      { "slot": "morning", "preferredTime": "06:30", "durationMinutes": 30 }
    ]
  },
  "bookingStatus": "request_received",
  "paymentStatus": "not_started",
  "assignmentStatus": "not_started",
  "walkStatus": "not_started",
  "quote": null,
  "payment": null,
  "assignment": null,
  "createdAt": "server timestamp",
  "updatedAt": "server timestamp"
}
```

This is an illustrative shape, not a final Firestore schema. Nullability, coordinate precision, required fields and ID generation must be confirmed with backend/security owners.

### 3.2 Type-specific schedule rules

- `single_walk`: exactly one service date and one walk entry. Immediate/ASAP is a request preference, not a separate booking type; server resolves the valid service date/time.
- `temporary_booking`: required inclusive `startDate` and `endDate`; selected dates must be inside the range. Each selected date may have its own walk list.
- `monthly_package`: required `startDate`; `endDate = startDate + 27 calendar days` (inclusive 28-day term). Persist both dates after server validation.
- `daily_continuous`: required `startDate`, recurring schedule and a cycle rule identifier. Do not calculate/persist the next cycle until the month-end policy is approved. No Auto-Pay.

All date-only fields use ISO `YYYY-MM-DD` in the service timezone; timestamps use Firestore server timestamps. Date-only values must not be derived from a UTC timestamp without explicit timezone conversion.

## 4. Independent lifecycle state machines

### Booking status (proposed)
`request_received` → `validating` → `availability_confirmed` → `quote_ready` → `awaiting_payment` → `confirmed` → `in_service` → `completed`

Other terminal/exception states: `rejected`, `cancelled`, `expired`, `needs_assistance`.

### Payment status (proposed)
`not_started`, `quote_pending`, `awaiting_payment`, `verification_pending`, `paid`, `failed`, `refund_pending`, `partially_refunded`, `refunded`.

### Assignment status (proposed)
`not_started`, `searching`, `assigned`, `walker_unavailable`, `manager_escalation`, `central_escalation`, `reassigned`, `cancelled`.

### Walk status (proposed)
`not_started`, `scheduled`, `walker_en_route`, `checked_in`, `in_progress`, `completed`, `interrupted`, `emergency_handover`.

These are separate dimensions. A booking must not be labelled `confirmed` merely because a request document exists. Walker Assigned is shown only after trusted backend acceptance/assignment confirmation.

## 5. Server-owned fields

The backend owns and validates:
- `serviceZoneId` and zone eligibility from the active verified polygon.
- availability decision and capacity reservation/expiry.
- quote amount, currency, taxes, discounts (if policy permits), quote ID/version/expiry.
- payment verification and payment reference.
- final booking status and timestamps.
- Walker assignment, acceptance and reassignment events.
- cancellation/refund decisions and audit trail.

Customer may submit preferences and a payment initiation request only through approved endpoints. Client must not write trusted quote, paid status, confirmed status, assigned Walker or server eligibility fields.

## 6. Quote and payment envelope (proposed)

```json
{
  "quote": {
    "quoteId": "server-generated",
    "currency": "INR",
    "totalMinorUnits": 0,
    "pricingPolicyVersion": "approved-version",
    "expiresAt": "server timestamp"
  },
  "payment": {
    "provider": "approved-provider",
    "providerOrderId": "server-generated",
    "status": "awaiting_payment",
    "verifiedAt": null
  }
}
```

No price should be invented or hard-coded. The server quote is authoritative. Payment confirmation must come from trusted provider/server verification, not a client callback alone.

## 7. Idempotency, concurrency and audit

- Every create/confirm/payment/assignment mutation needs an idempotency key and server-side deduplication.
- Availability must be revalidated/held atomically before quote/payment; quote expiry must release or revalidate capacity.
- State transitions must be validated server-side; clients cannot move lifecycle states directly.
- Record actor, action, previous state, new state, timestamp and reason in an append-only audit/event record.
- Retries must return the original operation result where the idempotency key matches.
- Avoid storing sensitive payment credentials or unnecessary personal data in booking documents.

## 8. Legacy compatibility adapter

Current Customer legacy values observed:
- enum: `oneTime`, `regular`, `chooseDates`.
- `bookingPlan`: `one_time`, `regular`, `customize`.
- `serviceType`: `temporary_walk`, `regular_walk`, `custom_walk`.
- schedule keys: `isImmediate`, `isRegular`, `isChooseDates`, `frequency`, `walksPerWeek`, `walkCount`, `walks`, `selectedDates`, `dateSchedules`.
- existing Customer flow writes directly to `bookings`, with `status: pending` and `walkerId: null`.

Proposed read-only mapping for legacy records:
- `oneTime` / `one_time` → candidate `single_walk` (confirm legacy immediate semantics).
- `regular` / `regular` → ambiguous between `monthly_package` and `daily_continuous`; do NOT auto-map until historical product meaning is reconciled.
- `chooseDates` / `customize` → candidate `temporary_booking` only when explicit date bounds can be reconstructed; otherwise preserve as `legacy_custom_dates`.
- Preserve original fields and raw document. Never backfill an uncertain canonical type automatically.

## 9. API surface (proposal only)

- `POST /v1/bookings/validate`: validate request shape, dog, pickup, service zone, service hours and eligibility.
- `POST /v1/bookings/availability`: obtain availability/capacity result and reservation token.
- `POST /v1/quotes`: create server-authoritative quote with expiry and policy version.
- `POST /v1/payments/initiate`: create provider order from a valid quote.
- `POST /v1/payments/webhook`: trusted provider verification; idempotent.
- `POST /v1/bookings/confirm`: confirm only after valid availability and verified payment where payment is required.
- `GET /v1/bookings/{bookingId}`: return canonical lifecycle view.
- `POST /v1/bookings/{bookingId}/cancel`: policy-based cancellation request.

Endpoint names and transport (callable Functions/HTTP) are not approved. Firebase implementation is out of scope for this draft.

## 10. Decisions required before approval

1. Daily Continuous month-end cycle rule for start dates 29/30/31.
2. Exact Temporary Booking date-selection model and whether non-consecutive service dates are supported.
3. Monthly Package weekly-payment eligibility and any manual collection cadence.
4. Single Walk immediate/ASAP behavior and whether date is mandatory.
5. Exact service timezone source and date-only serialization rules across apps.
6. Booking ID generation and idempotency-key ownership.
7. API transport, response/error envelope, quote expiry and capacity hold duration.
8. Canonical status names and transition authority.
9. Legacy `regular` and `chooseDates` document migration/read adapter behavior.
10. Pickup coordinate requirements, GPS accuracy threshold and verified-zone lookup ownership.

## 11. Approval and release gates

- Product/Founder approval of booking semantics and unresolved decisions.
- Backend approval of schema, endpoint contracts, security rules and state transitions.
- Customer, Admin and Partner owners approve shared field names and compatibility behavior.
- Contract examples and JSON schema tests added to a shared contract test suite.
- Emulator/integration tests verify authorization, idempotency, concurrency, payment verification and legacy reads.
- Only then implement server APIs and switch Customer writes away from direct trusted-field Firestore writes.

**Current status:** Draft only. No production schema change, no Firebase/backend change, no data migration, and no app implementation from this document.
