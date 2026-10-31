import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/features/addresses/models/saved_address.dart';
import '../../../lib/features/home/screens/home_screen.dart';
import '../../../lib/l10n/app_localizations.dart';

Widget _app(Widget home) => MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );

SavedAddress _homeAddress() => SavedAddress(
      id: 'home-1',
      label: 'Home',
      flatHouse: 'A-101',
      buildingSociety: 'Test Society',
      area: 'Sector 1',
      city: 'Noida',
      pincode: '201301',
      isDefault: true,
    );

void main() {
  testWidgets('Home address error can be retried successfully', (tester) async {
    var attempts = 0;
    final address = _homeAddress();

    await tester.pumpWidget(
      _app(
        HomeScreen(
          isSignedIn: () => true,
          loadAddresses: () async {
            attempts++;
            if (attempts == 1) {
              throw StateError('temporary address read failure');
            }
            return [address];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final strings = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(strings.homeSavedAddressLoadError), findsOneWidget);
    expect(find.text('A-101'), findsNothing);

    await tester.tap(find.text(strings.retry));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.textContaining('A-101'), findsOneWidget);
    expect(find.text(strings.homeSavedAddressLoadError), findsNothing);
  });

  testWidgets('Home keeps the saved address visible while refreshing',
      (tester) async {
    var attempts = 0;
    final refresh = Completer<List<SavedAddress>>();

    await tester.pumpWidget(
      _app(
        HomeScreen(
          isSignedIn: () => true,
          loadAddresses: () {
            attempts++;
            if (attempts == 1) {
              return Future.value([_homeAddress()]);
            }
            return refresh.future;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('A-101'), findsOneWidget);
    expect(attempts, 1);

    await tester.drag(find.byType(ListView).first, const Offset(0, 450));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(attempts, 2);
    expect(find.textContaining('A-101'), findsOneWidget);

    refresh.complete([_homeAddress()]);
    await tester.pumpAndSettle();
    expect(find.textContaining('A-101'), findsOneWidget);
  });
}
