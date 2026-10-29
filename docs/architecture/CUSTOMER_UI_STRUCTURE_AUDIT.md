# DOJO WALK Customer UI Structure Audit

**Purpose:** Complete the customer-side screen structure and visual behavior against the Notion UI/UX design system before starting a dedicated backend alignment phase.

**Source of truth**
- Unified UI/UX Design System: https://app.notion.com/p/405756abedb9819db5abcb5196a2f23d
- POL-006 Customer Booking & Eligibility Policy: https://app.notion.com/p/404756abedb9816d8856d4f4c2de203b
- POL-011 Pricing, Taxes & Customer Terms Policy: https://app.notion.com/p/404756abedb98162be03facfb55acea4

**Audit status:** In progress. This document is an audit checklist, not a claim that UI QA or tests have passed.

## Shared UI rules

- Brand: Dojo Walk.
- Primary orange: `#FF7900`; warm background: `#FFFAF5`; primary text: `#252525`.
- Premium minimal UI; clear action hierarchy; white surfaces, restrained borders/shadows and consistent icon style.
- Responsive layouts; no clipped content or accidental horizontal overflow.
- Loading, empty, error, permission-denied and confirmed-success states where relevant.
- Do not show fake metrics, fabricated availability, unapproved prices or unverified service promises.
- Keep UI-only work separate from backend/rules/deployment changes until the UI structure and screens have been reviewed.

## Customer screen map

| Area | Current code entry point | UI completion checks |
| --- | --- | --- |
| App bootstrap / theme / locale | `lib/main.dart`, `lib/app/dojo_walk_app.dart`, `lib/app/theme.dart`, `lib/app/locale_controller.dart` | Shared tokens, startup locale, language changes refresh visible screens, supported language list stays consistent |
| Splash / session gate | `lib/features/splash/screens/splash_screen.dart` | Loading/error/retry states, profile gate is clear, no false success |
| Main navigation | `lib/app/app_navigator.dart` | Home / My Bookings / Profile labels and selected state, touch targets and small-screen layout |
| Home | `lib/features/home/screens/home_screen.dart` | Primary booking action, selected pickup location, saved-address empty/error states, language refresh |
| Booking type / schedule | `lib/features/booking/screens/choose_walk_screen.dart` | One-time / regular / choose-dates distinction, duration 20–60 min, date/time validation, readable errors, price stays pending until approved |
| Dog selection | `lib/features/booking/screens/dog_selection_screen.dart` | Clear selected state, empty/error states, add/manage dog path; current flow selects one dog only |
| Pickup address selection | `lib/features/booking/screens/pickup_address_selection_screen.dart` | Saved-address empty/error states, selected pickup confirmation, safe retry |
| Booking review | `lib/features/booking/screens/booking_confirmation_screen.dart` | Accurate dog/schedule/address summary, unapproved price remains unpriced, recurring terms not promised prematurely, request is clearly not a payment |
| My Bookings | `lib/features/booking/screens/my_bookings_screen.dart` | Loading/empty/error/status states, no claim of walker assignment until confirmed |
| Dogs / profile | `lib/features/profile/screens/my_dogs_screen.dart`, `lib/features/profile/screens/profile_screen.dart`, `lib/features/profile/screens/account_details_screen.dart` | Manageable profile forms, safe validation, consistent tokens and language behavior |
| Addresses | `lib/features/addresses/screens/my_addresses_screen.dart`, `lib/features/addresses/screens/address_form_screen.dart` | Empty/error/validation states, clear default address and pickup labels |
| Settings / support / policies | `lib/features/settings/screens/settings_screen.dart`, support and privacy/terms screens | Language choice persists, settings statuses are accurate, policy text is readable and not overstated |

## Booking UI rules before backend phase

- Do not add multi-dog booking fields or alter the booking payload until the Admin, Partner and backend data contracts have been audited. The current customer UI writes one `dogId`.
- Do not add client-side availability or price as if authoritative. Availability, service-area eligibility, quote, payment and booking status require server authority under POL-006/POL-011.
- Current runtime pricing intentionally returns no price until an approved price book exists.
- A saved booking request is not proof of walker assignment, payment or final confirmation.
- Do not introduce coupon-code fields or redemption UI.

## Verified changes on this draft branch

- Shared design tokens aligned with the Notion palette.
- Coupon/offer UI removed.
- Booking duration UI range constrained to 20–60 minutes.
- Unapproved runtime price removed; review screen explains that pricing is pending and submission is a request, not payment.
- Recurring booking copy no longer promises Sunday coverage; days, pauses, cancellation terms and billing require confirmation.
- Home screen now listens for app-language changes and removes its listener on dispose.

