# DOJO WALK — Customer Booking Duplicate-Request / Idempotency Audit

**Date:** 2026-10-31  
**Status:** Read-only audit; no runtime code, backend, Firebase Rules, data, or deployment changes.  
**Repository/branch:** `DOJOWALK/DOJO-WALK-Customer` / `chore/remove-app-language-file`  
**Inspected file:** `lib/features/booking/screens/booking_confirmation_screen.dart`

## Executive result

The confirmation screen prevents rapid repeated taps within the same mounted screen using `_isSubmitting` and `_submitted`. This is a useful UI guard, but it is **not durable idempotency**. The client generates a new Firestore document ID for each submission attempt after reading the pet document. A retry, reopened screen, second device, or ambiguous network result can therefore produce a second booking document.

No safe Customer-only change can guarantee exactly-once booking creation while the current design writes directly to Firestore and the shared server-side booking contract is not approved/frozen.

## Evidence observed

1. `_submitBooking()` immediately returns when `_isSubmitting || _submitted`.
2. `_isSubmitting` is set to true before the pet read and Firestore write; it is reset to false in the catch block.
3. A fresh reference is generated on each invocation using `firestore.collection('bookings').doc()`.
4. The booking is persisted with `await bookingRef.set(bookingData)`.
5. `_submitted` becomes true only after the write returns successfully and the widget is still mounted.
6. The guard is held only in widget state. No durable request key is stored/reused across screen recreation, app restart, device changes, or retries.
7. If Firestore commits the write but the client does not receive a successful response (for example, a connection interruption), the catch path allows another attempt. That next attempt creates a different document ID.
8. The customer-facing success state is shown only after the write returns; the existing UI guard does not establish backend availability checks, quote validation, payment verification, or assignment.

## Risk classification

**High — duplicate booking risk under ambiguous retry/re-entry.**  
The current in-screen guard reduces accidental double taps but does not meet the idempotency requirement described in the Draft POL-006 Customer Booking & Eligibility Policy.

## Safe scope decision

- No change made to Customer booking write logic.
- No new client-generated idempotency field added; a client field alone would not provide trusted deduplication.
- No Firebase Rules, Functions, Backend, Admin, Partner, or Firestore data changed.
- No PR merged and no branch deleted.

## Required coordinated fix

1. Backend owner defines a trusted booking-create endpoint/callable and idempotency contract.
2. Client creates one stable request key for a booking intent and reuses it for retries of that same intent.
3. Server atomically records/claims the key and returns the original booking result for repeated requests; distinct intentional bookings use distinct keys.
4. Server validates customer, dog, service area, availability, schedule, quote, policy acceptance and booking state before creating the booking.
5. Firebase Rules prevent clients from bypassing the trusted create path, as agreed by the Firebase owner.
6. Add Emulator/integration tests for: rapid double tap, timeout after commit, retry after timeout, app restart/reopen, two-device same-key request, distinct-key intentional bookings, unauthorized requests, and concurrent races.
7. Only after contract approval and tests, migrate Customer submission away from direct `bookings/{id}.set()` in a coordinated cross-repository change.

## Related source of truth

- Draft POL-006 requires server-authoritative booking validation and an idempotency key or equivalent.
- Existing Customer/Firebase payload compatibility matrix documents that the current Customer writer uses a legacy direct Firestore payload and that Emulator tests have not been run.

**Conclusion:** retain the current UI guard, but do not label booking submission duplicate-safe. The durable fix is a backend-owned idempotent create operation, not a speculative Customer-only workaround.
