# DOJO WALK — Centralized Localization Plan

## Goal
Use one translation key per UI message across the Customer App, with locale-specific resources. Screens must not contain repeated English/Hindi/Bengali variants.

## Initial implementation on this branch
- Enabled Flutter generated localization (flutter: generate: true).
- Added l10n.yaml and ARB resources under lib/l10n/.
- Added the initial shared message catalog for English, Hindi and Bengali.
- Added a central registry of India's 22 scheduled languages plus English.
- Only English, Hindi and Bengali are marked available today. Other languages are rollout targets, not falsely advertised as complete.

## Target screen usage
Generated localization should be read from the widget context, e.g. AppLocalizations.of(context).bookWalk. Widgets then contain a key/reference, not three copies of the same message.

## Rollout order
1. Generate localization code and verify CI.
2. Migrate the app root and language preference UI to the generated localization system.
3. Migrate common navigation, buttons, empty/loading/error states.
4. Migrate each feature screen and remove inline three-language helpers.
5. Add each additional language's ARB file only with reviewed translations and plural/date/number formatting checks.
6. Run analyzer, unit/widget tests, Android/Web builds and visual QA before closing the draft PR.

## Safety and correctness rules
- Language selection changes display text only; it must not change canonical IDs, booking payloads, prices, booking statuses or payment logic.
- Persist the language preference and restore it at startup.
- Do not enable a language in Settings until translations cover the released screens.
- Native system widgets use Flutter's localization delegates; DOJO WALK's own strings use generated ARB resources.
- Translations for legal terms, payments, cancellation, emergencies and privacy require human review before release.

## Current limitation
The current Customer App still has inline translations in several screens. The new catalog is the foundation for incremental migration; this commit does not claim that every screen is already migrated or that all Indian languages are live.
