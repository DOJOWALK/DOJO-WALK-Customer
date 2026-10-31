# DOJO WALK — Customer Booking Payload vs Firebase Rules Compatibility Matrix

**Date:** 2026-10-31  
**Status:** Read-only source comparison; no code, Rules, data, or deployment changes.  
**Customer source:** `DOJOWALK/DOJO-WALK-Customer`, branch `chore/remove-app-language-file`  
**Firebase source:** `DOJOWALK/DOJO-WALK-Firebase`, branch `main`

## Executive result

The inspected Customer booking confirmation screen writes the **legacy payload shape** directly to `bookings/{bookingId}`. The Firebase create Rules are designed around that legacy shape and conditionally validate one-time, regular-daily, and selected-date/custom records. The newer draft canonical contract (`schemaVersion`, `bookingType`, `schedule`, `startDate`, `endDate`) is **not accepted** by the current Rules allowlist.

This is not evidence that every real booking succeeds: the Rules also require correctly typed/valid values, authenticated ownership, valid pickup coordinates, server timestamp equality, valid schedule items, and type-specific conditions. No Emulator test was run for this read-only matrix.

## 1. Field-by-field matrix

| Customer writes today | Firebase create Rules | Result / notes |
|---|---|---|
| `bookingId` | Required; must equal document ID | Accepted when equal |
| `customerId` | Required; must equal authenticated UID | Accepted only for owner |
| `walkType` | Required; must equal `scheduled` | Accepted only with this value |
| `bookingPlan` | Required; enum `one_time`, `regular`, `customize` | Accepted legacy discriminator |
| `serviceType` | Required; enum `temporary_walk`, `regular_walk`, `custom_walk` | Accepted legacy discriminator; must match plan-specific validator |
| `serviceName` | Required string | Accepted |
| `petName` | Required string | Accepted |
| `dogId` | Required non-empty string | Accepted |
| `petDetails` | Required map | Accepted if map |
| `pickupAddressId` | Required non-empty string | Accepted |
| `pickupAddress` | Required map; separate coordinate validator applies | Conditional; must satisfy coordinate validation |
| `scheduledAt` | Required timestamp | Accepted if timestamp |
| `duration` | Required; `validBookingDuration()` applies | Conditional; inspect validator constraints before relying on a duration |
| `preferredTime` | Required string | Accepted |
| `status` | Required; must equal `pending` | Accepted only with pending |
| `walkerId` | Required; must be null at create | Accepted only null |
| `cancelRequest` | Required; must be null at create | Accepted only null |
| `createdAt` | Required; must equal `request.time` | Accepted when server timestamp resolves as expected |
| `walkCount` | Required integer 1–3 | Accepted within range |
| `walkSchedules` | Required list; valid item checks; list size must equal `walkCount` | Conditional |
| `frequency` | Optional allowlisted key; regular validator requires `daily`; one-time/custom forbid it | Conditional by booking plan |
| `walksPerWeek` | Optional allowlisted key; regular requires integer value 7; one-time/custom forbid it | Conditional by booking plan |
| `walksPerDay` | Optional allowlisted key; regular/custom require integer 1–3 equal to `walkCount`; one-time forbids it | Conditional by booking plan |
| `planStatus` | Optional allowlisted key; regular requires `pending_confirmation`; one-time/custom forbid it | Conditional by booking plan |
| `dailyWalkTemplate` | Optional allowlisted key; regular requires valid schedule list matching `walkCount`; one-time/custom forbid it | Conditional by booking plan |
| `selectedDates` | Optional allowlisted key; custom requires non-empty list; one-time/regular forbid it | Conditional by booking plan |
| `dateSchedules` | Optional allowlisted key; custom requires list count equal to selectedDates; one-time/regular forbid it | Conditional by booking plan |

**Canonical draft fields not in the current create allowlist:** `schemaVersion`, `bookingType`, `schedule`, `startDate`, `endDate`, and canonical monthly package term fields. Adding any of these to the Customer document today would fail `keys().hasOnly(...)` unless Backend/Firebase deliberately versions and updates the contract first.

## 2. Booking-plan compatibility

