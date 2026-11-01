import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_walk_customer/app/app_language.dart';

void main() {
  const english = 'Home';
  const hindi = 'होम';
  const bengali = 'হোম';

  setUp(() {
    appLocale.value = const Locale('en');
  });

  group('appText', () {
    test('returns English text for the default English locale', () {
      expect(
        appText(en: english, hi: hindi, bn: bengali),
        english,
      );
    });

    test('returns Hindi text when Hindi is selected', () {
      appLocale.value = const Locale('hi');

      expect(
        appText(en: english, hi: hindi, bn: bengali),
        hindi,
      );
    });

    test('returns Bengali text when Bengali is selected', () {
      appLocale.value = const Locale('bn');

      expect(
        appText(en: english, hi: hindi, bn: bengali),
        bengali,
      );
    });

    test('falls back to English for an unsupported locale', () {
      appLocale.value = const Locale('fr');

      expect(
        appText(en: english, hi: hindi, bn: bengali),
        english,
      );
    });
  });
}
