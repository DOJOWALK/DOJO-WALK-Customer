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

## Localization progress checkpoint (2026-10-30)

- Settings now displays all 23 registry entries; languages without complete catalogs are visible but disabled with a translated “Translation in progress” label. Only reviewed available locales remain selectable.
- English, Hindi and Bengali ARB catalogs have matching non-metadata keys (181 each at the last catalog parity check).
- My Bookings now uses generated localization getters for the page title, login prompt, load-error title, empty-state body, filter labels, and booking-detail title/unavailable state where matched.
- Registry coverage test verifies the exact 23 locale codes and duplicate-code absence.
- Translation completeness for the other 20 languages is not achieved. Build/device visual QA has not been performed. The latest CI run for code commit `65ddd0121463fe87bc7caf758dd3b21eb60bdb3f` was in progress at the time of this note.

## Schedule-label localization checkpoint (2026-10-30)

- Migrated the My Bookings schedule/date list labels (Schedule, Dates, Date, Walk) to generated `AppLocalizations` getters and passed `BuildContext` into the schedule helper functions.
- Migrated the Booking Details app-bar title to the generated localization getter.
- EN/HI/BN catalogs remain at 260 matching non-metadata keys; key parity and presence of the schedule keys were checked.
- Latest CI for this code commit is queued; no PASS claim until it completes.
- Helper-level strings for date/time/duration/plan/price/age still use the existing EN/HI/BN helper and need a wider locale-formatting review. No backend/Firebase changes were made.

## My Bookings localization and date-format checkpoint (2026-10-30)

- Migrated additional My Bookings list/detail copy to generated localization getters: login-required state, Firestore connection/permission error, refresh, total amount label, view-details action, details login/load errors, and walker-not-assigned fallback.
- Added localized abbreviated month names for Hindi and Bengali in the booking date display; English keeps English abbreviations. This is a targeted display improvement, not a full locale-aware date/number formatting implementation.
- EN/HI/BN ARB catalogs currently have 260 matching non-metadata keys each; key-set parity checked.
- Latest CI for the month-format change is queued. This checkpoint is not a PASS claim; wait for the workflow result and address any failures.
- Remaining `_t(...)` calls exist in helpers and booking screen copy. Continue audit before declaring localization complete. No backend/Firebase changes were made.

## Booking details localization checkpoint (2026-10-30)

- Booking Details now uses generated localization getters for summary/price/dog section labels, core booking fields, pricing disclosure, and cancellation confirmation/submission messages in English, Hindi and Bengali.
- The EN/HI/BN ARB files currently have 213 matching non-metadata keys each; key-set parity was checked after the latest edits.
- CI for the latest customer code commit is queued at the time this checkpoint was written. Do not mark this batch passed until the run completes successfully.
- Remaining _t(...) usage still exists in this screen (including some detail fields, schedules, age/status fallbacks and support copy); this is partial migration, not complete localization. No backend/Firebase changes were made.

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

- `lib/features/profile/screens/change_mobile_number_screen.dart`: aligned colors with the shared Notion theme and localized phone/OTP labels, validation, Firebase Auth error messages, status feedback and security note in English/Hindi/Bangla. The existing OTP verification and account-update flow was preserved; no authentication behavior or Firebase rules were changed.

## Static source safety follow-up (2026-10-29)

- A deeper source review caught and fixed two issues introduced during localization:
  - The Change Mobile Number screen referenced the locale listener and translation helper without defining their lifecycle/helper methods. Added `initState`, `_onLocaleChanged`, and `_tr`, with listener cleanup in `dispose`.
  - Account Details had dynamic translated text inside `const` widgets/menu items. Removed the invalid const contexts so translated gender labels and section text can rebuild safely.
- Re-fetched the three edited screens after fixes. Brace and parenthesis counts match, and a heuristic scan found no remaining dynamic translation calls in nearby const widget contexts. These checks cannot replace Dart analyzer/compiler output.
- **Verification remains NOT VERIFIED:** this connected workflow interface has not shown a run for the latest commit. Flutter analyze, tests, builds and visual QA still need actual execution before the UI can be marked complete.

- Added `test/app/locale_controller_test.dart` with unit cases for supported locale codes, English/Hindi/Bangla selection, and English fallback for unsupported locales. The test source is committed but **has not been executed**; CI/test success remains unverified.

## CI-driven compile fix pass (2026-10-29)

