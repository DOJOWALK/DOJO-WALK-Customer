# Customer Profile, Account Details & My Dogs Audit — 2026-10-31

## Scope
Read-only source review on branch `chore/remove-app-language-file`, head at audit time `6cc927bae761901612b630946c3c7a404836a43a`.

Reviewed:
- `lib/features/profile/screens/profile_screen.dart`
- `lib/features/profile/screens/account_details_screen.dart`
- `lib/features/profile/screens/my_dogs_screen.dart`

No runtime code, Firebase Rules/Functions, backend, Admin, Partner, production data, or deployment changes were made.

## 1. Profile screen

Source blob: `7d21fdafb0a8aa764de927f4ca1af3bd3d5e972f`

Observed:
- Auth state is observed through `FirebaseAuth.instance.authStateChanges()`.
- Signed-out and signed-in views are present; navigation to account, dogs, bookings, addresses, support, settings and privacy pages is wired.
- Signed-in profile data is read from `users/{uid}` through a Firestore stream.
- Profile screen uses a locale ValueListenableBuilder and provides EN/HI/BN copy for the reviewed labels.
- The user document stream does not render explicit loading/error states. When the snapshot has no data (including a possible error), the UI falls back to display name / generic customer name and empty photo URL. This can make a data-read failure look like a normal profile.
- The signed-in profile shows a generic fallback name if no stored/display name exists; no explicit missing-profile state is shown.

Recommendation: add explicit user-document loading/error/retry states in a UI-only change; do not change user schema or access rules.

## 2. Account Details

Source blob: `47a3a764dd5583fab1b2895e927caf9e80820c87`

Observed:
- Loads `users/{uid}` once, prefills name, phone, gender, photo URL and DOB.
- EN/HI/BN translations and locale listener lifecycle are present.
- DOB picker prevents selecting a date later than the client-calculated 18th birthday threshold; save handler repeats the check.
- Save uses Firestore `set(..., SetOptions(merge: true))` for name, gender, DOB, phoneNumber and updatedAt.
- Phone update navigates to the existing Change Mobile Number screen and reloads profile after a successful return.
- Loading failure is caught silently; fallback name/phone values are set and the form is still enabled.
- Risk: after a failed profile read, a user can save the form and overwrite name/gender/DOB with fallback/empty values. The current catch path does not distinguish a successful empty document from a failed read.
- The 18+ DOB check is client-side only. It must not be treated as authoritative eligibility verification; POL-006 requires server-side validation.
- Photo URL is displayed but no photo upload/edit action was observed in the reviewed save flow.

Recommendation: distinguish load failure from a genuinely new/empty profile and block saving until data has loaded successfully or an explicit retry/new-profile path is selected. Keep eligibility validation server-authoritative.

## 3. My Dogs

Source blob: `5634275421c484e70a96ce6e3310f597add090d1`

Observed:
- Reads `users/{uid}/pets` ordered by `createdAt` descending.
- Provides loading, no-dogs, login-required and query-error states.
- Add/edit/delete actions are wired to Firestore subcollection documents.
- Form validates dog name, breed and age; size/gender have defaults; behavior and special-care multi-select options are available.
- Dog attributes are translated for English/Hindi/Bengali; breed/age/size/gender/behavior/care option values are stored as English canonical strings.
- Save writes `name`, `breed`, `age`, `size`, `gender`, `behaviour`, `specialCare`, `notes`, `createdAt` (create only), and `updatedAt`.
- Edit preserves existing notes by copying `existingData['notes']`; no editable notes control was observed in the reviewed form section.
- Delete permanently deletes the pet document after a confirmation dialog. No archive/soft-delete or booking-reference impact check is present in this client screen.
- The screen does not enforce a visible maximum number of saved dog profiles. The separate product rule of max 4 dogs per booking must not be confused with a max-4 profile limit.
- Query uses `orderBy('createdAt')`; legacy pet documents without `createdAt` may not appear in an ordered Firestore query. This needs data-shape verification before any migration or query change.
- Raw caught Firestore error text is appended to the user-facing snackbars in dog save/delete paths; this may expose technical details and is inconsistent with generic localized failure copy.
- No UI-level duplicate-submit lock is visible for delete; save has a local `saving` guard.
- No image upload/avatar field was observed in the reviewed dog form/list source.

Recommendation: verify legacy pet documents and booking references before changing query/delete semantics. Replace raw exception display with safe localized messages and add retry/confirmation behavior as appropriate. Do not invent a profile count limit.

## 4. Policy and cross-app gates

- POL-006 is Draft and requires Founder approval; customer age, eligibility, dog safety details and booking eligibility must be validated authoritatively server-side.
- Customer UI must not assume the client DOB check is proof of eligibility.
- Do not alter pet fields, Firestore rules, booking payloads, or delete behavior until Backend/Firebase and cross-app contracts are reviewed.
- Do not add a maximum saved-dog profile count based on the separate maximum of four dogs per booking.

## 5. Safe UI-only next actions

1. Add an explicit Profile user-document loading/error/retry state.
2. Add an Account Details load-error state and prevent save after failed load to avoid overwriting unknown data.
3. Replace raw Firestore exception text in My Dogs snackbars with safe localized copy.
4. Add tests for profile stream loading/error, account load failure/save guard, and dog form validation/duplicate submit.
5. Perform EN/HI/BN visual and long-text overflow QA on device/browser.

## 6. Verification status

This is a source audit only. No UI changes or test additions were made in this audit step. The previous latest code commit `6cc927bae761901612b630946c3c7a404836a43a` had successful Customer UI, Web Build and Android Validation runs; those results do not validate new changes because this audit adds documentation only.

PR #29 remains open/draft and must not be merged without explicit approval.
