# DOJO WALK — Customer Booking Flow Data Handoff Audit

**Date:** 2026-10-31  
**Repository:** `DOJOWALK/DOJO-WALK-Customer`  
**Branch:** `chore/remove-app-language-file`  
**Scope:** Read-only source audit of Choose Walk → Dog Selection → Pickup Address → Booking Confirmation. This document does not authorize a booking API or Firebase change.

## Executive result

The in-app handoff currently carries a mutable schedule map, selected dog snapshot and pickup-address map into the confirmation screen. Confirmation then re-reads the selected pet and writes a legacy parent booking document directly to Firestore.

The screen-to-screen handoff is present, but it is not a server-approved booking workflow. Team 01's Booking API Contract & Callable Implementation Gate remains **BLOCKED — contract and product decisions pending**. Do not switch the writer, add canonical fields, enable payment, or claim availability confirmation from this flow.

## Verified handoff

| Stage | Current behavior | Data passed / read |
|---|---|---|
| Choose Walk | Builds schedule based on One-Time, Regular or Choose Dates; validates local schedule rules before navigation | `WalkBookingType` + `Map<String,dynamic> schedule` |
| Dog Selection | Receives the same schedule map; lists `users/{uid}/pets`; verifies selected pet document still exists before continuing | `walkType`, `schedule`, selected dog map with `dogId` and `name` |
| Pickup Address | Receives walk type, schedule and dog details; customer selects a saved pickup address | `walkType`, `schedule`, `dogDetails`, selected address map |
| Booking Confirmation | Validates required dog/address IDs and schedule shape; re-reads selected pet; builds legacy booking payload | `walkType`, `dogDetails`, `pickupAddress`, `schedule` |
| Firestore write | Generates a client-side document reference and calls `bookingRef.set(bookingData)` | Legacy `bookings/{bookingId}` document |

## Current payload facts

The confirmation writer currently includes:

- Identity/request: `bookingId`, `customerId`, `walkType: scheduled`, `bookingPlan`, `serviceType`, `serviceName`.
- Pet: `petName`, `dogId`, `petDetails` snapshot.
- Pickup: `pickupAddressId`, map-valued `pickupAddress`.
- Schedule: `scheduledAt`, string `duration`, `preferredTime`, `walkCount`, `walkSchedules`.
- Initial state: `status: pending`, `walkerId: null`, `cancelRequest: null`, `createdAt: FieldValue.serverTimestamp()`.
- Regular-only: `frequency: daily`, `walksPerWeek: 7`, `walksPerDay`, `planStatus: pending_confirmation`, `dailyWalkTemplate`.
- Choose-Dates-only: `walksPerDay`, `selectedDates` as YYYY-MM-DD strings, `dateSchedules` with Timestamp date and nested cleaned walks.

The UI currently maps modes as:
- One-Time → `bookingPlan: one_time`, `serviceType: temporary_walk`.
- Regular → `bookingPlan: regular`, `serviceType: regular_walk`.
- Choose Dates → `bookingPlan: customize`, `serviceType: custom_walk`.

## Findings and risks

### 1. No API-backed availability gate in this flow

The schedule is locally validated, then the user proceeds through dog/address/confirmation. The inspected confirmation writer saves a pending booking directly; no approved availability callable or reservation token is consumed here. UI schedule validation is not proof of Walker/capacity availability.

**Disposition:** Keep this as a known integration blocker. Do not add an invented availability API or unlock payment.

### 2. No approved payment stage in the current writer

The inspected writer does not initiate payment or verify a provider transaction. Its successful Firestore write means only that a pending request document was saved.

**Disposition:** Do not label this screen as paid/confirmed and do not add client-trusted payment state.

### 3. Custom dates are represented in two parallel structures

Choose-Dates sends both `selectedDates` (date strings) and `dateSchedules` (Timestamp date plus walks). The confirmation writer derives the top-level `scheduledAt`, `duration`, `preferredTime`, `walkCount` and `walkSchedules` from the first date entry. The nested schedule remains the full multi-date detail.

This means consumers must not mistake the top-level schedule fields for the complete multi-date booking. Date ordering and one-to-one equality between both structures need contract-level validation.

**Disposition:** Preserve legacy shape until Team 01 approves an exact DTO; add contract fixtures for sorted dates, matching date sets, per-date walk counts and nested item validation.

### 4. Regular mode is a daily template, not a finalized calendar-monthly term

