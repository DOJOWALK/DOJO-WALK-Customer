# Customer Booking Schedule Edge-Case Follow-up — 2026-10-31

Branch: `chore/remove-app-language-file`
Reviewed commit: `af2cfbf62b314697291988a8e68fbf9860af5541`

## Scope
Static review of:
- `lib/features/booking/screens/choose_walk_screen.dart`
- `test/features/booking/choose_walk_screen_test.dart`

No production code, Firebase, backend, or other repository was changed in this follow-up.

## Code-path findings

| Case | Current implementation | Static result |
|---|---|---|
| Duplicate same-start slots | Slots are sorted by start time; the second start is compared with the first slot's end. | Rejected as overlap when duration is positive. |
| Adjacent slots | Overlap check uses `secondStart.isBefore(firstEnd)`. | Exact adjacency is allowed. |
| Past scheduled time | Scheduled slots must be `isAfter(now)`; equality is rejected too. | Past and exactly-now are rejected. |
| Regular Daily, no future slot today | `_regularStartDate()` chooses tomorrow when no configured slot today is after now. | Next-day start is selected. |
| Choose Dates validation | Every selected date is iterated and its slots validated before navigation. | One invalid date blocks continuation. |
| Date serialization | Selected dates are copied and sorted before building `dateSchedules`. | Output order is chronological. |

## Test coverage status

Existing widget tests currently cover translated booking choices, Walk Now controls, custom duration bounds, Daily Walk count choices, Choose Dates controls, and duplicate date selection.

The following edge cases are **not directly covered by dedicated automated tests** in the inspected test file:
1. Same-start duplicate slots rejected.
2. Exact-adjacent slots accepted.
3. Past / exactly-now / future boundary.
4. Regular Daily fallback to tomorrow when all slots today have elapsed.
5. A single invalid slot on one selected date blocks continuation.
6. Reverse date selection serializes chronologically.

These are coverage gaps, not confirmed runtime failures. The implementation findings above are static code-path observations; they are not claims that those scenarios were executed.

## Safe next test step
Add deterministic tests around an extracted pure schedule-validation helper with an injected clock. This avoids flaky tests that depend on the machine's current time and avoids Firebase/Auth navigation. Keep any extraction behavior-preserving and limited to the Customer repository. Do not change the legacy monthly-date helper: its 28-day behavior remains a separate shared-contract / founder-policy blocker.

## CI evidence for reviewed commit
- Customer Android Validation run 41180498535: completed SUCCESS, including booking-contract validation, Flutter analyze, Android debug APK build, and APK artifact verification.
- Customer UI Validation run 41180498489: previously reported SUCCESS; confirm run details before relying on it for a later commit.
- Customer Web Build Validation run 41180498497: previously reported SUCCESS; confirm run details before relying on it for a later commit.

Android run: https://github.com/DOJOWALK/DOJO-WALK-Customer/actions/runs/41180498535
