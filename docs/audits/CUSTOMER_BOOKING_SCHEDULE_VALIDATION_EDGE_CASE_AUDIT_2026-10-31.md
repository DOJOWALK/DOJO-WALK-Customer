# DOJO WALK — Customer Booking Schedule & Validation Edge-Case Audit

**Date:** 2026-10-31  
**Status:** Source/test coverage audit; no runtime code, Firebase, backend, data, or deployment changes.  
**Repository/branch:** `DOJOWALK/DOJO-WALK-Customer` / `chore/remove-app-language-file`

## Executive result

The booking selection UI contains useful local checks for duration (20–60 minutes), walk count (1–3), past scheduled times, and overlapping walks. The current widget tests cover basic booking-type display, custom duration boundaries, walk-count selection, and date-selection controls.

However, important schedule edge cases are not covered by tests. Local UI validation must not be treated as authoritative availability or booking validation; the current confirmation screen still writes the legacy booking document directly to Firestore.

## Source observations

### Implemented checks

- Custom duration dialog rejects values below 20 and above 60; normal duration choices include 20, 30, 45 and 60 minutes.
- Schedule slot validation rejects an empty slot list and more than three slots.
- Slot validation checks each duration is within 20–60 minutes.
- For scheduled booking types, past time slots are rejected; Regular Daily filters elapsed slots today and can start tomorrow when no future slot remains today.
- Slots are sorted by start time and overlapping intervals are rejected when the next start is earlier than the previous slot's end.
- Choose Dates requires at least one date, and the last remaining date cannot be removed.
- Selected dates are serialized in ascending date order.
- Date picker permits today through 365 days ahead.
- Walk Now is treated as immediate/ASAP rather than a scheduled time; availability is not confirmed in this screen.

### Test coverage observed

Existing `test/features/booking/choose_walk_screen_test.dart` covers:
- Booking choices in English, Hindi and Bangla.
- Walk Now duration controls.
- Custom duration rejection at 19 minutes and acceptance at 60 minutes.
- Daily Walk choice of 1, 2 or 3 walks.
- Choose Dates control visibility.

Existing date calculator tests cover date-only normalization, legacy inclusive 28-day arithmetic, candidate Daily Continuous anchor policies, and temporary-range helper behavior. These pure helper tests do not exercise the live booking screen's selected-date/time validation or Firestore submission.

## Gaps requiring tests

| Priority | Missing test | Why it matters |
|---|---|---|
| High | Two slots with the same start time | Must reject duplicate/overlapping walk times |
| High | Adjacent slots where second starts exactly when first ends | Confirms boundary is allowed and avoids off-by-one errors |
| High | Slot starts one minute before now vs exactly now vs one minute after now | Verifies past/current/future behavior consistently |
| High | Regular Daily with no future slot today | Confirms start date rolls to tomorrow and no elapsed slot is accidentally scheduled today |
| High | Choose Dates with one past-time slot among several dates | Entire selection must stop before proceeding |
| Medium | Remove selected date while editing another date | Selected date and schedule map must remain consistent |
| Medium | Re-select an already-selected date | Must not create duplicate selected-date records |
| Medium | Select dates in reverse order | Serialized schedule must remain chronological |
| Medium | Leap day/year boundary in UI date selection and serialization | Prevents date normalization mistakes |
| Medium | Repeated Continue taps while profile/login navigation is pending | UI guard should prevent duplicate navigation/submission attempts |
| Medium | Unmount screen during profile lookup/navigation | Avoid setState/navigation after disposal |
| Medium | Per-date schedule counts and first-date summary | Ensures top-level legacy counts match the date schedule written |

## Contract and product blockers

1. Customer-side time checks cannot confirm a Walker is available; backend availability must remain authoritative.
2. The date picker’s 365-day horizon is a UI limit, not an approved service-booking horizon.
3. The existing 28-day Monthly Package helper conflicts with the latest product direction of calendar-monthly billing. It is explicitly not wired to booking submission; do not silently change it until the shared contract and 29/30/31 month-end policy are approved.
4. Draft canonical booking fixtures are not the active Firebase legacy payload. Do not send canonical fields or change Rules from this Customer-only audit.
5. A local schedule validator cannot prevent concurrent booking conflicts or duplicate writes.

## Safe next actions

- Add focused widget tests for the high-priority edge cases that can be asserted without backend changes.
- Keep backend availability, idempotency, quote, payment and assignment out of client authority.
- Do not change production schedule semantics until the shared booking contract is approved.
- Run Flutter analyze, targeted booking tests, full UI validation and Android/Web builds; report each actual CI result.

## Scope confirmation

No runtime code changed. No Firebase Rules/Functions, Backend, Admin, Partner, Firestore records, PR merge, branch deletion, or deployment was performed.
