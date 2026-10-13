
import 'package:flutter/material.dart';

final ValueNotifier<Locale> appLocale =
    ValueNotifier<Locale>(const Locale('en'));

const List<Locale> dojoSupportedLocales = [
  Locale('en'),
  Locale('hi'),
  Locale('bn'),
];

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