| Customer UI branch | Customer legacy values | Firebase validator | Compatibility |
|---|---|---|---|
| One-Time Walk | `bookingPlan=one_time`, `serviceType=temporary_walk`; one walk; no regular/custom-only fields | `validOneTimeBooking()` | Shape aligns, subject to all base checks |
| Regular Daily Walk | `bookingPlan=regular`, `serviceType=regular_walk`, `frequency=daily`, `walksPerWeek=7`, `walksPerDay`, `planStatus=pending_confirmation`, `dailyWalkTemplate` | `validRegularBooking()` | Shape aligns as a daily recurring template; it does **not** establish a calendar-monthly package |
| Choose Dates | `bookingPlan=customize`, `serviceType=custom_walk`, `walksPerDay`, `selectedDates`, `dateSchedules` | `validCustomBooking()` | Shape aligns at list/count level; Rules do not prove monthly duration or that dates fall inside a canonical inclusive range |
| Canonical Monthly Package draft | `bookingType=monthly_package`, `startDate`, `endDate`, canonical `schedule` | No matching validator / keys not allowlisted | Rejected by current Rules allowlist; do not send yet |

## 3. Important gaps and risks

1. **Monthly term is not represented in current legacy writes.** Customer's current confirmation writer does not write canonical `startDate`/`endDate`; Firebase Rules do not calculate or validate a calendar-monthly end date.
2. **Regular is not equivalent to Monthly Package.** Current Rules define `regular` as daily frequency, seven walks/week, and a daily template. Do not relabel or migrate it to monthly without an approved mapping.
3. **Custom dates are structurally checked, not semantically bounded.** The Rules check that `selectedDates` is a non-empty list and `dateSchedules` has the same size. They do not enforce a start/end range, calendar-monthly term, date uniqueness, or cross-list equality in the inspected validator.
4. **Base validation is strict.** Extra fields not listed in `validBookingBase().keys().hasOnly(...)` cause rejection. Required fields, enums, coordinate checks, schedule item checks, duration, timestamp and status checks also apply.
5. **Client write remains direct.** The inspected Customer screen calls `bookingRef.set(bookingData)`. The Rules validate the client-created record but this source alone does not prove server-authoritative availability, quote, payment verification, idempotency, or assignment.
6. **A Rules allowlist match is not a successful integration test.** Emulator authorization and real payload fixtures are still required.

## 4. Recommended safe sequence

1. Keep Customer writes on the currently coordinated legacy shape; do not add canonical fields as an ad hoc change.
2. Obtain Founder/Product approval for Monthly Package semantics, including starts on 29/30/31, February/leap years, date-only timezone semantics and billing/proration.
3. Backend + Customer + Admin + Partner + Firebase owners freeze a versioned canonical contract and an explicit legacy mapping (especially `regular` and `customize`).
4. Backend/Firebase design a trusted create/validation path and narrow Rules changes. Do not broadly widen `keys().hasOnly(...)`.
5. Add Emulator tests for all three legacy variants, canonical versioned payload, rejected unknown fields, date boundaries, authorization, duplicate/idempotency behavior, and legacy reads.
6. Only after those tests and approvals, coordinate app changes across repositories.

## 5. Source evidence

- Customer writer: `lib/features/booking/screens/booking_confirmation_screen.dart` — derives legacy plan/service values, constructs `bookingData`, conditionally adds regular/custom fields, then calls `bookingRef.set(bookingData)`.
- Firebase: `firestore.rules` — `validBookingBase()`, `validOneTimeBooking()`, `validRegularBooking()`, `validCustomBooking()`, and `match /bookings/{bookingId}` create rule.
- Customer canonical drafts: `docs/contracts/SHARED_BOOKING_CONTRACT_V1_FINAL_DECISION_REGISTER_DRAFT.md` and `docs/contracts/SHARED_BOOKING_DATA_CONTRACT_V1_DRAFT.md`.

## Scope guardrails

- Read-only inspection only.
- No Customer runtime code changed.
- No Firebase Rules, Functions, backend, Admin, Partner, production data, or deployment changed.
- No PR merged; no branch deleted.
- No Firebase Emulator test was run as part of this document.
