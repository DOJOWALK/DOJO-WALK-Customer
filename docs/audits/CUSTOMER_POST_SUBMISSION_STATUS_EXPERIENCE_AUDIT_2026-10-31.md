# Customer Post-Submission & Booking Status Experience Audit — 2026-10-31

## Scope and evidence

Read-only source audit of Customer branch `chore/remove-app-language-file` for the post-submit confirmation, My Bookings list, booking card, booking details, status mapping, payment display and cancellation affordance.

Files inspected:
- `lib/features/booking/screens/booking_confirmation_screen.dart`
- `lib/features/booking/screens/my_bookings_screen.dart`

This is a source inspection only. No live Firestore records, emulator, device flow, payment provider, backend callable or production Rules were exercised. It does not establish deployed behavior.

Notion constraints reviewed:
- Team 04 — Customer App: backend owns authoritative availability, payment, assignment and walk completion; Customer must handle pending/failure/unavailable states; use Team 01 approved contracts.
- Booking API Contract & Callable Implementation Gate: design direction only; implementation remains BLOCKED pending contract approval. Parent booking, child walk tasks, payment status, assignment status and task lifecycle are separate concepts. Direct-writer cutover is not authorized.

## Verified current behavior

### 1. After submission

In `booking_confirmation_screen.dart`, `_submitBooking()`:
- validates login, dog/address IDs and selected schedule;
- re-reads the selected pet from `users/{uid}/pets/{dogId}`;
- generates a client-side document ID under `bookings`;
- writes directly to `bookings/{id}` with `status: pending`, `walkerId: null`, and a server timestamp for `createdAt`;
- does not initiate availability confirmation, quote, payment verification, assignment or walk-task creation;
- after the Firestore write succeeds, shows a green check icon and “request received” dialog, displays the booking ID, and says the team will confirm;
- the Done action returns to the first route.

The copy correctly describes a request rather than a paid/confirmed booking. However, the green check is a successful document-write indicator, not evidence of service availability, payment, confirmation or Walker assignment.

### 2. My Bookings list

In `my_bookings_screen.dart`:
- listens to Firebase Auth state;
- streams `bookings` filtered by `customerId == current user UID`;
- applies All / Upcoming / Completed / Cancelled filters client-side;
- sorts records by `scheduledAt` descending;
- displays a status badge, first scheduled date/time, booking ID, pickup summary and a derived/legacy saved-price summary;
- opens details using the selected parent booking document.

The list reads parent `bookings` only. It does not read `walk_tasks`, so it cannot yet represent each occurrence in the approved parent-booking/child-task design. Choose-Dates records are sorted and summarized by their top-level/first `scheduledAt`, not by all selected occurrences.

### 3. Status vocabulary and presentation

Current UI mapping:
- `pending` → Pending;
- `finding_walker` → Finding Walker;
- `walker_assigned` / `assigned` → Walker Assigned;
- `walker_arriving` → Walker Arriving;
- `confirmed` / `accepted` → Confirmed;
- `in_progress` / `in progress` → In Progress;
- `completed` → Completed;
- `cancelled` / `canceled` → Cancelled;
- unknown values are rendered as a raw string with underscores replaced by spaces.

The Upcoming filter currently includes `pending`, `finding_walker`, `walker_assigned`, `walker_arriving`, `confirmed`, `assigned`, `accepted`, and also `in_progress` / `in progress`.

Notion's V1 design direction separates parent booking, payment, assignment and individual walk-task states. The UI currently has one booking-level status and does not present separate payment or assignment states. Candidate states such as `pending_confirmation`, `ready_for_assignment`, `payment_review`, `partially_completed`, and `support_review` are not explicitly mapped; they fall through to raw text. The canonical values and transition matrix remain unapproved, so this audit does not recommend adding guessed mappings.

### 4. Booking details and payment/Walker information

The details screen streams the parent booking document again. It displays:
- booking-level status;
- schedule and selected dates;
- dog and pickup snapshot details;
- a Walker section based on `walkerId`, otherwise “Not assigned”;
- a price section derived from saved schedule prices or legacy `totalAmount` / `additionalCharges`.

It does not display a distinct payment status, verified payment reference, assignment status/attempt state, or child walk-task timeline. A displayed saved amount is not proof that payment has been initiated or verified. The current Customer booking writer does not add a server quote or payment status.

### 5. Cancellation affordance — high-risk finding

The details screen enables a cancellation request for statuses accepted by `_isUpcoming()`. That helper includes `in_progress`. The cancellation action then directly runs a client Firestore transaction and writes `cancelRequest.status: pending` after checking the booking owner, current status and absence of an existing request.

This creates a UI/business-rule mismatch: an in-progress booking is considered eligible for the ordinary cancellation-request path. DOJO WALK's live-walk safety direction says a running walk is not ordinarily cancelled; emergency stop requires a safe handover. The backend cancellation contract and authoritative transition rules are not approved, so the Customer client must not be treated as the authority for this decision.

The current cancellation write is also a direct Customer-to-Firestore mutation, not a Team 01-approved cancellation callable. Do not change it to an invented callable name or alter Rules from this repository.

## Findings and severity

| ID | Severity | Finding | Evidence / impact |
|---|---|---|---|
| CUST-POST-01 | High | Cancellation helper includes `in_progress` as Upcoming | Ordinary cancellation request button can be shown during an active walk. Requires coordinated policy/API decision and backend enforcement. |
| CUST-POST-02 | High / dependency | Booking submission still directly writes parent booking | No authoritative availability, quote, payment verification, task creation or assignment occurs in this client flow. Existing direct writer must remain until approved coordinated cutover; do not imply booking is confirmed. |
| CUST-POST-03 | Medium | Payment status is not represented separately | Price display is derived from saved price fields; no payment-state UI or verified transaction evidence. |
| CUST-POST-04 | Medium | Parent-only history view | No child `walk_tasks` occurrence view; multi-date/multi-walk progress cannot be represented per occurrence yet. |
| CUST-POST-05 | Medium | Status mapping is partial and mixes lifecycle concepts | Some candidate parent states display raw; assignment/payment/task states are not independently represented. |
| CUST-POST-06 | Medium | Choose-Dates history is first-date oriented | Parent list sorting and card summary use `scheduledAt` / first preferred time rather than a per-date task timeline. |
| CUST-POST-07 | Low | Green success icon follows a successful client write | Text says request received/team will confirm, which is appropriate; keep visual semantics clearly “request submitted”, not paid/confirmed. |

## Safe next steps

1. Keep PR #29 Draft and preserve the existing direct writer until Team 01 publishes and approves the callable/DTO and coordinated cutover plan.
2. Raise CUST-POST-01 with Product + Team 01: define exactly which booking/task states allow cancellation requests, and ensure in-progress walk emergency handling is separate. Do not implement an assumed callable or client-only workaround.
3. After the canonical parent/payment/assignment/task status contract is approved, implement explicit UI adapters and separate status sections from authoritative fields only.
4. After the child-task read contract is approved, add per-occurrence history/timeline for Choose-Dates and Regular bookings; do not invent a `walk_tasks` query shape.
5. Add widget/emulator tests for request submitted vs confirmed, pending/failed payment, assignment pending/failed, multiple selected dates, unknown status, cancellation before start, and cancellation attempt during an active walk. Tests must use approved contract fixtures.

## Change and verification record

- Documentation-only audit file.
- No Dart source changed.
- No Firebase/backend repository, Rules, Console, or live data changed.
- No new branch created.
- CI for this documentation commit must be checked separately; this document does not claim a test or production PASS.
