import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/app/locale_controller.dart';
import '../../../lib/features/profile/screens/my_dogs_screen.dart';

void main() {
  tearDown(() {
    appLocale.value = const Locale('en');
  });

  testWidgets('My Dogs retry resubscribes and recovers from a stream error',
      (tester) async {
    var attempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MyDogsScreen(
          currentUserId: () => 'customer-test',
          watchDogs: (uid) {
            expect(uid, 'customer-test');
            attempts++;
            if (attempts == 1) {
              return Stream<List<DogListRecord>>.error(
                StateError('temporary pets read failure'),
              );
            }
            return Stream<List<DogListRecord>>.value([
              const DogListRecord(
                id: 'dog-1',
                data: {'name': 'Buddy', 'breed': 'Labrador'},
              ),
            ]);
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Unable to load dogs'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(attempts, 1);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Buddy'), findsOneWidget);
    expect(find.text('Unable to load dogs'), findsNothing);
  });

  testWidgets('My Dogs error and retry copy updates in Hindi and Bengali',
      (tester) async {
    appLocale.value = const Locale('hi');
    await tester.pumpWidget(
      MaterialApp(
        home: MyDogsScreen(
          currentUserId: () => 'customer-test',
          watchDogs: (_) => Stream<List<DogListRecord>>.error(
            StateError('temporary pets read failure'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('कुत्तों की जानकारी नहीं खुल पाई'), findsOneWidget);
    expect(find.text('फिर कोशिश करें'), findsOneWidget);

    appLocale.value = const Locale('bn');
    await tester.pump();

    expect(find.text('কুকুরের তথ্য লোড করা যায়নি'), findsOneWidget);
    expect(find.text('আবার চেষ্টা করুন'), findsOneWidget);
    expect(find.text('कुत्तों की जानकारी नहीं खुल पाई'), findsNothing);
  });

  testWidgets('My Dogs shows loading while the dogs stream is waiting',
      (tester) async {
    final controller = StreamController<List<DogListRecord>>();

    await tester.pumpWidget(
      MaterialApp(
        home: MyDogsScreen(
          currentUserId: () => 'customer-test',
          watchDogs: (_) => controller.stream,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    unawaited(controller.close());
  });

  testWidgets('My Dogs shows loading while the dogs stream is pending',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyDogsScreen(
          currentUserId: () => 'customer-test',
          watchDogs: (_) => Stream<List<DogListRecord>>.multi((_) {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No Dogs Added Yet'), findsNothing);
  });

  testWidgets('My Dogs shows the empty state when no dogs exist',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyDogsScreen(
          currentUserId: () => 'customer-test',
          watchDogs: (_) => Stream<List<DogListRecord>>.value(
            const <DogListRecord>[],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('No Dogs Added Yet'), findsOneWidget);
    expect(find.text('Unable to load dogs'), findsNothing);
  });

  testWidgets('My Dogs shows login required when signed out',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyDogsScreen(
          currentUserId: () => null,
          watchDogs: (_) {
            fail('Dogs stream must not be opened while signed out.');
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Login Required'), findsOneWidget);
    expect(find.text('Please log in to manage your dogs.'), findsOneWidget);
  });
}
