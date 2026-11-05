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

## India-wide language rollout matrix

The registry intentionally lists English plus all 22 languages in the Eighth Schedule. A registry entry is not the same as a shipped translation. Settings must use `availableDojoLanguages`, so only reviewed, end-to-end supported languages can be selected.

| Language | Locale code | Current translation status | Selectable |
|---|---|---|---|
| English | en | ARB catalog present | Yes |
| Hindi | hi | ARB catalog present; review/coverage still ongoing | Yes |
| Bengali | bn | ARB catalog present; review/coverage still ongoing | Yes |
| Assamese | as | Translation rollout pending | No |
| Bodo | brx | Translation rollout pending | No |
| Dogri | doi | Translation rollout pending | No |
| Gujarati | gu | Translation rollout pending | No |
| Kannada | kn | Translation rollout pending | No |
| Kashmiri | ks | Translation rollout pending | No |
| Konkani | kok | Translation rollout pending | No |
| Maithili | mai | Translation rollout pending | No |
| Malayalam | ml | Translation rollout pending | No |
| Manipuri (Meitei) | mni | Translation rollout pending | No |
| Marathi | mr | Translation rollout pending | No |
| Nepali | ne | Translation rollout pending | No |
| Odia | or | Translation rollout pending | No |
| Punjabi | pa | Translation rollout pending | No |
| Sanskrit | sa | Translation rollout pending | No |
| Santali | sat | Translation rollout pending | No |
| Sindhi | sd | Translation rollout pending | No |
| Tamil | ta | Translation rollout pending | No |
| Telugu | te | Translation rollout pending | No |
| Urdu | ur | Translation rollout pending | No |

### Release gate for each new language
1. Create the locale ARB from the current English source catalog; do not copy English strings and mark them as translated.
2. Translate every released customer-facing key, including errors, booking states, support, privacy, payment and cancellation text.
3. Check placeholders, plural/date/number formatting, right-to-left layout for Urdu/Kashmiri where applicable, and glyph/font rendering.
4. Add the locale to Flutter's supported locale list only when generated localization and widget code support it.
5. Enable it in Settings only after localization completeness tests, analyzer/tests, Android/Web builds and visual QA pass.
6. Record human review for legal, payment, safety and emergency wording before enabling it for customers.

The registry test now asserts the exact 23 locale codes and checks for duplicates. This verifies registry coverage only; it does not certify translation completeness.
