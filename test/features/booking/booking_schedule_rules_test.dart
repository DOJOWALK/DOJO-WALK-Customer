import 'package:flutter_test/flutter_test.dart';

import '../../../lib/features/booking/models/booking_schedule_rules.dart';

void main() {
  group('BookingScheduleRules.hasOverlap', () {
    final day = DateTime(2026, 11, 5);

    test('rejects two slots with the same start time', () {
      final slots = [
        BookingScheduleSlot(
          start: DateTime(day.year, day.month, day.day, 7),
          durationMinutes: 30,
        ),
        BookingScheduleSlot(
          start: DateTime(day.year, day.month, day.day, 7),
          durationMinutes: 20,
        ),
      ];

      expect(BookingScheduleRules.hasOverlap(slots), isTrue);
    });

    test('allows exactly adjacent slots', () {
      final slots = [
        BookingScheduleSlot(
          start: DateTime(day.year, day.month, day.day, 7),
          durationMinutes: 30,
        ),
        BookingScheduleSlot(
          start: DateTime(day.year, day.month, day.day, 7, 30),
          durationMinutes: 20,
        ),
      ];

      expect(BookingScheduleRules.hasOverlap(slots), isFalse);
    });

    test('detects overlap even when slots are supplied out of order', () {
      final slots = [
        BookingScheduleSlot(
          start: DateTime(day.year, day.month, day.day, 8),
          durationMinutes: 30,
        ),
        BookingScheduleSlot(
          start: DateTime(day.year, day.month, day.day, 7),
          durationMinutes: 90,
        ),
      ];

      expect(BookingScheduleRules.hasOverlap(slots), isTrue);
    });

    test('does not report overlap for fewer than two slots', () {
      expect(BookingScheduleRules.hasOverlap(const []), isFalse);
      expect(
        BookingScheduleRules.hasOverlap([
          BookingScheduleSlot(
            start: DateTime(day.year, day.month, day.day, 7),
            durationMinutes: 30,
          ),
        ]),
        isFalse,
      );
    });
  });

  group('BookingScheduleRules.isFutureStart', () {
    final now = DateTime(2026, 11, 5, 12);

    test('rejects a past start time', () {
      expect(
        BookingScheduleRules.isFutureStart(
          DateTime(2026, 11, 5, 11, 59),
          now,
        ),
        isFalse,
      );
    });

    test('rejects a start time exactly equal to now', () {
      expect(BookingScheduleRules.isFutureStart(now, now), isFalse);
    });

    test('accepts a future start time', () {
      expect(
        BookingScheduleRules.isFutureStart(
          DateTime(2026, 11, 5, 12, 1),
          now,
        ),
        isTrue,
      );
    });
  });

  group('BookingScheduleRules.regularStartDate', () {
    final now = DateTime(2026, 11, 5, 12);

    test('starts today when at least one selected time is still future', () {
      final result = BookingScheduleRules.regularStartDate(
        now: now,
        slotStarts: [
          DateTime(2026, 11, 5, 7),
          DateTime(2026, 11, 5, 18),
        ],
      );

      expect(result, DateTime(2026, 11, 5));
    });

    test('starts tomorrow when every selected time today has elapsed', () {
      final result = BookingScheduleRules.regularStartDate(
        now: now,
        slotStarts: [
          DateTime(2026, 11, 5, 7),
          DateTime(2026, 11, 5, 11, 59),
          now,
        ],
      );

      expect(result, DateTime(2026, 11, 6));
    });

    test('starts tomorrow when no slots are supplied', () {
      final result = BookingScheduleRules.regularStartDate(
        now: now,
        slotStarts: const [],
      );

      expect(result, DateTime(2026, 11, 6));
    });
  });

  group('BookingScheduleRules.sortDates', () {
    test('normalizes and sorts dates chronologically regardless of input order', () {
      final result = BookingScheduleRules.sortDates([
        DateTime(2026, 11, 8, 18),
        DateTime(2026, 11, 5, 9),
        DateTime(2026, 11, 6, 22),
        DateTime(2026, 11, 5, 23),
      ]);

      expect(
        result,
        [
          DateTime(2026, 11, 5),
          DateTime(2026, 11, 6),
          DateTime(2026, 11, 8),
        ],
      );
    });
  });
}
