# Customer Notifications & Help/Support Integration Gap Audit — 2026-10-31

## Scope
Read-only source audit of the Customer app branch `chore/remove-app-language-file`, head commit `6cc927bae761901612b630946c3c7a404836a43a`.

Reviewed:
- `lib/features/notifications/screens/notifications_screen.dart`
- `lib/features/support/screens/help_support_screen.dart`

No runtime code, Firebase, backend, Admin, Partner, production data, or deployment changes were made.

## 1. Notifications screen

Source blob: `6291397e3707fd5dc74eb8c29003c161cc91c09b`

Observed:
- Uses shared DOJO WALK theme tokens and generated localization getters.
- Displays a static empty-state illustration and copy.
- Empty-state text explicitly says notifications are not connected.
- No notification repository/provider, Firestore stream, FCM token registration, permission request, unread count, mark-as-read action, or deep-link handling is present in this screen.

Conclusion: UI empty state only. Do not represent notifications as operational.

## 2. Help & Support screen

Source blob: `d96f6802660412eea20e2dfccc6b54e5b3308586`

Observed:
- FAQ list is locally defined and displayed through ExpansionTiles.
- Category dropdown and message field are present; message validation requires at least 10 characters and limits input to 1,000.
- Controller is disposed correctly.
- Submit handler validates the form, then only shows the localized `supportMessageNotSent` snackbar.
- The screen also displays an explicit `supportFormNotConnected` notice.
- No support-ticket repository, callable/API client, Firestore write, email/WhatsApp handoff, attachment flow, ticket ID, status tracking, or retry mechanism is present.
- FAQ text/category values are localized via generated localization getters. The internal category values remain fixed English identifiers, which is acceptable as internal values but should not be shown as untranslated copy.

Conclusion: FAQ and form UI only. Submitting a message does not send or save a support request.

## 3. Product and security gates before implementation

Do not invent a client-side Firebase collection or direct write path. Before connecting either feature, the backend/product owner must define and approve:
- Notifications: canonical event types, recipient rules, server-authoritative creation, read/unread state, retention, deep-link allowlist, FCM token lifecycle and user permission behavior.
- Support: approved ticket API/collection, authenticated customer identity, category enum, validation and rate limits, attachment policy, privacy/retention, ticket acknowledgement/ID, status lifecycle, escalation ownership and audit trail.
- Failure behavior: loading, empty, permission-denied, offline, retry, duplicate submission/idempotency, and confirmed-success states.
- Data minimization: never expose internal notes, walker/customer private contact data, or unrelated booking details in notification payloads or support responses.

## 4. Safe Customer UI work that can proceed without backend

- Review responsive layout, keyboard behavior, screen-reader labels, and touch targets.
- Verify EN/HI/BN localization and overflow for long translated strings.
- Add widget tests for static empty states, FAQ expansion, category selection, validation, and the explicit not-connected submission behavior.
- Keep submission copy truthful until an approved endpoint exists.

## 5. Verification status

Latest commit `6cc927bae761901612b630946c3c7a404836a43a`:
- Customer UI Validation: SUCCESS — run [41174688453](https://github.com/DOJOWALK/DOJO-WALK-Customer/actions/runs/41174688453).
- Customer Web Build Validation: SUCCESS — run [41174688563](https://github.com/DOJOWALK/DOJO-WALK-Customer/actions/runs/41174688563).
- Customer Android Validation: SUCCESS — run [41174688529](https://github.com/DOJOWALK/DOJO-WALK-Customer/actions/runs/41174688529). Job steps included dependency install, booking contract validation, Flutter analyze, Android debug APK build and artifact verification.

These are CI checks for this exact commit. They do not establish visual QA on physical devices, real notification delivery, or live support-ticket integration.

## 6. Status

- Notifications: UI-only; integration not implemented.
- Help & Support: FAQ/form UI-only; requests are not transmitted or persisted.
- Backend/Firebase changes: none.
- PR #29: remains open/draft; do not merge without explicit approval.
