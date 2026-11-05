# Customer Retry Tests — Injection Seam Refinement
Date: 2026-10-31
Repository: DOJOWALK/DOJO-WALK-Customer
Branch: chore/remove-app-language-file
PR: #29 (Draft; unmerged)

## Additional source inspection

### My Dogs data shape
- No standalone Dog/Pet model file exists under `lib/features/profile/`.
- The screen consumes Firestore `QueryDocumentSnapshot<Map<String, dynamic>>` records directly.
- Display rendering uses `doc.id` and `doc.data()`.
- Edit and delete actions still need the Firestore pets collection. Add Dog also passes that collection to the existing form.
- The form writes the existing `users/{uid}/pets` collection and current fields. Deletion checks the customer's existing `bookings` history before deleting. These mutation paths must remain unchanged.

## Refined minimal seam

### Home
- Add optional constructor inputs: `bool Function() isSignedIn` and `Future<List<SavedAddress>> Function() loadAddresses`.
- Production defaults delegate to the existing FirebaseAuth and AddressService behavior.
- Use the same sign-in predicate for Home's address management entry points.
- Keep the existing address stream for the selector unchanged in this isolated retry-test scope.

### My Dogs
- Add optional constructor inputs: `String? Function() currentUserId` and `Stream<List<DogListRecord>> Function(String uid) watchDogs`.
- Introduce a small immutable screen-level record containing only `id` and `data`; production adapter maps the current ordered Firestore query into records.
- Keep `_pets(uid)`, add/edit/delete, booking-history protection, collection path, sort order, and Firestore writes unchanged.
- Widget tests can provide deterministic streams without creating Firebase users, Firestore snapshots, or third-party mocks. Populated-state tests need not invoke mutation actions.

## Test cases
1. Home: loading; failed load and retry recovery; empty result; default-address preference; fallback to first address; previous address retained during failed refresh; signed-out behavior.
2. My Dogs: loading; error/retry/resubscribe/success; empty stream; populated stream; signed-out behavior.
3. Regression: add/edit/delete continue using the same Firestore collection and booking-history deletion guard.

## Guardrails
- Preserve const construction and all existing call sites; all new inputs remain optional.
- Do not change Firestore schema, fields, query ordering, rules, booking-history checks, or write behavior.
- No new package dependency.
- No Firebase/backend repository changes.

## Status
Refinement audit only. No application source or tests changed. This design avoids faking Firebase SDK classes and does not require dependency additions. CI has not been run for this document-only note.
