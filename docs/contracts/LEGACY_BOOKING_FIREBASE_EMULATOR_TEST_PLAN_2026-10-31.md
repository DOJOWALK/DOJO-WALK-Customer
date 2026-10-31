# DOJO WALK — Legacy Booking Fixtures & Firebase Emulator Test Plan

**Date:** 2026-10-31  
**Status:** Draft test plan; NOT executed.  
**Owner boundary:** Customer branch contains test documentation only. Firebase repository and backend remain untouched.

## Objective

Convert the source comparison into a repeatable Firebase Emulator test suite for the three legacy booking shapes currently written by Customer:
1. One-Time Walk (`one_time`)
2. Regular Daily Walk (`regular`)
3. Choose Dates (`customize`)

This plan deliberately does not implement or authorize the canonical Monthly Package contract.

## Inputs and source-of-truth evidence

- Customer writer: `lib/features/booking/screens/booking_confirmation_screen.dart`.
- Firebase Rules: `firestore.rules` on Firebase `main`.
- Booking helpers inspected: `validBookingBase`, `validBookingDuration`, `validPickupCoordinates`, `validWalkScheduleItem`, `validWalkScheduleList`, `validOneTimeBooking`, `validRegularBooking`, `validCustomBooking`.
- Synthetic fixture templates: `docs/contracts/fixtures/legacy-firestore-booking-create-fixtures-draft.json`.

## Emulator suite structure (proposal only)

Create the test suite in the Firebase repository only after Backend/Firebase owner authorizes work:
- `tests/firestore/bookings.create.rules.test.ts` — Rules Unit Testing suite.
- `tests/firestore/fixtures/legacy-booking-create-fixtures.ts` — fixture builders with Firestore Timestamp and serverTimestamp conversion.
- Use `@firebase/rules-unit-testing` with the Firestore Emulator and the exact current `firestore.rules`.
- Run tests against a clean emulator database; do not use production Firebase credentials or production data.
- Authenticated customer context: `customer_fixture_001`; unauthenticated context for denied-write test; optionally another customer UID for ownership mismatch.
- Set document path to `bookings/{payload.bookingId}`.
- For each positive fixture, use real `Timestamp.fromDate(...)` for `scheduledAt`, and `serverTimestamp()` for `createdAt`. Resolve the server timestamp through the Emulator Rules evaluation; do not substitute a client clock timestamp.

## Positive tests — expected allow

| Test ID | Fixture | Assertion |
|---|---|---|
| P01 | one_time | Authenticated owner can create a valid one-time record |
| P02 | regular_daily | Authenticated owner can create a valid daily recurring template |
| P03 | choose_dates | Authenticated owner can create a valid selected-date/custom record |
| P04 | valid coordinates | Both latitude and longitude within legal ranges are accepted |
| P05 | absent coordinates | Both coordinates absent are accepted by the current helper |
| P06 | null coordinate pair | Both coordinates null are accepted by the current helper |
| P07 | duration boundaries | 20 and 60 minutes accepted; schedule item duration uses integer 20–60 |

## Negative tests — expected deny

Run every mutation in the companion JSON fixture file:
- Document ID mismatch and wrong customer UID.
- Unauthenticated create.
- Any unknown key, including canonical draft fields (`schemaVersion`, `bookingType`, `schedule`, `startDate`, `endDate`).
- Duration below 20 or above 60.
- Walk item duration below 20 or above 60; invalid/empty time; malformed schedule list.
- Latitude-only or longitude-only coordinate pair; out-of-range coordinates.
- `walkCount` mismatch or values outside 1–3.
- Invalid plan/service pairing.
- Regular payload missing daily template, wrong frequency, wrong walksPerWeek, invalid walksPerDay, or forbidden custom-only fields.
- Custom payload missing selectedDates/dateSchedules, count mismatch, or forbidden regular-only fields.
- Wrong initial status, non-null walkerId, non-null cancelRequest, invalid createdAt, or missing required base fields.

## Known coverage gaps — do not misinterpret

1. Current Rules do **not** prove custom selectedDates uniqueness, date order, dateSchedules-to-selectedDates value equality, calendar-monthly boundaries, or month-end handling.
2. Current `regular` is a daily recurring template, not a calendar-monthly subscription/package.
3. Current Rules have no canonical `monthly_package` positive case. A canonical payload should currently be denied because canonical keys are outside `keys().hasOnly(...)`.
4. Rules tests do not prove availability, service-zone eligibility, quote calculation, payment, walker assignment, idempotency, or the real customer flow.
5. Rules helper inspection suggests both coordinates absent is allowed. Product may require a stricter GPS/address policy, but changing that is a separate approval and Rules task.
6. Test suite must load the exact deployed-intended Rules file and record its Git commit SHA to avoid testing a stale copy.

## Execution and evidence gate

Before implementation:
- Backend/Firebase owner explicitly approves the Firebase repository test-only change.
- Confirm the exact Rules branch/commit to test.
- Confirm emulator config and supported Node/package versions.
- Do not change Rules, Functions, Firestore data, indexes, deployment, or Customer runtime code as part of test-only setup.

After implementation:
- Run the full booking Rules suite in Emulator.
- Capture test command, commit SHA, total tests, pass/fail counts, and logs.
- Run existing Firebase test suite to detect regressions.
- Have Customer owner review all three positive fixtures against the live Customer writer.
- Only then report compatibility status as Emulator-verified.

## Current execution status

- Source comparison: completed.
- Synthetic legacy fixture templates: drafted in Customer repo.
- Emulator test plan: drafted in Customer repo.
- Firebase Emulator tests: **NOT RUN**.
- Firebase Rules/code/data/deployment changes: **NONE**.
- Customer runtime code changes: **NONE**.