## Recent in-progress screen work (2026-10-29)

The following edits are committed on the current draft branch. These are source-level changes, not visual-QA or runtime verification:

- `lib/features/addresses/screens/my_addresses_screen.dart`: English/Hindi/Bangla labels for saved-address empty state, address actions, delete confirmation, retry and feedback; listens to `appLocale` and removes its listener on dispose.
- `lib/features/addresses/screens/address_form_screen.dart`: localized form labels/hints, PIN validation, map/search/current-location feedback and save/update states; listens to `appLocale` and removes its listener on dispose.
- `lib/features/booking/screens/pickup_address_selection_screen.dart`: corrected dynamic localized widgets so they are not incorrectly declared `const`.
- `lib/features/booking/screens/booking_confirmation_screen.dart`: localized booking summary labels, pending-price disclosure, schedule/plan labels, validation feedback and request-received dialog; booking plan identifiers written to the data model remain canonical.
- Static source sanity checks performed: balanced braces/parentheses and a scan for direct `const Text` calls containing dynamic locale helpers in the four reviewed screens. These checks do not replace Dart analysis or Flutter tests.
- GitHub Actions workflow runs were not returned for the latest commits. Flutter format/analyze/test/build and visual QA remain unverified.

## Remaining UI work — keep backend separate

1. Finish screen-by-screen UI and localization audit (English, Hindi, Bangla); fix strings and state behavior where required.
2. Review dog, address, booking review, booking list and profile flows for consistent premium styling and accessible form/error states.
3. Check responsive/mobile layout, keyboard focus/semantics where web is supported, touch targets and reduced-motion behavior.
4. Run Flutter format/analyze/tests/build and capture actual mobile/web screenshots. Record exact commands/results; do not mark a screen verified without evidence.
5. Only after the UI audit is accepted, begin a separate backend contract pass for availability, service-zone eligibility, price quote, idempotency, payment and cross-app booking status.

## Verification caveat

Automated tests, Flutter analyze/build and visual QA are not confirmed by this document. Do not mark the UI complete until real evidence is recorded.

## Additional UI audit pass (2026-10-29)

- Reviewed the latest source for Booking Confirmation, Pickup Address Selection, Address Form, My Addresses, My Bookings, Profile, Settings, My Dogs, Account Details, Notifications, Help & Support, and Privacy & Terms.
- Confirmed source-level locale update patterns are present in My Bookings, Profile, My Dogs, and Privacy & Terms; Settings maintains its selected language in local state and writes the shared locale.
- Updated Notifications empty state to follow the shared DOJO WALK theme and switch English/Hindi/Bangla copy through `appLocale`.
- Notifications and Help & Support are still UI-only placeholders: notification delivery and support-request submission are not connected. The support screen itself still needs a localization pass.
- Account Details, Help & Support, and other remaining customer screens still need a broader copy/localization and interaction audit.
- Static source scan found no obvious `const Text` / `const` parent widget containing dynamic locale helper calls in the four recently localized address/booking screens. This is a heuristic scan only, not Dart analysis.
- **Verification status remains NOT VERIFIED:** no successful Flutter format/analyze/test/build or device/browser visual QA has been recorded for this branch. Do not treat the UI audit as complete and do not begin backend/Firebase alignment yet.
- Added `.github/workflows/customer-ui-validation.yml` for pull requests targeting `main`; it runs `flutter analyze` and `flutter test` without requiring release secrets. The connected GitHub workflow lookup has not returned a run yet, so CI results are still pending.

## Additional localization pass (2026-10-29, continued)

- `lib/features/support/screens/help_support_screen.dart`: added shared `appLocale` listening via `ValueListenableBuilder`; localized the page heading, FAQ questions and answers, issue categories, validation copy, submit label and explicit not-connected notice in English/Hindi/Bangla. FAQ copy continues to avoid promising availability, assignment, cancellation outcomes or payment state.
- `lib/features/profile/screens/account_details_screen.dart`: added app-locale listener lifecycle and localized account heading, profile labels, DOB picker prompt, gender choices, validation, save feedback and save action in English/Hindi/Bangla.
- Source-level delimiter checks show matching brace/parenthesis counts in both edited screens. This is only a lightweight sanity check, not Dart parsing or compilation.
- The support form remains deliberately UI-only: pressing submit validates input and explains that the request is not sent. No Firebase support collection or server workflow was added.
- **Still NOT VERIFIED:** Flutter formatting, static analysis, automated tests, Android/web builds and visual QA have not been run successfully or recorded. The new pull-request validation workflow has not returned a run in the connected workflow lookup. Keep PR #29 in draft; backend/Firebase alignment remains deferred.
