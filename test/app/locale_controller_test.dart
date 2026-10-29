import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/app/locale_controller.dart';

void main() {
  setUp(() {
    appLocale.value = const Locale('en');
  });

  tearDown(() {
    appLocale.value = const Locale('en');
  });

  group('DOJO WALK app locale', () {
    test('supports English, Hindi and Bangla', () {
      expect(
        dojoSupportedLocales.map((locale) => locale.languageCode).toList(),
        <String>['en', 'hi', 'bn'],
      );
    });

    test('returns English copy for English locale', () {
      appLocale.value = const Locale('en');

      expect(
        appText(en: 'Account', hi: 'खाता', bn: 'অ্যাকাউন্ট'),
        'Account',
      );
    });

    test('returns Hindi copy when Hindi is selected', () {
      appLocale.value = const Locale('hi');

      expect(
        appText(en: 'Account', hi: 'खाता', bn: 'অ্যাকাউন্ট'),
        'खाता',
      );
    });

    test('returns Bangla copy when Bangla is selected', () {
      appLocale.value = const Locale('bn');

      expect(
        appText(en: 'Account', hi: 'खाता', bn: 'অ্যাকাউন্ট'),
        'অ্যাকাউন্ট',
      );
    });

    test('falls back to English for an unsupported locale', () {
      appLocale.value = const Locale('fr');

      expect(
        appText(en: 'Account', hi: 'खाता', bn: 'অ্যাকাউন্ট'),
        'Account',
      );
    });
  });
}
