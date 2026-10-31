# Customer Localization, Loading, Empty & Error-State Audit — 2026-10-31

## Scope

Read-only source audit on the existing branch `chore/remove-app-language-file` in `DOJOWALK/DOJO-WALK-Customer`.

Reviewed:
- Team 04 — Customer App responsibilities and Definition of Done.
- Central Task Register filtered to Department = Customer App (no matching rows returned; no Task ID is assigned or inferred here).
- Booking API Contract & Callable Implementation Gate (still BLOCKED; no backend integration changes authorized).
- `lib/main.dart`, `lib/app/dojo_walk_app.dart`, `lib/app/locale_controller.dart`, `lib/app/language/language_config.dart`, `l10n.yaml`, EN/HI/BN ARB catalogs.
- Settings, Home, My Dogs, Dog Selection, My Addresses, Pickup Address Selection, Notifications and Help & Support screens.
- Existing Customer UI test file for Notifications and Help & Support was inspected as source; tests were not executed in this audit.

No backend/Firebase repository, Rules, Console, live data, or other team's files were changed.

## 1. Localization findings

### Verified foundation

- Flutter generated localization is configured through `l10n.yaml` with ARB resources in `lib/l10n/`.
- `main.dart` restores the saved `dojo_app_language` preference before `runApp`, and validates it against the selectable language registry.
- `DojoWalkApp` binds `MaterialApp.locale` to the shared `appLocale` notifier and uses generated localization delegates/supported locales.
- The language registry lists English plus the 22 scheduled Indian languages. Only English (`en`), Hindi (`hi`) and Bengali (`bn`) are marked selectable; the other 20 are disabled as translation rollout pending. This is the correct conservative behavior and must not be described as all 23 languages being live.
- The EN, HI and BN ARB files contain 395 matching user-facing message keys each. The one English-only `@bookingConfirmationSelectedDates` entry is ARB metadata, not a user-facing translation key.

### Remaining localization inconsistency

- `MyAddressesScreen` still contains many inline EN/HI/BN triples through `_text(...)` and `appText`, rather than the central ARB catalog.
- `MyDogsScreen` still contains a large inline translation dictionary via `_dogTr(...)`.
- Other audited screens already use generated `AppLocalizations` getters.
- The mixed pattern makes future translation review and language coverage harder, even though these inline helpers currently cover the three enabled locales.

Recommendation: migrate the remaining inline dictionaries to ARB keys in small screen-scoped changes. Do not enable additional languages until their full released-screen catalog, placeholders, formatting and visual review are complete.

## 2. Loading, empty and error states

| Screen | Loading | Empty / signed-out | Error / retry | Audit result |
|---|---|---|---|---|
| Dog Selection | Spinner while stream has no data | Explicit signed-out state; clear no-dog message with Add Dog action | Error copy and Retry button | Good baseline; test stream retry and selection restoration |
| Pickup Address Selection | Spinner while stream has no data | Explicit no-address state with add-address action | Error copy and Retry button | Good baseline; test retry and default-address reselection |
| My Dogs | Spinner while stream waits | Signed-out and no-dog states | Error state explains connection/Firestore permission issue, but no explicit retry action | Add an explicit retry/re-subscribe action |
| My Addresses | Spinner while stream waits | Signed-out and no-address states; Add New Address action | Error message and retry by replacing the route | Functional, but retry should be tested for duplicate route/navigation behavior |
| My Bookings | Auth and booking stream loading indicators | Signed-out and empty list states | Error title, connection/permission guidance and refresh action | Good baseline; distinguish permission denied from network errors if safely available |
| Home saved address | `_loadingAddress` is tracked and empty address state is handled | No saved address falls back to Select Location | `_loadDefaultAddress()` catches failures silently and only sets loading false | High-priority UX gap: load failure is indistinguishable from no address; no retry/error state |
| Settings | Location permission has a loading label | Settings remain available | Settings load, location check and settings-open failures have messages | Good baseline; verify on Android and Web separately |
| Notifications | Not applicable | Honest “No notifications yet” state | No live notification source or retry state | Explicitly says notifications are not connected; do not imply notification delivery is implemented |
| Help & Support | Form is local UI | FAQ content is present | Form explicitly discloses that support submission is not connected and says message was not sent | Honest disabled integration; do not represent a submitted support ticket |

## 3. Findings / priority

| ID | Priority | Finding | Evidence / impact |
|---|---|---|---|
| CUST-L10N-01 | Medium | Localization remains split between ARB getters and inline three-language helpers | `MyAddressesScreen` and `MyDogsScreen` retain hard-coded EN/HI/BN variants; migration/coverage can drift |
| CUST-STATE-01 | High | Home saved-address load failure is silent | `_loadDefaultAddress()` catch block only clears `_loadingAddress`; customer receives no failure message or retry and may mistake failure for an empty address list |
| CUST-STATE-02 | Medium | My Dogs stream error has no direct retry action | Customer must leave/reopen the screen to retry the stream |
| CUST-STATE-03 | Medium | Notifications are a static not-connected empty state | No notification stream/integration is wired in this screen; copy is honest, but feature remains pending |
| CUST-STATE-04 | Medium | Support request form is not connected | UI correctly discloses that the message is not sent; support ticket creation remains pending |
| CUST-STATE-05 | Low | Retry behavior differs across screens | Dog/Pickup use rebuild, My Addresses replaces the route; consistent retry behavior and route tests are needed |

## 4. Safe implementation order

1. Fix Home saved-address failure UX locally: preserve the last valid address state, show a localized load-failure message, and provide a retry action. Do not change AddressService or Firestore schema.
2. Add a retry action for My Dogs that resubscribes safely without duplicate navigation.
3. Migrate My Addresses and My Dogs inline text to generated ARB getters, preserving existing EN/HI/BN wording. Add key-parity checks and widget tests.
4. Keep Notifications and Help & Support visibly “not connected” until Team 01-approved notification/support contracts and real end-to-end delivery are available.
5. Run localization generation, formatter, analyzer, widget tests, Android build, Web build and EN/HI/BN visual checks. Do not claim PASS until the actual workflow evidence is available.

## 5. Verification and scope record

- Source evidence: inspected on existing branch `chore/remove-app-language-file`.
- ARB user-facing key parity: 395 keys in each of EN, HI and BN; checked by parsing the three files.
- Existing notification/support widget tests: source present, execution not performed in this audit.
- Flutter analyze/build, device testing and visual QA: not run here.
- No Dart source changed in this documentation-only commit.
- No new branch created; no direct work on `main`.
- No Firebase/backend/Rules/Console changes.
- Team 01 callable/API implementation gate remains BLOCKED; this audit does not authorize integration.