- Retrieved the actual GitHub Actions run for commit `159aeb549f7b01ee7d87c91b8d7403b3ec41c4e3`. `flutter pub get` succeeded; `flutter analyze` failed with 8 `const_eval_method_invocation` errors in:
  - `lib/features/addresses/screens/address_form_screen.dart:659`
  - `lib/features/addresses/screens/my_addresses_screen.dart:58`
  - `lib/features/booking/screens/dog_selection_screen.dart:250, 291, 351, 390, 399, 553`
- Fixed the dynamic translated strings inside const widget contexts in those three screens by removing const from the relevant parent/widgets while keeping static child values const where possible.
- Source delimiter sanity checks passed for the three edited files. **This does not mean the analyzer is fixed yet**; the latest commit must run through GitHub Actions to confirm, and any new analyzer findings must be addressed.
- Latest recorded run for the earlier commit failed at Analyze, so Tests were skipped. No merge and no backend/Firebase work until validation is clean.

- **CI result confirmed (2026-10-29):** GitHub Actions run [40927069975](https://github.com/DOJOWALK/DOJO-WALK-Customer/actions/runs/40927069975) for commit `3e166766d3d5ab6ddca84212f836c649d924e343` completed successfully. Steps confirmed: `flutter pub get`, `flutter analyze`, and `flutter test` all succeeded after the const-context fixes.
- This confirms automated analysis and tests for that exact commit. It does **not** confirm Android/web build, responsive visual QA, screen-reader/accessibility review, or live Firebase/backend integration. Those remain pending.


## CI confirmation and next screen-level audit (2026-10-29)

- **Latest observed validation run:** GitHub Actions run [40927290951](https://github.com/DOJOWALK/DOJO-WALK-Customer/actions/runs/40927290951) completed successfully for commit `6f81680a79a69b1a87580493fea9e011fdce4cb8`. The job completed `flutter pub get`, `flutter analyze`, and `flutter test` successfully. This validates the latest recorded source + audit-doc commit for those checks only.
- PR #29 remains open as Draft; it has not been merged. Do not mark the customer UI complete from analyzer/unit-test success alone.

### Findings from the next source review

- `lib/features/booking/screens/choose_walk_screen.dart`: core booking-selection UI still has substantial hard-coded English/Hinglish strings, including date-picker text, validation feedback, walk-type/schedule headings, duration labels and Continue action. This is a localization gap against the English/Hindi/Bangla requirement. Preserve booking payload field names and enum values while localizing visible labels; do not alter booking/availability semantics as part of a copy-only change.
- `lib/features/auth/screens/phone_login_screen.dart` and `lib/features/auth/screens/otp_verification_screen.dart`: authentication screens still contain hard-coded English/Hindi messages and do not consistently use the shared locale controller. A localization pass is required without changing OTP, resend, account-session or navigation behavior.
- `lib/features/settings/screens/settings_screen.dart`: language selection writes both SharedPreferences and `appLocale`; verify app-wide language persistence and cold-start behavior. Avoid introducing a second language source of truth.
- `lib/features/profile/screens/privacy_terms_screen.dart`: visible legal copy is localized, but legal correctness/versioning is not established by UI review. Do not present this source review as legal approval; final privacy notice, service terms, cancellation/refund terms and consent flows require an owner/legal review before launch.
- `lib/features/booking/screens/my_bookings_screen.dart`: localized status/plan/date fallback helpers exist. Continue auditing remaining visible strings and error/empty/loading states, including whether each displayed booking status reflects an authoritative backend state.

### Scope and next actions

1. Continue localization of the booking-selection and authentication screens in small commits; keep canonical payload keys/status values unchanged.
2. Add focused widget/unit tests for locale-dependent labels and critical validation states where practical.
3. Re-run the PR validation workflow after source edits; inspect the run for the latest head SHA.
4. Build Android and web separately and perform visual/accessibility QA before calling the customer UI complete.
5. Backend/Firebase integration remains deferred until the Notion-aligned customer UI audit is complete.


## OTP screen localization and validation (2026-10-29)

- `lib/features/auth/screens/otp_verification_screen.dart`: added shared `appLocale` listening with English/Hindi/Bangla copy for the OTP screen's primary headings, input hint, verify/resend/change-number actions, secure-login note, and common Firebase OTP error states. Existing OTP credential, resend timer, session and navigation logic was intentionally left unchanged.
- CI run [40928627423](https://github.com/DOJOWALK/DOJO-WALK-Customer/actions/runs/40928627423) caught a missing closing parenthesis in the locale-builder wrapper; corrected it in commit `eaeb5c9e40837022c03267615a649d30f4db2f60`.
- **Latest source validation:** run [40928873771](https://github.com/DOJOWALK/DOJO-WALK-Customer/actions/runs/40928873771) for that corrected source commit completed successfully: dependency install, `flutter analyze`, and `flutter test` all passed.
- The OTP screen still needs a focused widget-level locale test, and remaining less-common error strings should be reviewed. This pass does not verify actual SMS delivery, Firebase phone-auth configuration, Android/web builds, or visual QA.


## Centralized localization foundation (2026-10-29)

- Added Flutter generated-localization configuration in `l10n.yaml`, enabled localization generation in `pubspec.yaml`, and created English/Hindi/Bengali ARB catalogs under `lib/l10n/`.
- Wired `DojoWalkApp` to generated `AppLocalizations` delegates and supported locales.
- Added `lib/app/language/language_config.dart` as the single registry for English plus India's 22 scheduled languages. Only English, Hindi and Bengali are marked available because only these have initial catalog resources; other languages are explicitly rollout targets, not live translations.
- Settings and cold-start language restoration now read the same central language registry rather than maintaining separate hard-coded lists.
- Added registry tests to ensure 23 language entries exist and untranslated languages are not selectable.
- Detailed rollout plan: `docs/architecture/CENTRALIZED_LOCALIZATION_PLAN.md`.
- **Important:** this is the foundation, not a completed all-screen migration. Existing feature screens still contain inline translations and must be migrated to generated keys incrementally. Do not advertise all Indian languages as available until each has reviewed translations and coverage across the released screens.


## Generated-key migration: Notifications (2026-10-30)

- Migrated `NotificationsScreen` to generated `AppLocalizations` getters; it no longer embeds separate English/Hindi/Bengali strings or listens to `appLocale` itself.
- Added `notificationsTitle`, `noNotificationsYet` and `notificationsNotConnected` to the English, Hindi and Bengali ARB catalogs.
- Updated the locale controller so its supported locale list comes from the generated catalog. The legacy `appText` helper remains temporarily for screens not yet migrated.
- Next migration targets: Help & Support, authentication screens, then booking screens. Preserve booking payload values and backend statuses while changing display strings only.


## Generated-key migration: Phone Login (2026-10-30)

- Migrated primary Phone Login screen labels, title, mobile input hint, Send OTP action and security note to generated `AppLocalizations` keys.
- Added English, Hindi and Bengali ARB entries for these labels and common mobile/OTP feedback.
- Authentication flow, Firebase phone verification, navigation and canonical phone format were not intentionally changed.
- Remaining hard-coded authentication messages and the Booking screen's large set of inline strings still require migration and review.


## Generated-key migration: Help & Support (2026-10-30)

- Migrated the Help & Support screen title, hero text, FAQ heading, issue form labels, topic categories, minimum-length validation, submit label, and not-connected disclosure to generated `AppLocalizations` keys.
- Added matching English, Hindi and Bengali ARB entries. Category values stored by the form remain canonical English identifiers; only their displayed labels are translated.
- FAQ question/answer content still uses the compatibility inline translation helper and remains a follow-up migration item.
- Support submission remains intentionally non-functional until an actual support integration is implemented; UI copy continues to disclose this.

## Generated-key migration: Help & Support FAQ (2026-10-30)

- Moved all six Help & Support FAQ questions and answers into generated localization catalogs (app_en.arb, app_hi.arb, app_bn.arb).
- The support screen now resolves FAQ copy through AppLocalizations; removed the screen-specific inline English/Hindi/Bengali translation helper and locale listener. Flutter's generated localization delegate is the single source for displayed FAQ language.
- The stored FAQ identifiers and support form category values remain canonical keys; no booking, authentication, pricing, or backend behavior was changed.
- Support submission remains a clearly disclosed UI placeholder and does not send a message.
- Validation must be confirmed from GitHub Actions for the current branch head; no claim of local formatting, device visual QA, Android/web build, or backend integration is made here.

## Generated-key migration: Choose Walk booking screen (2026-10-30)

- Migrated the main Choose Walk screen labels, walk-type cards, schedule setup headings, walk-now disclosure, date/time picker help text, duration dialog labels, estimated-price disclosure, and common validation/profile/login feedback to generated AppLocalizations keys.
- Added matching English, Hindi and Bengali ARB values. A catalog consistency check found 117 non-metadata English keys and no missing keys in Hindi or Bengali at the time of this update.
- Preserved canonical schedule payload fields and values (for example One-Time, Daily, Custom, ASAP, frequency flags, date schedule shape), pricing service behavior, 20–60 minute duration validation, 1–3 walks/day constraint, profile age gate and navigation flow. No price was newly approved or hard-coded.
- Remaining localization follow-up: review any residual user-visible literals and date-format presentation; test language switching on this screen, then continue remaining Customer UI screens.
- GitHub Actions validation for the current branch head is pending/not yet confirmed. No device visual QA or local build is claimed.
- Follow-up within this migration: localized month names and the date-editing prefix as generated keys so the custom date chips do not keep English month abbreviations in Hindi/Bengali UI.


## Generated localization validation checkpoint (2026-10-30)

- Verified GitHub Actions run [40936722739](https://github.com/DOJOWALK/DOJO-WALK-Customer/actions/runs/40936722739) for commit `d18f3c7e0f5ad50824a3a374b7ab63eac205bb90`: the `validate` job completed successfully.
- Re-checked all three ARB catalogs: English 158 keys, Hindi 158 keys, Bengali 158 keys; no missing or extra non-metadata keys across the three catalogs.
- Updated My Bookings cancellation transaction errors to use generated localization keys (`bookingNotFound`, `cannotChangeBooking`, `cancellationNotAvailable`, `cancellationAlreadyRequested`). The transaction still verifies document existence, customer ownership, and eligible booking status before writing a cancellation request.
- Remaining work: My Bookings still contains legacy inline translations across its status labels, empty/loading/error states, booking details, and cancellation dialog. Continue migrating display copy to generated localization keys without changing canonical backend status values or booking payload fields. The UI audit is not complete; PR #29 remains Draft.


## My Bookings status-label migration (2026-10-30)

- Added generated localization keys for booking statuses and cancellation-request states to English, Hindi, and Bengali ARB catalogs.
- Migrated the booking status badge, booking detail status row, and cancellation status row to use `AppLocalizations` getters. Canonical backend status values and cancellation state values remain unchanged.
- Verified all three ARB files parse as JSON and contain 169 matching non-metadata keys each, with no missing Hindi or Bengali keys.
- GitHub Actions for code commit `828b816d8089f33b6c6a6404bd1e68217886feac` was pending at the time of this note; wait for its result before claiming validation passed. My Bookings still has other inline translations to migrate and the full Customer UI audit remains open.


### Booking helper localization checkpoint (2026-10-30)

- My Bookings now uses generated localization getters for the “price to be confirmed” fallback and booking plan labels (Regular Walk, Customized Walk, One-Time Walk), instead of the older three-language inline helper strings for those fields.
- No pricing policy or amount calculation was changed. Missing/invalid saved prices still display the unconfirmed-price message; no draft price was introduced.
- CI must validate the latest commits before this checkpoint is considered verified. Date/time/duration/age helper labels and date formatting remain in the localization audit queue; do not claim full 23-language coverage. Only English, Hindi, and Bengali catalogs are currently available/selectable.


### Booking date/time/duration/age helper localization checkpoint (2026-10-30)

- Migrated My Bookings date fallback, time AM/PM labels, duration unit/fallback, and dog-age fallback/year labels to generated `AppLocalizations` getters.
- Updated all inspected call sites to pass `BuildContext` into these helpers; money display call sites now consistently pass context for the unapproved-price fallback.
- The preceding CI run for SHA `c453eb4b7c0e329a36721f96a383b5d2e93d1b58` failed during `flutter analyze` due to a missing `BuildContext` argument at the extra-charge `_money` call. That call was corrected in the subsequent code edit. The latest run must finish before this correction is considered verified.
- Date formatting still uses manually maintained abbreviated month labels for English/Hindi/Bengali; full locale-aware formatting and non-EN/HI/BN catalogs remain future work. No backend/Firebase changes were made.


### Booking schedule duration localization (2026-10-30)

- Updated the My Bookings schedule-detail rows to use the shared localized duration formatter for each saved walk, including selected-date schedules. Numeric durations now display with the localized minutes label instead of showing a bare number.
- No booking schema, price calculation, scheduling rules, or backend behavior changed.
- CI run #40952258375 passed for the preceding helper/fallback localization commit. The new schedule-duration change has a fresh CI run pending; do not mark it verified until Analyze and Tests both pass.
- Remaining localization work includes legacy generic fallback handling, full locale-aware date/time formatting, a screen-by-screen visible-string audit, and real translations/review for the other 20 Indian languages. Only EN/HI/BN catalogs are currently available; all 23 registry options are not yet fully supported.


### Home pickup-address localization checkpoint (2026-10-30)

- Added matching generated localization keys to English, Hindi, and Bengali ARB catalogs for the Home screen's saved-address fallback, location prompt, login-required address actions, pickup-address selector title, and address-loading error.
- Migrated those six Home screen strings from inline three-language literals to generated AppLocalizations getters. Updated the saved-address formatting helper to accept BuildContext where needed.
- The Home screen still contains other inline _t strings; this is a partial migration, not a full Home localization pass. The current validation run must pass before this change is considered verified.


### Home screen full inline-string migration checkpoint (2026-10-30)

- Added 17 matching generated localization keys to the EN/HI/BN catalogs and migrated the Home screen's remaining visible copy for empty address state, adding an address, default-address marker, notifications tooltip, pickup-location label/loading state, hero/service copy, Book a Walk CTA, My Dogs, and Help & Support.
- Removed the obsolete three-language `_t` helper from `home_screen.dart`; a source scan now finds no `_t(` call or helper in that file.
- The Home screen still requires visual/locale-switch QA and an audit for other localization gaps. Only EN/HI/BN catalogs are currently available; this does not mean all 23 language options are translated.
- The latest successful Customer UI Validation run (#40953133306) was for the preceding Home address localization commit. Newer Home catalog/UI changes require a fresh run before being considered verified.


### Dog-selection localization checkpoint (2026-10-30)

- Added matching EN/HI/BN generated catalog entries for the dog-selection screen title, retry action, empty-state title/body, add-dog action/loading label, and continue action.
- Migrated those visible strings to generated AppLocalizations getters. Booking behavior and the one-dog-per-booking contract remain unchanged.
- The previous Home localization validation run (#40953817937) passed. A new CI run is required for this dog-selection change; do not treat it as verified until Analyze and Tests pass.
- Remaining dog-selection copy still uses the legacy three-language helper and needs a separate complete visible-string audit.


### Dog-selection full copy localization checkpoint (2026-10-30)

- Migrated remaining dog-selection user-facing inline English/Hindi/Bengali strings to generated `AppLocalizations` getters, including login/selection/load errors, dog breed/gender/age fallbacks, stale/missing dog validation, list heading and one-dog-per-booking guidance, add-another-dog, and continue-to-pickup actions.
- Removed the screen's legacy three-language `_text` helper. Dog selection still stores and verifies the selected dog document and continues to the pickup-address screen; no backend, Firestore contract, or multi-dog booking behavior was changed.
- EN/HI/BN ARB JSON and key parity are being checked after this change. CI for the latest code must pass before the change is considered verified. The other 20 scheduled Indian-language catalogs and full locale-aware formatting remain pending.


### Pickup-address selection localization checkpoint (2026-10-30)

- Migrated the pickup-address selection screen's inline English/Hindi/Bengali labels and user-facing errors to generated `AppLocalizations` getters, including address selection/validation, saved-address loading, empty state, add-address actions, and continuation to booking review.
- Removed the screen's legacy `_text` helper. Existing saved-address selection and navigation to booking review are unchanged; no service-area validation, pricing, payment, or backend behavior was added or implied.
- EN/HI/BN catalog parity and JSON validity are being checked. The latest Customer UI CI run must pass before treating the changes as verified. Only these three catalogs are currently available; the remaining 20 Indian-language translations are not yet complete.



### Booking review pricing safety + premium disclosure update (2026-10-30)

- Updated `lib/features/booking/screens/booking_confirmation_screen.dart` to stop deriving customer prices locally through `WalkPricingService`. Removed estimated/per-walk/daily/total price figures from the review UI and removed client-calculated `price` values from the walk schedule payload.
- Replaced the price breakdown with a visually grouped, localized disclosure: price is confirmed only after service availability and approved pricing are checked; the current action is a booking request, not a payment.
- Preserved the existing dog, pickup address, schedule, duration, walk-count validation, booking identifiers, and pending-request submission structure. No Firebase configuration or payment integration was changed.
- Policy basis: POL-011 requires one authoritative server-side price calculation, approved/versioned prices, final customer quote before confirmation, and no use of unapproved candidate prices. POL-006 requires availability/eligibility and server quote checks before payment.
- Important implementation gap remains: this screen still writes a pending booking document directly to Firestore and does not yet obtain a server-side availability result or authoritative quote. This UI change removes misleading client-side pricing; it does **not** implement the required quote/availability/payment workflow and must not be treated as production-ready.
- The booking review screen still uses the legacy inline `_text` helper rather than generated `AppLocalizations` keys. Continue its localization migration after this policy/UI correction.
- GitHub Actions validation for the resulting source commit must be checked before marking this checkpoint verified. Android/web builds and visual QA have not been run.



### Walk-schedule screen pricing safety checkpoint (2026-10-30)

- Updated `lib/features/booking/screens/choose_walk_screen.dart` to remove the local `WalkPricingService` dependency, estimated per-walk/daily price UI, and client-calculated `price` / `dailyPrice` values from the schedule object.
- Replaced the immediate-walk price line with the existing localized availability/pricing disclosure. The scheduled-walk screen retains the same disclosure and now presents duration/schedule information without an invented or unapproved amount.
- Preserved the existing `WalkBookingType` enum and the current one-time/regular/choose-dates scheduling behavior. No backend, Firestore, payment, or Firebase configuration changes were made.
- **Booking-type alignment is still blocked pending a coordinated contract update:** the current customer UI exposes three legacy types (`oneTime`, `regular`, `chooseDates`), while POL-006's 2026-10-30 decision defines four primary types: Single Walk, Temporary Booking, Monthly Package, and Daily Continuous. The current enum and downstream schedule payload are also consumed by login/profile/dog selection/booking review. Do not simply relabel the three cards or change enum values in isolation; first map all consumers and confirm canonical payload values with Admin/Partner/backend.
- Morning/Afternoon/Evening/Night remain time-slot periods, not booking types. Extra Walk/Reschedule remain features, not top-level types.
- The booking-type screen still requires a generated-localization migration and a full premium UI/empty/error/loading/accessibility/visual audit.
- GitHub source write succeeded; Flutter format/analyze/tests/build, generated-code validation, and visual QA have not been run. Do not mark this checkpoint as CI-verified.



### Four-type booking contract audit (2026-10-30)

- Audited current Customer path: `ChooseWalkScreen` enum `oneTime/regular/chooseDates` → `DogSelectionScreen` → pickup address → booking review.
- Legacy UI labels are Walk Now / Daily Walk / Choose Dates. Schedule payload includes `isImmediate`, `isRegular`, `isChooseDates`, `frequency: One-Time/Daily/Custom`, and `walksPerWeek: 7`.
- Booking review maps these to Firestore `bookingPlan: one_time/regular/customize` and `serviceType: temporary_walk/regular_walk/custom_walk`. The Regular path writes `frequency: daily` and `walksPerWeek: 7`; this does not distinguish 28-day Monthly Package from calendar-anchored Daily Continuous.
- Temporary Booking currently uses a list of selected dates rather than an explicit finite start/end date range. Monthly Package's exact 28-day term, Daily Continuous cycle anchor, and manual weekly/monthly billing preference are not represented as distinct booking types.
- The review screen directly writes a pending Firestore booking document. This audit found no proof of server-side availability/quote/payment/idempotency integration.
- Searched GitHub code for the legacy booking fields in the known Admin, Partner and Firebase repositories; no matching code results were returned, so cross-app compatibility could not be verified. This is not proof that no consumers exist.
- Proposed canonical values for cross-app contract discussion: `single_walk`, `temporary_booking`, `monthly_package`, `daily_continuous`. These are proposals only and must not be emitted to production until Admin/Partner/backend owners approve the shared schema and compatibility reader.
- No booking-type enum or Firestore field was renamed in this checkpoint; avoid a breaking change until the shared contract is frozen.
- Detailed audit and proposed migration sequence appended to Notion POL-006. Founder approval remains required. No backend/Firebase change made.
- Validation: source was read and call sites traced; Flutter format/analyze/tests/build, backend contract tests and visual QA have not been run. CI is not marked passed.
