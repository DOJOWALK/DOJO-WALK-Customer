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

Future<void> _openSelector(WidgetTester tester) async {
  final strings = await AppLocalizations.delegate.load(const Locale('en'));
  await tester.tap(find.text(strings.homeSelectLocation));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

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
            if (attempts == 1) throw StateError('temporary address read failure');
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
            if (attempts == 1) return Future.value([_homeAddress()]);
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

  testWidgets('Home shows loading text while saved addresses are pending',
      (tester) async {
    final pending = Completer<List<SavedAddress>>();
    var attempts = 0;
    await tester.pumpWidget(
      _app(
        HomeScreen(
          isSignedIn: () => true,
          loadAddresses: () {
            attempts++;
            return pending.future;
          },
        ),
      ),
    );
    await tester.pump();

    final strings = await AppLocalizations.delegate.load(const Locale('en'));
    expect(attempts, 1);
    expect(find.text(strings.homeLoadingSavedAddress), findsOneWidget);

    pending.complete([_homeAddress()]);
    await tester.pumpAndSettle();
    expect(find.textContaining('A-101'), findsOneWidget);
  });

  testWidgets('Home shows location prompt when customer has no saved address',
      (tester) async {
    await tester.pumpWidget(
      _app(
        HomeScreen(
          isSignedIn: () => true,
          loadAddresses: () async => <SavedAddress>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final strings = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(strings.homeSelectLocation), findsOneWidget);
    expect(find.text(strings.homeSavedAddressLoadError), findsNothing);
  });

  testWidgets('Home does not load saved addresses while signed out',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      _app(
        HomeScreen(
          isSignedIn: () => false,
          loadAddresses: () async {
            attempts++;
            return [_homeAddress()];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final strings = await AppLocalizations.delegate.load(const Locale('en'));
    expect(attempts, 0);
    expect(find.text(strings.homeSelectLocation), findsOneWidget);
  });

  testWidgets('Home address selector shows loading state', (tester) async {
    final stream = StreamController<List<SavedAddress>>();
    await tester.pumpWidget(
      _app(
        HomeScreen(
          isSignedIn: () => true,
          loadAddresses: () async => <SavedAddress>[],
          watchAddresses: () => stream.stream,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _openSelector(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    // Do not await StreamController.close(): StreamBuilder teardown may leave
    // the modal route subscription alive until the next event-loop turn.
    unawaited(stream.close());
  });

  testWidgets('Home address selector shows empty state', (tester) async {
    final stream = StreamController<List<SavedAddress>>();
    await tester.pumpWidget(
      _app(
        HomeScreen(
          isSignedIn: () => true,
          loadAddresses: () async => <SavedAddress>[],
          watchAddresses: () => stream.stream,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _openSelector(tester);
    stream.add(<SavedAddress>[]);
    await tester.pump();

    final strings = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(strings.homeNoSavedAddresses), findsOneWidget);
    expect(find.text(strings.homeAddAddressForPickup), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await stream.close();
  });

  testWidgets('Home address selector shows error state', (tester) async {
    final stream = StreamController<List<SavedAddress>>();
    await tester.pumpWidget(
      _app(
        HomeScreen(
          isSignedIn: () => true,
          loadAddresses: () async => <SavedAddress>[],
          watchAddresses: () => stream.stream,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _openSelector(tester);
    stream.addError(StateError('temporary stream failure'));
    await tester.pump();

    final strings = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(strings.homeAddressesLoadError), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await stream.close();
  });
}
