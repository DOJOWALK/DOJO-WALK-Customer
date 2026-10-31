# Customer Notifications & Help/Support Integration Gap Audit — 2026-10-31

## Scope
Read-only source audit refreshed against branch `chore/remove-app-language-file` at the current PR #29 head observed during this review: `d8e27af472eaa0ba5f744f0ac4575311c199da37`.

Reviewed:
- `lib/features/notifications/screens/notifications_screen.dart` — blob `6291397e3707fd5dc74eb8c29003c161cc91c09b`
- `lib/features/support/screens/help_support_screen.dart` — blob `d96f6802660412eea20e2dfccc6b54e5b3308586`
- `lib/features/profile/screens/profile_screen.dart` — profile navigation entry for Help & Support
- `lib/app/dojo_walk_app.dart` and `lib/main.dart` — app entry/localization setup

No runtime code, Firebase, backend, Admin, Partner, production data, or deployment changes were made.

## 1. Notifications screen

Observed:
- A stateless screen using shared DOJO WALK theme tokens and generated localization getters.
- Displays a static empty-state illustration and copy.
- Empty-state text explicitly says notifications are not connected.
- No notification repository/provider, Firestore stream, FCM token registration, permission request, unread count, mark-as-read action, notification history pagination, or deep-link handling is present.

Conclusion: UI-only placeholder. It correctly signals that notifications are not connected; do not represent notification delivery or notification history as operational.

## 2. Help & Support screen

Observed:
- FAQ list is locally defined and displayed through ExpansionTiles.
- Category dropdown and message field are present. Message validation requires at least 10 trimmed characters and limits input to 1,000 characters.
- Message controller is disposed correctly.
- Category values are fixed internal English identifiers; displayed labels are localized.
- Submit handler validates the form, then only shows the localized `supportMessageNotSent` snackbar.
- The screen also displays an explicit `supportFormNotConnected` notice.
- No support-ticket repository, callable/API client, Firestore write, email/WhatsApp handoff, attachment flow, ticket ID, status tracking, or retry mechanism is present.
- The submit button remains available after validation, but the handler does not transmit or persist the message. The UI must not imply that a ticket was created.

Conclusion: FAQ and form UI only. Submitting a message does not send or save a support request.

## 3. Product and security gates before implementation

Do not invent a client-side Firebase collection or direct write path. Before connecting either feature, the backend/product owner must define and approve:
- Notifications: canonical event types, recipient rules, server-authoritative creation, read/unread state, retention, deep-link allowlist, FCM token lifecycle, and user permission behavior.
- Support: approved ticket API/collection, authenticated customer identity, category enum, validation and rate limits, attachment policy, privacy/retention, ticket acknowledgement/ID, status lifecycle, escalation ownership, and audit trail.
- Failure behavior: loading, empty, permission-denied, offline, retry, duplicate submission/idempotency, and confirmed-success states.
- Data minimization: never expose internal notes, walker/customer private contact data, or unrelated booking details in notification payloads or support responses.

## 4. Safe Customer UI work that can proceed without backend

- Review responsive layout, keyboard behavior, screen-reader labels, and touch targets.
- Verify EN/HI/BN localization and overflow for long translated strings.
- Add widget tests for static empty states, FAQ expansion, category selection, validation, and the explicit not-connected submission behavior.
- Keep submission copy truthful until an approved endpoint exists.
- Do not add fake local persistence, invented Firebase paths, simulated ticket IDs, or success messages.

## 5. Verification status

Branch/PR:
- PR #29 remains OPEN and Draft; no merge performed.
- Latest branch head observed: `d8e27af472eaa0ba5f744f0ac4575311c199da37`.

Relevant CI observations:
- Customer Web Build for commit `8a474a589cd683afa3a6f99b9e137624899d84d3`: SUCCESS — run [41176460874](https://github.com/DOJOWALK/DOJO-WALK-Customer/actions/runs/41176460874).
- Customer UI Validation for commit `8a474a589cd683afa3a6f99b9e137624899d84d3`: SUCCESS — run [41176460660](https://github.com/DOJOWALK/DOJO-WALK-Customer/actions/runs/41176460660).
- Customer Android Validation for commit `8a474a589cd683afa3a6f99b9e137624899d84d3`: CANCELLED — run [41176460768](https://github.com/DOJOWALK/DOJO-WALK-Customer/actions/runs/41176460768). This is not an Android PASS.
- Earlier Android run for commit `593f86f34d9bab7fe4dfdb0d3b324aa1d65bb77b`: CANCELLED — run [41176282537](https://github.com/DOJOWALK/DOJO-WALK-Customer/actions/runs/41176282537).

These CI results do not establish visual QA on physical devices, real notification delivery, or live support-ticket integration. The audit refresh itself changes documentation only; it does not claim a new runtime test.

## 6. Status

- Notifications: UI-only; integration not implemented.
- Help & Support: FAQ/form UI-only; requests are not transmitted or persisted.
- Backend/Firebase changes: none.
- Android validation for the latest code commit above: not verified because the run was cancelled.
- PR #29: OPEN/Draft; do not merge without explicit approval.
