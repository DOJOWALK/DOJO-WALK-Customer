# DOJO WALK — Customer Schedule Test Coverage Reconciliation

**Date:** 2026-10-31  
**Repository:** `DOJOWALK/DOJO-WALK-Customer`  
**Branch:** `chore/remove-app-language-file`  
**PR:** #29 (Open / Draft)  
**Scope:** Documentation-only reconciliation. No runtime code, Firebase, backend, data, or deployment changes.

## Why this follow-up exists

The earlier `CUSTOMER_BOOKING_SCHEDULE_VALIDATION_EDGE_CASE_AUDIT_2026-10-31.md` listed several schedule cases as missing tests based mainly on the booking-screen widget test file. A separate pure unit-test file already covers many of those rules. This note reconciles the audit against both test files so that existing coverage is not duplicated or incorrectly reported as absent.

## Existing automated coverage found

Source files:
- `lib/features/booking/models/booking_schedule_rules.dart`
- `test/features/booking/models/booking_schedule_rules_test.dart`
- `test/features/booking/choose_walk_screen_test.dart`

| Scenario | Existing test coverage | Assessment |
|---|---|---|
| Same-start duplicate slots | `hasOverlap`: rejects two slots with identical start | Covered at pure-helper level |
| Exact-adjacent slots | `hasOverlap`: allows next slot at previous end | Covered at pure-helper level |
| Partial overlap independent of input order | `hasOverlap`: sorts slots and rejects overlap | Covered at pure-helper level |
| Past / exactly-now / future start | `isFutureStart`: one minute before, equal, one minute after | Covered at pure-helper level |
| Regular booking rolls to tomorrow when no future slot remains | `regularStartDate`: elapsed slots today | Covered at pure-helper level |
| Regular booking starts today if a later slot remains | `regularStartDate`: future slot today | Covered at pure-helper level |
| Date ordering, normalization and duplicate date removal | `sortDates`: reverse order, duplicate calendar date, time normalization | Covered at pure-helper level |
| Leap day and year boundary sorting | `sortDates`: 2027/2028 boundary and 29 February | Covered at pure-helper level |
| Duplicate selected date in booking UI | `choose_walk_screen_test.dart`: reselects same date | Covered at widget level |

## Remaining gaps — do not duplicate existing helper tests

1. **Multi-date UI validation:** a selected date containing one invalid/past slot blocks the entire Choose Dates continuation. This needs a deterministic widget-level test or a pure validation seam that accepts an injected clock.
2. **Screen lifecycle / navigation:** unmount during async profile lookup and repeated Continue callbacks while navigation is pending need widget-level regression coverage.
3. **Schedule payload integration:** verify per-date slot counts and serialized schedule summaries remain aligned at the UI-to-booking boundary. Do not assert or change the legacy backend payload contract without Team 01 approval.

## Contract boundaries

- These tests prove local schedule-helper behavior only; they do not prove real-time walker availability.
- Backend availability, booking idempotency, quote calculation, payment verification and walker assignment remain server-authoritative.
- The legacy 28-day monthly helper must not be changed until the calendar-monthly contract and month-end rule are approved.
- No Firebase collection, callable, Rules, Functions or backend endpoint is introduced by this work.

## Verification evidence

The existing PR #29 head at the start of this documentation follow-up had successful Customer UI Validation, Customer Android Validation and Customer Web Build Validation runs. Those runs validate that earlier commit only; this documentation-only commit must receive its own CI result before being described as newly verified.

## Outcome

The earlier audit's pure-helper coverage gaps are reconciled as already covered. The remaining work is specifically widget/integration coverage, not duplicate unit tests for the same helper rules.
