import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Single runtime locale state used by the app.
///
/// Persisted preference is restored during app startup. UI widgets should
/// consume generated AppLocalizations instead of embedding language variants.
final ValueNotifier<Locale> appLocale =
    ValueNotifier<Locale>(const Locale('en'));

/// Supported runtime locales come from the generated localization catalog,
/// so the app root and locale controller cannot drift apart.
List<Locale> get dojoSupportedLocales => AppLocalizations.supportedLocales;

/// Compatibility helper for screens that have not yet migrated to ARB keys.
/// New or migrated screens should use AppLocalizations.of(context).
@Deprecated('Use AppLocalizations.of(context) and generated ARB keys.')
String appText({
  required String en,
  required String hi,
  required String bn,
}) {
  switch (appLocale.value.languageCode) {
    case 'hi':
      return hi;
    case 'bn':
      return bn;
    default:
      return en;
  }
}
