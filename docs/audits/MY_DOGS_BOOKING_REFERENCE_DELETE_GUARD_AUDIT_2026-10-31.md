# My Dogs Booking-Reference Delete Guard Audit — 2026-10-31

## Scope
Customer App only. No Firebase/Backend/Firestore Rules changes were made. Reviewed branch `chore/remove-app-language-file`.

## Evidence reviewed
- `lib/features/profile/screens/my_dogs_screen.dart`: delete action now queries the signed-in customer's `bookings` where `customerId == uid`, checks both top-level `dogId` and nested `petDetails.dogId`, and stops the client delete when a reference is found.
- `lib/features/booking/screens/booking_confirmation_screen.dart`: booking creation reads `users/{uid}/pets/{dogId}` and writes both `dogId` and a `petDetails` snapshot into `bookings/{bookingId}`.
- Firebase repository `firestore.rules` (read-only inspection of main): customers can list their own bookings; `users/{uid}/pets/{petId}` deletion is currently allowed for the owner or admin without a booking-reference condition.

## Current result
The Customer UI has a best-effort guard that blocks deletion when an existing booking references the dog. A failed booking-history read also prevents deletion because the operation is inside the same guarded try path.

## Important limitation — not a guaranteed integrity control
This check is client-side and non-atomic. A booking could be created after the history query completes but before the pet document is deleted. Firestore Rules currently do not enforce the reference constraint. Therefore this change improves ordinary UX but must NOT be described as a production-grade guarantee that referenced dog records can never be deleted.

## Required backend-owner follow-up
Before production, backend/Firebase owner should approve and implement one authoritative approach:
1. Soft-delete/archive pet profiles while preserving immutable booking snapshots and references; or
2. A trusted server transaction/callable that checks references and changes pet state atomically; plus
3. Firestore Rules that prevent direct client deletion when policy requires retention, with emulator tests for referenced and unreferenced pets, query failures, and concurrent booking/delete attempts.

Do not invent a new collection or field name without shared contract approval. Do not modify Firebase Rules/Functions from this Customer task.

## Verification
- Source re-fetch confirms the Customer guard checks both dog ID locations before calling delete.
- Customer UI Validation run: [41176460660](https://github.com/DOJOWALK/DOJO-WALK-Customer/actions/runs/41176460660) — success.
- Customer Web Build run: [41176460874](https://github.com/DOJOWALK/DOJO-WALK-Customer/actions/runs/41176460874) — success.
- Android Validation run: [41176460768](https://github.com/DOJOWALK/DOJO-WALK-Customer/actions/runs/41176460768) — Flutter Analyze passed; Android debug APK build was still in progress at audit time; no final Android result claimed.

## Status
Customer-side best-effort guard documented. Backend integrity enforcement remains an explicit cross-team blocker.
