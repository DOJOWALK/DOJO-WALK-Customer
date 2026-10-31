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


    testWidgets(
      'blocks Continue when any selected date contains a past time',
      (tester) async {
        final fixedNow = DateTime(2026, 11, 5, 12);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: ChooseWalkScreen(clock: () => fixedNow),
          ),
        );

        await tester.tap(find.text('Choose Dates'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add / Select Date'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('6').last);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Locate the action by widget type so the test does not depend on
        // the translated button copy or whether its ListView child is built
        // just before scrolling.
        final continueButton = find.byType(FilledButton).last;
        await tester.ensureVisible(continueButton);
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        // The first selected date is today and its default 7 AM slot is past.
        // Validation must stop before login/profile navigation is attempted.
        expect(find.textContaining('5 Nov 2026'), findsOneWidget);
        expect(find.textContaining('7:00 AM'), findsOneWidget);
        expect(find.text(strings.loginToContinueBooking), findsNothing);
      },
    );

    testWidgets('reselecting an already selected date does not duplicate it', (tester) async {
      await tester.pumpWidget(_testApp(const Locale('en')));
      await tester.tap(find.text('Choose Dates'));
      await tester.pumpAndSettle();

      final selectedDateChip = find.byWidgetPredicate(
        (widget) =>
            widget is ChoiceChip &&
            widget.label is Text &&
            ((widget.label as Text).data ?? '').startsWith('5 '),
      );

      await tester.tap(find.text('Add / Select Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(selectedDateChip, findsOneWidget);

      await tester.tap(find.text('Add / Select Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(selectedDateChip, findsOneWidget);
    });
  });
}
