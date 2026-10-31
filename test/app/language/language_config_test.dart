import 'package:flutter_test/flutter_test.dart';

import '../../../lib/app/language/language_config.dart';

void main() {
  group('DOJO WALK language registry', () {
    test('only reviewed English, Hindi and Bengali are selectable', () {
      expect(
        availableDojoLanguages.map((language) => language.code).toList(),
        ['en', 'hi', 'bn'],
      );
      expect(availableDojoLanguages.every((language) => language.isAvailable), isTrue);
    });

    test('language codes are unique', () {
      final codes = dojoLanguages.map((language) => language.code).toList();

      expect(codes.toSet().length, codes.length);
    });

    test('every registered language has native and English names', () {
      for (final language in dojoLanguages) {
        expect(language.code, isNotEmpty);
        expect(language.nativeName, isNotEmpty);
        expect(language.englishName, isNotEmpty);
      }
    });

    test('lookup returns the matching language', () {
      expect(dojoLanguageByCode('hi').nativeName, 'हिन्दी');
      expect(dojoLanguageByCode('bn').nativeName, 'বাংলা');
    });

    test('unknown language safely falls back to English', () {
      final language = dojoLanguageByCode('unknown');

      expect(language.code, 'en');
      expect(language.nativeName, 'English');
    });

    test('unreviewed languages remain unavailable for selection', () {
      final unavailable = dojoLanguages.where((language) => !language.isAvailable);

      expect(unavailable, isNotEmpty);
      expect(unavailable.any((language) => language.code == 'gu'), isTrue);
      expect(unavailable.any((language) => language.code == 'ta'), isTrue);
      expect(unavailable.any((language) => language.code == 'te'), isTrue);
    });
  });
}
