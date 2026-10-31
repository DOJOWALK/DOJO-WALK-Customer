import 'package:flutter_test/flutter_test.dart';
import '../../lib/l10n/app_localizations.dart';

void main() {
  group('Authentication localization', () {
    test('OTP copy is available in all currently supported locales', () async {
      final cases = <String, Map<String, String>>{
        'en': {'title': 'Verify OTP', 'invalid': 'Invalid OTP. Please check and try again.'},
        'hi': {'title': 'OTP सत्यापित करें', 'invalid': 'गलत OTP है। जाँचकर फिर कोशिश करें।'},
        'bn': {'title': 'OTP যাচাই করুন', 'invalid': 'ভুল OTP। যাচাই করে আবার চেষ্টা করুন।'},
      };

      for (final entry in cases.entries) {
        final strings = await AppLocalizations.delegate.load(Locale(entry.key));
        expect(strings.otpVerifyTitle, entry.value['title']);
        expect(strings.otpInvalidCode, entry.value['invalid']);
        expect(strings.otpChangeMobile, isNotEmpty);
        expect(strings.otpResendFailed, isNotEmpty);
      }
    });
  });
}
