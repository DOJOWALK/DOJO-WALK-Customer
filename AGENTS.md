# DOJO WALK Customer App — AI Contributor Instructions

## Project scope
This is the DOJO WALK customer Flutter app. The root `pubspec.yaml` includes Flutter localization, Firebase Auth, Firestore, Storage, image picker, Google Maps, geolocation, geocoding, shared preferences, and package information.

## Required workflow
1. Inspect the relevant UI, models, services, localization resources, and tests before editing. Follow existing project patterns.
2. Preserve existing Firebase contracts and compatibility with the Partner, Admin, and Firebase repositories.
3. Use the repository's Flutter/Dart configuration. Run `flutter pub get`, `flutter analyze`, and relevant `flutter test` tests where available.
4. Add tests for booking validation, loading/error states, localization, permissions, and critical customer journeys when relevant.
5. Report exact commands and results. Do not mark unrun tests as PASS.

## Product constraints
- Booking is custom-scheduled: selected dates, time slots, walks per day, and duration; duration is 20–60 minutes and dog count is capped at four.
- Check availability before payment. Do not allow payment for an unavailable slot. Preserve same-walker assignment behavior and the documented fallback process.
- Cash and coupon flows must not be reintroduced.
- Live walk tracking must display only verified backend/session state. Do not fabricate GPS, walker assignment, payment, or completion status.
- Preserve localization support, including Hindi and English, and existing language architecture.

## Security and privacy
Never expose walker/customer private details, precise addresses, tokens, payment credentials, or KYC data in logs or UI beyond approved product requirements. Do not put secrets in the app bundle. Client validation never replaces backend authorization.

## Pull requests
Use a feature branch, never commit directly to `main`. Include affected customer journeys, screenshots for UI changes, localization impact, tests, and rollback notes. No production deploy or merge without owner approval.


## Mandatory DOJO WALK engineering operating rules (Notion-aligned)

Follow the Notion AI Engineering Control Center and Four Team AI Coding Instructions. Central Task Register: https://app.notion.com/p/2f476768c6f14aec9e70bf04afd83df8

Before editing, inspect the assigned task and linked spec, this repository's source and instructions, working tree, active branch, recent commits and open PRs. Record task ID, branch, current commit SHA, scope, acceptance criteria, dependencies and test plan. Continue the exact active task branch; do not create a new branch merely because a chat/session changed. Check for duplicate work first. If a required decision or contract is missing, stop and report BLOCKED.

Keep the smallest safe scope. Do not silently change product policy, API/data contracts, schema, permissions, security rules or payment behavior. Team 01 owns shared backend contracts; notify affected client teams before contract changes. Never force-push, delete branches, close historical PRs or overwrite unmerged work without explicit approval.

Run relevant checks and record exact commands/workflows, timestamps, results and exact commit SHA tested. Use PASS only for checks that passed; FAIL for failures; NOT RUN for checks not executed. PRs and handoffs must include task ID, scope, risk, affected repositories, branch, PR, SHA, contract/schema version where relevant, test evidence, blockers and rollback notes.

Obtain independent review for security, permissions, payment, KYC, GPS/location and migration changes. Do not weaken authentication or security Rules to make tests pass. Production Rules, Storage Rules, Functions, secrets, destructive migrations and production data writes require explicit authorization. Merge/deploy only after required human approval. A green CI result applies only to checks run on that exact SHA and is not blanket production approval.

Do not introduce coupon or cash-payment flows. Protect KYC, selfies, customer data, GPS/location history, payment records and credentials. Do not mark work complete until acceptance criteria, test evidence, review/approval and PR/release state are accurately recorded.

## Customer-specific guardrails
Booking configuration, availability, pricing, payment status, confirmation, walker assignment and walk completion must follow approved backend contracts and remain backend-authoritative. Do not introduce coupons or cash payments. Never infer availability or mark a booking paid/confirmed from client-only state. Handle pending/failure/retry/duplicate callbacks and stale state explicitly.
