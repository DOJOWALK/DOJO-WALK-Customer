import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_walk_customer/features/booking/models/booking_date_calculator.dart';

void main() {
  group('BookingDateCalculator.dateOnly', () {
    test('normalizes a timestamp without changing its calendar date', () {
      final result = BookingDateCalculator.dateOnly(
        DateTime(2028, 6, 14, 23, 59, 58),
      );

      expect(result, DateTime(2028, 6, 14));
    });
  });

  group('Monthly Package inclusive 28-day term', () {
    test('ends 27 days after the start date', () {
      expect(
        BookingDateCalculator.monthlyPackageEndDate(DateTime(2026, 10, 30)),
        DateTime(2026, 11, 26),
      );
    });

    test('handles year rollover', () {
      expect(
        BookingDateCalculator.monthlyPackageEndDate(DateTime(2026, 12, 20)),
        DateTime(2027, 1, 16),
      );
    });

    test('includes leap day when it falls within the 28-day term', () {
      expect(
        BookingDateCalculator.monthlyPackageEndDate(DateTime(2028, 2, 1)),
        DateTime(2028, 2, 28),
      );
      expect(
        BookingDateCalculator.monthlyPackageEndDate(DateTime(2028, 2, 15)),
        DateTime(2028, 3, 13),
      );
    });
  });

  group('Daily Continuous month-end candidate policies', () {
    test('preserveOriginalAnchorDay returns to the 31st after February', () {
      final policy = DailyCycleAnchorPolicy.preserveOriginalAnchorDay;

      expect(
        BookingDateCalculator.dailyContinuousCycleStart(
          anchorDate: DateTime(2027, 1, 31),
          cycleIndex: 1,
          policy: policy,
        ),
        DateTime(2027, 2, 28),
      );
      expect(
        BookingDateCalculator.dailyContinuousCycleStart(
          anchorDate: DateTime(2027, 1, 31),
          cycleIndex: 2,
          policy: policy,
        ),
        DateTime(2027, 3, 31),
      );
    });

    test('rollForwardFromPreviousCycle retains the clamped day', () {
      final policy = DailyCycleAnchorPolicy.rollForwardFromPreviousCycle;

      expect(
        BookingDateCalculator.dailyContinuousCycleStart(
          anchorDate: DateTime(2027, 1, 31),
          cycleIndex: 1,
          policy: policy,
        ),
        DateTime(2027, 2, 28),
      );
      expect(
        BookingDateCalculator.dailyContinuousCycleStart(
          anchorDate: DateTime(2027, 1, 31),
          cycleIndex: 2,
          policy: policy,
        ),
        DateTime(2027, 3, 28),
      );
    });

    test('handles leap-year February under either candidate policy', () {
      for (final policy in DailyCycleAnchorPolicy.values) {
        expect(
          BookingDateCalculator.dailyContinuousCycleStart(
            anchorDate: DateTime(2028, 1, 31),
            cycleIndex: 1,
            policy: policy,
          ),
          DateTime(2028, 2, 29),
        );
      }
    });

    test('rejects a negative cycle index', () {
      expect(
        () => BookingDateCalculator.dailyContinuousCycleStart(
          anchorDate: DateTime(2028, 1, 1),
          cycleIndex: -1,
          policy: DailyCycleAnchorPolicy.preserveOriginalAnchorDay,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Temporary Booking date range validation', () {
    test('accepts selected dates within an inclusive range', () {
      expect(
        BookingDateCalculator.isTemporaryRangeValid(
          startDate: DateTime(2026, 10, 1, 18),
          endDate: DateTime(2026, 10, 7, 9),
          selectedDates: [
            DateTime(2026, 10, 1, 23),
            DateTime(2026, 10, 7, 0, 1),
          ],
        ),
        isTrue,
      );
    });

    test('rejects an end date before the start date', () {
      expect(
        BookingDateCalculator.isTemporaryRangeValid(
          startDate: DateTime(2026, 10, 8),
          endDate: DateTime(2026, 10, 7),
          selectedDates: [DateTime(2026, 10, 7)],
        ),
        isFalse,
      );
    });

    test('rejects selected dates outside the range or an empty selection', () {
      expect(
        BookingDateCalculator.isTemporaryRangeValid(
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 10, 7),
          selectedDates: [DateTime(2026, 10, 8)],
        ),
        isFalse,
      );
      expect(
        BookingDateCalculator.isTemporaryRangeValid(
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 10, 7),
          selectedDates: [],
        ),
        isFalse,
      );
    });
  });
}
