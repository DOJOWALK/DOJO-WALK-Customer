# Customer Screen Test Harness Feasibility — 2026-10-31

## Review performed
Reviewed the existing Flutter widget-test conventions, app bootstrap, address service, Home Screen and My Dogs Screen on `chore/remove-app-language-file`.

## Findings

### Existing test convention
- Widget tests use `flutter_test` and `MaterialApp` with localization delegates.
- The current Choose Walk widget tests do not initialize Firebase.
- Existing test files cover booking UI, auth localization, locale controller, and support/notifications.
- `pubspec.yaml` includes `flutter_test`, but no dedicated Firebase mock package, fake Firestore package, Mockito, or Mocktail dependency was found.

### Firebase initialization boundary
- `lib/main.dart` calls `Firebase.initializeApp()` before `runApp`.
- Home Screen currently constructs `AddressService()` internally and reads `FirebaseAuth.instance.currentUser` directly.
- `AddressService` itself already supports injected `FirebaseFirestore` and `FirebaseAuth` instances, but Home Screen does not expose an injection seam.
- My Dogs Screen reads `FirebaseAuth.instance` and `FirebaseFirestore.instance` directly while building its stream.

## Conclusion
A meaningful Home/My Dogs retry-recovery widget test cannot currently be written using the repository's existing test dependencies and setup without introducing a Firebase test/mocking strategy or adding controlled dependency injection.

Do not add superficial tests that only assert static text or simulate a retry button without proving the data source is resubscribed/recovered.

## Safe next implementation proposal
1. Agree on a minimal testability seam for Home Screen (inject AddressService and auth/current-user access while retaining production defaults).
2. Agree on a testability seam for My Dogs (inject pets stream provider while retaining the existing Firestore default).
3. Use deterministic fake streams to test loading → error → retry → success, plus empty/populated and signed-out states.
4. Avoid adding third-party dependencies unless a repository-wide test strategy explicitly selects them.

## Scope and gates
- No source code or dependency changes made in this feasibility pass.
- No Firebase project, Firestore schema/rules, backend, or API changes.
- Booking API integration remains blocked pending Team 01 contract approval.
- PR #29 remains Draft / unmerged.
