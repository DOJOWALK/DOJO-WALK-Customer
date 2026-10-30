# DOJO WALK — Cross-App Booking Compatibility Audit (Admin / Partner / Firebase)

**Date:** 2026-10-30  
**Status:** Read-only source audit — findings verified in the inspected `main` branch snapshots; not a production/deployed-state verification.  
**Related proposal:** `docs/contracts/SHARED_BOOKING_DATA_CONTRACT_V1_DRAFT.md`  
**No runtime code, Firestore rules, production data, deployment or PR merge was changed.**

## 1. Repositories and files inspected

| Repository | Branch/ref | Files |
|---|---|---|
| `DOJOWALK/DOJO-WALK-Admin` | `main` | `lib/screens/bookings/bookings_screen.dart`; prior assignment/security audit docs `STEP_197`, `STEP_198`, `STEP_200`, `STEP_201` |
| `DOJOWALK/DOJO-WALK-Partner` | `main` | `lib/screens/home/partner_home_screen.dart`; `lib/screens/home/walk_details_screen.dart`; `lib/features/live_walk/screens/live_walk_screen.dart` |
| `DOJOWALK/DOJO-WALK-Firebase` | `main` | `firestore.rules`; Functions source tree |
| `DOJOWALK/DOJO-WALK-Customer` | working branch `chore/remove-app-language-file` | Customer booking contract audit and shared contract draft (see related docs) |

## 2. Confirmed current-source observations

### 2.1 Firebase booking create contract is legacy-only

Current `DOJO-WALK-Firebase/main/firestore.rules`:
- `validBookingBase` requires legacy fields including `walkType`, `bookingPlan`, `serviceType`, `serviceName`, `petName`, `dogId`, `petDetails`, `pickupAddressId`, `pickupAddress`, `scheduledAt`, `duration`, `preferredTime`, `status`, `walkerId`, `cancelRequest`, `createdAt`, `walkCount`, `walkSchedules`.
- It allows only a fixed legacy key allowlist; proposed `schemaVersion`, `bookingType`, `schedule`, `serviceZoneId`, `quote`, and separate lifecycle objects are not accepted by this current create validator.
- Create requires `status == 'pending'` and `walkerId == null`.
- Legacy booking types are limited to `one_time/temporary_walk`, `regular/regular_walk`, and `customize/custom_walk`.
- Rules hard-limit `walkCount` and `walksPerDay` to 1–3. This is an observed current rules constraint, not confirmation that the proposed new product catalogue should inherit it.
- `validRegularBooking` requires `frequency == 'daily'`, `walksPerWeek == 7`, `planStatus == 'pending_confirmation'`, and a `dailyWalkTemplate` list.
- `validCustomBooking` requires `selectedDates` and `dateSchedules` lists of matching size; it does not require explicit inclusive `startDate/endDate` bounds.

**Compatibility consequence:** the proposed v1 canonical payload cannot be written directly to the current `bookings` collection under these rules. Do not switch Customer writes or add canonical fields without a coordinated Rules/backend migration and legacy test coverage.

### 2.2 Firebase booking update permissions

The current rules expose separate update allowances:
- Customer: limited to `cancelRequest` and `updatedAt` for selected booking statuses; completed bookings may update review fields.
- Admin: can update an allowlist including `status`, `walkerId`, `assignedAt`, payment/price fields, walk schedules and plan status, provided `isAdmin()` is true (`super_admin` plus active account).
- Approved Partner: can update an allowlist of lifecycle and walk execution fields only when `resource.data.walkerId == request.auth.uid`.

The Admin rule is permission to write assignment fields; it is not an assignment algorithm, atomic eligibility workflow, or proof that an Admin UI currently offers assignment. This broad Admin update allowlist must be reviewed before any trusted assignment endpoint is enabled.

### 2.3 Admin booking screen is a read/display surface

Current `lib/screens/bookings/bookings_screen.dart` streams the `bookings` collection and displays status, customer, walker and amount fallback values. The inspected screen does not implement a Walker assignment action. Its filter labels include pending/assigned/accepted/in-progress/completed/cancelled display states, but these labels do not establish a canonical state machine.

### 2.4 Partner app consumes assignment and advances walk lifecycle

Current `partner_home_screen.dart` loads today's bookings by querying `bookings` where `walkerId == current UID`, then filters by a legacy `date` value. This confirms Partner is a consumer of pre-existing assignments.

Current `walk_details_screen.dart` reads customer/dog/address details from legacy shapes and, when navigating to pickup, directly updates the booking `status` to `accepted` and `updatedAt`. This is a Partner lifecycle write, not assignment.

