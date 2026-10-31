# Customer Retry UX Test Coverage Audit — 2026-10-31

## Scope
Read-only review of the Customer App branch `chore/remove-app-language-file`.
Reviewed:
- `lib/features/home/screens/home_screen.dart`
- `lib/features/profile/screens/my_dogs_screen.dart`
- Existing test tree under `test/`, including booking and support widget-test conventions.
- `pubspec.yaml` test dependencies.

No Firebase/backend files, API contracts, booking writes, or production behavior were changed by this audit.

## Verified implementation

### Home saved-address loading
- `_loadDefaultAddress()` marks loading and clears the prior error before each attempt.
- Signed-out users leave loading without querying addresses.
- Successful empty results clear the saved address and show the localized select-location text.
- Successful results prefer the default address, falling back to the first saved address.
- Exceptions set `_addressLoadFailed` and stop loading.
- Existing saved address remains visible while a refresh is in progress.
- Failure UI displays a localized error and Retry action.
- Pull-to-refresh invokes the same loader.

### My Dogs stream retry
- Firestore pets are read from the signed-in user's `users/{uid}/pets` subcollection, ordered by `createdAt` descending.
- Stream errors show an error state and Retry action.
- Retry increments `_retryAttempt`; the `ValueKey<int>` on `StreamBuilder` forces a new stream subscription.
- Loading, empty, and populated states are handled separately.
- Signed-out state does not start the pets stream.

## Test coverage finding
The current test tree contains widget tests for Choose Walk, auth localization, and notifications/support. No dedicated HomeScreen or MyDogsScreen widget test file was found in the inspected test directories.

Therefore the retry behavior is implemented but not directly regression-tested by a dedicated screen-level widget test at this audit point.

## Recommended regression cases
1. Home: loading state, successful default-address selection, fallback-to-first behavior, empty result.
2. Home: failed request exposes Retry; retry success clears the error and updates the address.
3. Home: existing address remains visible while a refresh is pending.
4. My Dogs: loading, empty, populated, and stream-error states.
5. My Dogs: tapping Retry rebuilds the stream subscription and can recover from an initial stream error.
6. Both screens: signed-out behavior does not issue authenticated data reads.

## Testability / risk note
These screens instantiate Firebase Auth/Firestore-backed services directly. Before adding widget tests, establish the repository's supported Firebase test initialization or mocking pattern. Do not add a new mocking dependency or change production dependency injection solely to make a speculative test compile. A test that only checks static labels would not prove retry recovery.

## Gate / ownership
- This is a Customer App UI QA finding only.
- Booking Callable / availability / payment / assignment API gate remains blocked pending Team 01 contract approval.
- No Firebase/backend integration is authorized by this audit.
- PR #29 remains Draft / unmerged.
