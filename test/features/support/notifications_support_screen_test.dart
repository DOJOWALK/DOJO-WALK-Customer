import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/app/theme.dart';
import '../../../lib/features/notifications/screens/notifications_screen.dart';
import '../../../lib/features/support/screens/help_support_screen.dart';
import '../../../lib/l10n/app_localizations.dart';

Widget _localizedApp(Widget child, {String languageCode = 'en'}) {
  return MaterialApp(
    locale: Locale(languageCode),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: DojoWalkTheme.light(),
    home: child,
  );
}

Future<void> _scrollToSupportForm(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -900));
  await tester.pumpAndSettle();
}

void main() {
  group('Customer notifications screen', () {
    testWidgets('shows honest not-connected empty state in English', (tester) async {
      await tester.pumpWidget(_localizedApp(const NotificationsScreen()));

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('No notifications yet'), findsOneWidget);
      expect(
        find.textContaining('when notifications are connected'),
        findsOneWidget,
      );
    });

    testWidgets('renders localized empty state in Hindi and Bengali', (tester) async {
      await tester.pumpWidget(
        _localizedApp(const NotificationsScreen(), languageCode: 'hi'),
      );
      expect(find.text('अभी कोई नोटिफ़िकेशन नहीं है'), findsOneWidget);
      expect(find.textContaining('नोटिफ़िकेशन सेवा जुड़ने के बाद'), findsOneWidget);

      await tester.pumpWidget(
        _localizedApp(const NotificationsScreen(), languageCode: 'bn'),
      );
      expect(find.text('এখনও কোনো বিজ্ঞপ্তি নেই'), findsOneWidget);
      expect(find.textContaining('বিজ্ঞপ্তি পরিষেবা যুক্ত হলে'), findsOneWidget);
    });
  });

  group('Customer Help & Support screen', () {
    testWidgets('shows FAQ and explicit not-connected disclosure', (tester) async {
      await tester.pumpWidget(_localizedApp(const HelpSupportScreen()));

      final l10n = AppLocalizations.of(tester.element(find.byType(HelpSupportScreen)));
      expect(find.text(l10n.helpAndSupport), findsOneWidget);
      expect(find.text(l10n.supportFaqTitle), findsOneWidget);
      await _scrollToSupportForm(tester);
      expect(find.text(l10n.supportFormNotConnected), findsOneWidget);
      expect(find.text(l10n.supportSubmitRequest), findsOneWidget);
    });

    testWidgets('expands an FAQ answer', (tester) async {
      await tester.pumpWidget(_localizedApp(const HelpSupportScreen()));

      await tester.tap(find.text('How do I book a dog walk?'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Open Home, tap Book a Walk'),
        findsOneWidget,
      );
    });

    testWidgets('validates short message and does not submit it', (tester) async {
      await tester.pumpWidget(_localizedApp(const HelpSupportScreen()));
      await _scrollToSupportForm(tester);

      await tester.tap(find.text('Submit Support Request'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter at least 10 characters.'), findsOneWidget);
      expect(find.textContaining('Your message is not sent yet.'), findsNothing);
    });

    testWidgets('valid message still clearly reports that it was not sent', (tester) async {
      await tester.pumpWidget(_localizedApp(const HelpSupportScreen()));
      await _scrollToSupportForm(tester);

      await tester.enterText(
        find.byType(TextFormField),
        'I need help with my booking.',
      );
      await tester.tap(find.text('Submit Support Request'));
      await tester.pump();

      final l10n = AppLocalizations.of(tester.element(find.byType(HelpSupportScreen)));
      expect(find.text(l10n.supportMessageNotSent), findsOneWidget);
      expect(find.text(l10n.supportFormNotConnected), findsOneWidget);
    });

    testWidgets('renders localized support disclosure in Hindi and Bengali', (tester) async {
      await tester.pumpWidget(
        _localizedApp(const HelpSupportScreen(), languageCode: 'hi'),
      );
      expect(find.text('मदद और सहायता'), findsOneWidget);
      await _scrollToSupportForm(tester);
      var l10n = AppLocalizations.of(tester.element(find.byType(HelpSupportScreen)));
      expect(find.text(l10n.supportFormNotConnected), findsOneWidget);

      await tester.pumpWidget(
        _localizedApp(const HelpSupportScreen(), languageCode: 'bn'),
      );
      expect(find.text('সহায়তা ও সমর্থন'), findsOneWidget);
      await _scrollToSupportForm(tester);
      l10n = AppLocalizations.of(tester.element(find.byType(HelpSupportScreen)));
      expect(find.text(l10n.supportFormNotConnected), findsOneWidget);
    });
  });
}