Current `live_walk_screen.dart`:
- Reads booking pickup coordinates from top-level `latitude` / `longitude`, with fallback to a GeoPoint in `location`.
- Starts GPS tracking after location permission checks; rejects location samples with invalid coordinates/accuracy or accuracy above 35m, and filters implausible movement.
- Creates a client-generated document ID in the `walks` collection for the walk session (full write path needs separate audit before any walk-record contract is approved).

**Compatibility consequence:** the proposed canonical nested `pickup` object is not yet what the inspected Partner live-walk reader consumes. A mapping/adapter or coordinated Partner update is needed. Do not assume `pickupAddress` string/map and Partner's top-level coordinates/GeoPoint are interchangeable.

### 2.5 Assignment implementation remains unlocated

Existing Admin documentation (Steps 197–201) also records a bounded search that did not locate a trusted assignment writer. The current main-branch source inspected here confirms the Admin booking screen is read-only and Partner queries assigned work, while Firebase rules permit Admin assignment-field updates. Firebase Functions tree currently contains service-location/district functions but no clearly named booking-assignment function.

This does **not** prove no assignment process exists outside inspected files, in an external backend, manual operations, another branch or an unindexed path. Owner confirmation is required before designing an automatic/manual assignment implementation.

## 3. Cross-app compatibility matrix

| Contract area | Customer / proposal | Firebase current main | Admin current main | Partner current main | Result |
|---|---|---|---|---|---|
| Booking type | 4 proposed canonical IDs; current Customer still legacy 3-choice enum | Accepts only 3 legacy plan/service pairs | Displays records; no canonical type handling observed in inspected screen | Uses assigned booking records; schedule reader uses legacy date fields | **Mismatch** |
| Document schema | Proposed `schemaVersion`, `bookingType`, nested `schedule` | Fixed legacy allowlist; canonical fields rejected on create | Reads flexible map fields | Reads legacy flat fields and nested legacy customer/dog objects | **Mismatch** |
| Pickup location | Customer currently forwards saved-address ID/map; proposed backend derives zone | Legacy `pickupAddressId` + `pickupAddress` required | Screen displays booking data; no zone derivation shown | Reads top-level coordinates or GeoPoint `location` for return validation | **Mismatch / adapter needed** |
| Service zone | Backend-derived active verified polygon | Current location callable architecture is separate; booking create does not require canonical zone ID | Existing service location models are City/Area oriented | Legacy walker profile zones still exist per prior audit | **Not connected end-to-end** |
| Booking status | Proposed independent lifecycle | One legacy `status` field | Displays raw status | Partner sets `accepted`; rules allow lifecycle writes | **Mismatch** |
| Assignment | Server-authoritative assignment | Admin rule permits `walkerId/assignedAt` updates | Inspected screen does not assign | Queries `walkerId`; cannot self-assign | **Writer not identified** |
| Payment/quote | Server-authoritative quote and verified payment | Rules allow Admin updates to price/payment fields; no quote contract established | Displays amount fallbacks | No quote contract observed in inspected paths | **Not aligned** |
| Walk execution | Separate walk state and events | Partner lifecycle fields allowed on booking | Live operations read booking/walker data | GPS and walk record handled in Partner client | **Separate contract required** |

## 4. Required decisions / blockers

1. Identify and confirm the real assignment operator: manual Admin process, trusted server function, or external service. No automatic assignment should be implemented until confirmed.
2. Decide whether booking creation will move behind a trusted backend API or retain Firestore client create with an expanded, strictly validated schema. Do not simply widen the existing rules allowlist.
3. Define a canonical migration adapter for legacy fields while preserving raw documents.
4. Align pickup location serialization: saved address, coordinates, accuracy, GeoPoint/legacy fields and backend-derived service zone.
5. Define the booking lifecycle transition authority so Partner's `accepted` update cannot conflict with booking confirmation/payment state.
6. Define the payment/quote server ownership and remove client/Admin ability to forge trusted payment state in the eventual rules design.
7. Audit full Partner `walks` document writes and all status writes in a dedicated Walk Execution Contract before modifying that schema.
8. Confirm deployed Firestore Rules revision independently; this report inspected GitHub `main`, not production deployment.

## 5. Safe next implementation sequence

- Freeze current Customer legacy writer and Firebase Rules contract as compatibility baseline.
- Approve canonical contract field names and lifecycle dimensions with Product/Founder + Backend + Admin + Partner.
- Write a migration/adapter spec with explicit legacy mappings and unknown-value preservation.
- Design trusted assignment workflow and authorization; do not treat Firestore Admin write permission as an assignment service.
- Design pickup/zone resolution contract.
- Only then implement coordinated API/Rules changes with emulator, integration, idempotency, concurrency, legacy-read and Partner lifecycle tests.
- Keep PR #29 Open + Draft; do not merge.

**Exit result:** Cross-app incompatibilities are documented from inspected source snapshots. No runtime implementation or Firebase changes were made. No production deployment status was verified.
