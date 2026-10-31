import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/features/booking/screens/choose_walk_screen.dart';
import '../../../lib/l10n/app_localizations.dart';

Widget _testApp(Locale locale) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const ChooseWalkScreen(),
  );
}

void main() {
  group('ChooseWalkScreen booking type selection', () {
    for (final locale in const [Locale('en'), Locale('hi'), Locale('bn')]) {
      testWidgets('shows translated booking choices for ${locale.languageCode}', (tester) async {
        await tester.pumpWidget(_testApp(locale));

        final strings = await AppLocalizations.delegate.load(locale);
        expect(find.text(strings.bookWalk), findsOneWidget);
        expect(find.text(strings.walkNow), findsOneWidget);
        expect(find.text(strings.dailyWalk), findsOneWidget);
        expect(find.text(strings.chooseDates), findsOneWidget);
        expect(find.text(strings.continueDogSelection), findsOneWidget);
      });
    }

    testWidgets('Walk Now reveals duration options without schedule controls', (tester) async {
      await tester.pumpWidget(_testApp(const Locale('en')));
      await tester.tap(find.text('Walk Now'));
      await tester.pumpAndSettle();

      expect(find.text('Walk Now request'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      for (final minutes in [20, 30, 45, 60]) {
        expect(find.text('$minutes min'), findsOneWidget);
      }
      expect(find.text('Select dates'), findsNothing);
      expect(find.text('Walks per day'), findsNothing);
    });

    testWidgets('custom duration rejects values below 20 and accepts 60 minutes', (tester) async {
      await tester.pumpWidget(_testApp(const Locale('en')));
      await tester.tap(find.text('Walk Now'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Custom duration'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom duration'));
      await tester.pumpAndSettle();

      final input = find.byType(TextField);
      await tester.enterText(input, '19');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Custom duration'), findsOneWidget);
      expect(find.text('Enter between 20 and 60 minutes.'), findsOneWidget);

      await tester.enterText(input, '60');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('60 min'), findsOneWidget);
    });

    testWidgets('Daily Walk allows selecting one, two, or three walks per day', (tester) async {
      await tester.pumpWidget(_testApp(const Locale('en')));
      await tester.tap(find.text('Daily Walk'));
      await tester.pumpAndSettle();

      expect(find.text('Daily plan'), findsOneWidget);
      expect(find.text('Walks per day'), findsOneWidget);
      expect(find.text('1 Walk'), findsOneWidget);
      expect(find.text('2 Walks'), findsOneWidget);
      expect(find.text('3 Walks'), findsOneWidget);

      await tester.ensureVisible(find.text('3 Walks'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3 Walks'));
      await tester.pumpAndSettle();

      expect(find.text('Walk 1'), findsOneWidget);
      expect(find.text('Walk 2'), findsOneWidget);
      expect(find.text('Walk 3'), findsOneWidget);
    });

    testWidgets('Choose Dates reveals date selection controls', (tester) async {
      await tester.pumpWidget(_testApp(const Locale('en')));
      await tester.tap(find.text('Choose Dates'));
      await tester.pumpAndSettle();

      expect(find.text('Select dates'), findsOneWidget);
      expect(find.text('Add / Select Date'), findsOneWidget);
      expect(find.textContaining('Editing:'), findsOneWidget);
      expect(find.text('Walks per day'), findsNothing);
    });
  });
}
