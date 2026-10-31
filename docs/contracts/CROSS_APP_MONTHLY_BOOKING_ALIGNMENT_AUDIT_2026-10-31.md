# DOJO WALK — Cross-App Monthly Booking Alignment Audit
Date: 2026-10-31
Status: Read-only source audit. No runtime, API, Firestore Rules, production data, or deployment changes.

## Executive finding
The Founder direction recorded in the Customer draft contract is calendar-monthly: the end date is the day before the same date in the following month (7 Nov → 6 Dec). This is not yet a shared cross-app implementation.

Customer's legacy date calculator still exposes an inclusive 28-day helper. Firebase Rules accept only legacy bookingPlan values and do not validate canonical monthly startDate/endDate fields. Admin's inspected bookings screen is a read/display surface. Partner consumes assigned legacy booking records and does not calculate monthly package terms.

Do not change the Customer helper in isolation or send calendar-monthly fields to the current Firebase create allowlist. A cross-app contract and backend approval are required first.

## Evidence by repository

### Customer — DOJOWALK/DOJO-WALK-Customer
Branch: chore/remove-app-language-file; audited head: 4357bf5c8efcbd5dd4e49d9fc97064ce0339c1c4.
- SHARED_BOOKING_CONTRACT_V1_FINAL_DECISION_REGISTER_DRAFT.md records calendar-monthly direction and pending Founder decision for 29/30/31 month-end starts.
- SHARED_BOOKING_DATA_CONTRACT_V1_DRAFT.md describes monthly_package with explicit calendar-monthly dates.
- scripts/booking_contract_validator.py validates the draft calendar-monthly fixture and reports monthly_month_end_policy_required for 31 Jan → February.
- lib/features/booking/models/booking_date_calculator.dart (blob 7d74e006ae0abe563efa8723b8ba489aefc535a2) still defines monthlyPackageEndDate as startDate + 27 days. Its own comment says this helper is not wired to booking submission or Firestore.
- test/features/booking/models/booking_date_calculator_test.dart still labels its group as an inclusive 28-day term.
- docs/contracts/CANONICAL_BOOKING_V1_VALIDATION_TEST_MATRIX_DRAFT.md (blob 6f174c179eebbaf0b0039114286ca180088bbcc0) still contains old 28-day examples.

### Firebase — DOJOWALK/DOJO-WALK-Firebase
Branch: main; firestore.rules blob 9bac26b9e13a97d412a0154ec9af70629e82eb47.
- validBookingBase accepts legacy keys such as bookingPlan, frequency, walksPerWeek, dailyWalkTemplate, selectedDates and dateSchedules. It does not allow canonical bookingType, schedule, startDate or endDate.
- validRegularBooking requires bookingPlan=regular, serviceType=regular_walk, frequency=daily, walksPerWeek=7, daily template and planStatus=pending_confirmation. It has no calendar-monthly end-date validation.
- validCustomBooking checks selected-date/date-schedule list shape, not monthly package duration.
- docs/architecture/CROSS_APP_FIRESTORE_FIELD_CONTRACT_AUDIT_2026-10-31.md records parent-booking vs individual-walk occurrence mismatch and Partner/Rules field mismatches.
- docs/contracts/BOOKING_WALK_TASK_CONTRACT_V1_DRAFT.md proposes one child task per scheduled walk occurrence; it remains a draft.

### Admin — DOJOWALK/DOJO-WALK-Admin
Branch: main.
- lib/screens/bookings/bookings_screen.dart (blob e8ac53cee7a5e16a00e83c1311539b5567e8be43) reads display fields such as scheduledAt / bookingDate; no monthly end-date calculation was found in this screen.
- docs/STEP_200_BOOKING_ASSIGNMENT_SECURITY_CONTRACT.md (blob fc6cf73a247cc27099b51a0521f807b4659507fa) is planning-only and requires trusted server-side assignment.
- docs/STEP_197_BOOKING_LOCATION_MIGRATION_CONTRACT.md (blob 170e477431616a1e0fab9d90fd76dc30ffe401db) is planning-only and confirms the current Admin screen is not the assignment algorithm.

### Partner — DOJOWALK/DOJO-WALK-Partner
Branch: main.
- lib/screens/home/partner_home_screen.dart (blob 9a1c14fe13e05eaa7fd2df55942a20b02ce82074) queries bookings by walkerId, filters today's work using legacy date, and reads startTime.
- lib/screens/home/walk_details_screen.dart (blob 4443ca2b4520700246c417cb315a6645506a1be1) reads the parent booking and changes its status to accepted; no monthly term calculation was found.
- lib/screens/home/working_schedule_screen.dart writes the Partner's own availability preferences; this is not the Customer monthly booking term.
- Firebase's cross-app audit records a mismatch between Partner workingSchedule writes and the inspected Rules allowlist. Do not widen Rules as part of this audit.

## Mismatch register
| ID | Finding | Risk | Required action |
|---|---|---|---|
| MB-01 | Customer draft says calendar-monthly; legacy helper still calculates 28 days | Medium; helper is documented as not wired to submission | Reconcile helper/tests after shared approval |
| MB-02 | Firebase Rules have no canonical monthly fields or calendar-monthly validation | High; new Customer payload would be rejected | Backend + Rules contract and Emulator tests |
| MB-03 | Legacy regular means a daily recurring template, not a proven calendar-monthly package | High; semantic ambiguity | Founder/Product defines regular meaning and migration |
| MB-04 | Admin and Partner consume legacy records, not canonical monthly dates | High; future display/dispatch inconsistency | Define canonical parent booking and walk occurrence projection |
| MB-05 | Month-end policy for 29/30/31 starts remains unresolved | High; not all end dates can be safely calculated | Founder decides February and short-month handling |
| MB-06 | Draft validation matrix still states 28 days | Medium; docs/tests conflict | Update matrix and fixtures during approved reconciliation |

## Safe implementation sequence
1. Founder approves the complete monthly rule: 29/30/31 starts, February/leap years, year boundaries, timezone/date semantics, and billing/proration.
2. Product + Customer + Admin + Partner + Backend freeze one canonical booking contract and legacy regular migration mapping.
3. Backend team designs trusted booking validation/write path and Firestore Rules changes; do not broadly expand the allowlist.
4. Add Emulator and cross-app tests for legacy reads, new monthly writes, idempotency, date boundaries, and Partner occurrence projection.
5. Only after approval, update Customer UI/helper/tests, Admin display, Partner task projection, and Firebase implementation in coordinated PRs.

## Scope guardrails followed
- This audit changed only this documentation file in the Customer repository.
- No Admin, Partner, Firebase, Firestore Rules, Functions, production data, or deployment changes were made.
- No PR was merged and no branch was deleted.