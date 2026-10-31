import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/features/profile/screens/my_dogs_screen.dart';

void main() {
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
    await controller.close();
  });

  testWidgets('My Dogs shows the empty state when no dogs exist',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyDogsScreen(
          currentUserId: () => 'customer-test',
          watchDogs: (_) => Stream.value(const <DogListRecord>[]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Dogs Added Yet'), findsOneWidget);
    expect(find.text('Add your dog once and select it for future bookings.'),
        findsOneWidget);
  });

  testWidgets('My Dogs shows login required when signed out',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyDogsScreen(
          currentUserId: () => null,
          watchDogs: (_) => const Stream.empty(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login Required'), findsOneWidget);
    expect(find.text('Please log in to manage your dogs.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
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