The current payload records a daily template and `walksPerWeek: 7`, but no explicit calendar-monthly start/end pair or approved cycle policy.

**Disposition:** Do not reinterpret `regular` as a monthly package or silently calculate an end date.

### 5. Parent booking versus child Walk Task is not implemented by this Customer flow

The latest Notion design direction distinguishes `bookings/{bookingId}` (commercial/customer parent) from `walk_tasks/{walkTaskId}` (one scheduled occurrence). The inspected Customer writer creates only the parent booking document. It does not create child tasks, and Customer must not independently create them.

**Disposition:** Backend owns atomic/idempotent task generation. Customer should later render task-level schedule/status only from an approved backend response/read contract.

### 6. Dog snapshot is re-read but remains client-written in the booking

The confirmation screen re-fetches the selected pet before creating the payload, which reduces stale selection risk. It then embeds the fetched pet data in `petDetails`. The callable gate specifies that backend must verify pet ownership and generate trusted snapshot fields.

**Disposition:** Keep the re-read as current UI validation, but do not treat it as server-side ownership enforcement.

### 7. Pickup address map is passed through as a client snapshot

The selected address ID and map are passed into confirmation and written as-is. The callable gate requires ownership verification and a defined authoritative address/snapshot policy. Coordinate validation alone does not prove that the saved address belongs to the authenticated customer.

**Disposition:** Do not reshape or enrich the map until Team 01 approves the exact address DTO and compatibility mapping.

### 8. Date/time serialization needs a frozen contract

Choose Walk serializes selected dates into a mixture of `DateTime`, display-formatted strings and walk time strings. Confirmation converts selected date values to Firestore Timestamps for nested `dateSchedules`, uses date-only values for `selectedDates`, and stores local clock labels in `preferredTime` / `walkSchedules[*].time`.

Notion's current design direction specifies `Asia/Kolkata`, UTC Firestore timestamps, and explicit `serviceDateKey` / `serviceTime` / timezone for each Walk Task. The existing Customer payload is not yet that approved task contract.

**Disposition:** Backend and app owners must approve date-only and timestamp semantics before changing serialization.

## Cross-app / backend boundary

- Team 01 owns approved request DTO, authentication/ownership checks, server IDs/timestamps, availability, quote/payment, task generation, assignment and lifecycle transitions.
- Customer owns the user journey and submits intent only through the approved contract after the gate opens.
- Admin/Partner compatibility must be tested against the exact server-created legacy projection; do not add guessed Partner fields in Customer.
- Existing legacy documents must remain readable; no bulk migration is part of this task.

## Required tests when the contract is approved

1. One-Time, Regular and Choose-Dates request fixtures.
2. Missing/invalid dog ID; deleted pet between selection and submit; ownership mismatch.
3. Missing/invalid pickup ID; address ownership mismatch; both coordinates missing / half-pair / out-of-range.
4. Custom date order, duplicate dates, date-set parity, invalid date, empty nested walks, and invalid nested walk on a later date.
5. Duration 20 and 60 boundaries; invalid values and top-level/per-walk consistency.
6. Asia/Kolkata date boundary, UTC timestamp conversion and immediate/ASAP semantics.
7. Same idempotency key retry returns the original request; changed payload with same key is rejected.
8. Parent booking and child Walk Task creation is atomic/idempotent on backend.
9. Admin and Partner readers consume the exact server-created compatibility projection.
10. Payment pending/failure/verification and availability unavailable/expired states are handled without client-trusted confirmation.

## Gate and action

**Current status: AUDIT DOCUMENTED — IMPLEMENTATION BLOCKED.**

Safe next step is to finalize the legacy-compatible callable DTO and field mapping across Customer, Admin and Partner, then let Team 01 implement and test it in its own isolated backend branch. Customer runtime code remains unchanged until written approval and exact API contract are available.

## Evidence inspected

- `lib/features/booking/screens/choose_walk_screen.dart`
- `lib/features/booking/screens/dog_selection_screen.dart`
- `lib/features/booking/screens/pickup_address_selection_screen.dart`
- `lib/features/booking/screens/booking_confirmation_screen.dart`
- Notion: `TEAM 04 — Customer App`
- Notion: `Booking API Contract & Callable Implementation Gate`
- Notion: `DOJO WALK — Central Task Register`

**Limitations:** Source inspection only. No Firebase Emulator, live Firestore, device GPS, payment provider, availability engine, Admin/Partner end-to-end, or production test was run for this audit.
