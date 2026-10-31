# Customer Screen Retry Test Injection Plan
Date: 2026-10-31
Repository: DOJOWALK/DOJO-WALK-Customer
Branch: chore/remove-app-language-file
PR: #29 (Draft; do not merge)

## Scope
This is a customer-app-only testability plan. It does not change Firebase, backend contracts, Firestore rules, schema, Functions, or deployment.

## Verified current implementation

### Home
File: `lib/features/home/screens/home_screen.dart`
- `HomeScreen` has a const constructor with no test seams.
- `_HomeScreenState` constructs `AddressService()` internally.
- `_loadDefaultAddress()` calls `FirebaseAuth.instance.currentUser` directly, then `AddressService.getAddresses()`.
- Existing behavior retains the previously selected address when a refresh fails; the failure flag exposes retry UI.
- `AddressService` already accepts optional `FirebaseFirestore` and `FirebaseAuth` constructor dependencies, but injecting a fake FirebaseAuth/Firestore implementation would still require a mocking strategy.

### My Dogs
File: `lib/features/profile/screens/my_dogs_screen.dart`
- `MyDogsScreen` has a const constructor with no test seams.
- The screen reads `FirebaseAuth.instance.currentUser` directly.
- The pets stream is built directly from `FirebaseFirestore.instance.collection('users').doc(uid).collection('pets').orderBy('createdAt', descending: true).snapshots()`.
- Retry increments `_retryAttempt`; a `ValueKey<int>` recreates the StreamBuilder subscription.
- Error, waiting, empty, and populated states are present.

## Recommended minimal seam design
1. Home: add optional constructor callbacks for current-user identity and address loading, with production defaults preserving current Firebase behavior. Prefer a typed callback such as `Future<List<SavedAddress>> Function()` plus a simple signed-in predicate/getter. Keep the existing `AddressService` default in production.
2. My Dogs: add an optional typed pets-stream provider. Prefer exposing `Stream<List<DogRecord>>` (or the existing domain type if one exists) rather than making widget tests construct Firebase `QuerySnapshot` objects. Production default maps the existing ordered Firestore query into that type.
3. Keep all existing user-facing loading/error/empty/populated/retry behavior unchanged.
4. Add dependency-free widget tests using `Completer`, `StreamController`, and fake typed records. Cover loading -> error -> retry -> success, empty/populated, and signed-out behavior.
5. Do not add mock packages unless the team explicitly selects that test strategy.

## Guardrails
- Do not modify booking submission or any Team 01-owned API.
- Do not change Firestore collection names, query ordering, document fields, or access rules.
- Do not change Firebase/backend repository or Firebase Console.
- Do not merge PR #29.
- Before implementation, inspect the complete dog model/parsing code and all call sites to ensure constructor changes remain source-compatible.

## Status
Audit only. No production code, tests, dependencies, Firebase configuration, or backend files were changed in this step. CI has not been run for this document-only commit.
