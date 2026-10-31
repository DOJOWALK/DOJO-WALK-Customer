import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/features/booking/models/booking_schedule_rules.dart';

void main() {
  group('BookingScheduleRules.hasOverlap', () {
    test('rejects two slots with the same start time', () {
      final start = DateTime(2026, 11, 5, 8);

      expect(
        BookingScheduleRules.hasOverlap([
          BookingScheduleSlot(start: start, durationMinutes: 30),
          BookingScheduleSlot(start: start, durationMinutes: 20),
        ]),
        isTrue,
      );
    });

    test('allows an adjacent slot that starts exactly at previous end', () {
      final start = DateTime(2026, 11, 5, 8);

      expect(
        BookingScheduleRules.hasOverlap([
          BookingScheduleSlot(start: start, durationMinutes: 30),
          BookingScheduleSlot(
            start: start.add(const Duration(minutes: 30)),
            durationMinutes: 20,
          ),
        ]),
        isFalse,
      );
    });

    test('rejects partially overlapping slots regardless of input order', () {
      final start = DateTime(2026, 11, 5, 8);

      expect(
        BookingScheduleRules.hasOverlap([
          BookingScheduleSlot(
            start: start.add(const Duration(minutes: 20)),
            durationMinutes: 30,
          ),
          BookingScheduleSlot(start: start, durationMinutes: 30),
        ]),
        isTrue,
      );
    });
  });

  group('BookingScheduleRules.isFutureStart', () {
    final now = DateTime(2026, 11, 5, 8, 30);

    test('rejects a start one minute before now', () {
      expect(
        BookingScheduleRules.isFutureStart(
          now.subtract(const Duration(minutes: 1)),
          now,
        ),
        isFalse,
      );
    });

    test('rejects a start exactly at now', () {
      expect(BookingScheduleRules.isFutureStart(now, now), isFalse);
    });

    test('accepts a start one minute after now', () {
      expect(
        BookingScheduleRules.isFutureStart(
          now.add(const Duration(minutes: 1)),
          now,
        ),
        isTrue,
      );
    });
  });

  group('BookingScheduleRules.regularStartDate', () {
    final now = DateTime(2026, 11, 5, 12);

    test('starts today when at least one slot is still in the future', () {
      final today = DateTime(2026, 11, 5);

      expect(
        BookingScheduleRules.regularStartDate(
          now: now,
          slotStarts: [
            DateTime(2026, 11, 5, 7),
            DateTime(2026, 11, 5, 18),
          ],
        ),
        today,
      );
    });

    test('starts tomorrow when no slot today is still in the future', () {
      expect(
        BookingScheduleRules.regularStartDate(
          now: now,
          slotStarts: [
            DateTime(2026, 11, 5, 7),
            DateTime(2026, 11, 5, 12),
          ],
        ),
        DateTime(2026, 11, 6),
      );
    });
  });

  test('sortDates normalizes and sorts dates independent of selection order', () {
    expect(
      BookingScheduleRules.sortDates([
        DateTime(2026, 11, 8, 18),
        DateTime(2026, 11, 6, 9),
        DateTime(2026, 11, 7),
        DateTime(2026, 11, 6, 22),
      ]),
      [
        DateTime(2026, 11, 6),
        DateTime(2026, 11, 7),
        DateTime(2026, 11, 8),
      ],
    );
  });
}
