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
}
