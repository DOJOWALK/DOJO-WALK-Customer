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
