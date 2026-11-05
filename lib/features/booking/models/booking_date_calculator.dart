/// Pure date rules for the customer booking flow.
///
/// Daily Continuous month-end behavior is deliberately policy-injected until
/// POL-006 receives an explicit product decision. This model is not wired to
/// booking submission or Firestore.
enum DailyCycleAnchorPolicy {
  /// Each cycle is calculated from the original start day.
  ///
  /// Example: Jan 31 -> Feb 28/29 -> Mar 31.
  preserveOriginalAnchorDay,

  /// Each cycle is calculated from the previous cycle start.
  ///
  /// Example: Jan 31 -> Feb 28/29 -> Mar 28/29.
  rollForwardFromPreviousCycle,
}

class BookingDateCalculator {
  BookingDateCalculator._();

  /// Removes the time component and returns a local date-only value.
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// A Monthly Package is an inclusive 28-day term.
  static DateTime monthlyPackageEndDate(DateTime startDate) =>
      dateOnly(startDate).add(const Duration(days: 27));

  /// Calculates the start date of a Daily Continuous calendar cycle.
  ///
  /// [cycleIndex] is zero-based; 0 returns the normalized anchor date.
  /// A month-end policy is mandatory so callers cannot silently assume one.
  static DateTime dailyContinuousCycleStart({
    required DateTime anchorDate,
    required int cycleIndex,
    required DailyCycleAnchorPolicy policy,
  }) {
    if (cycleIndex < 0) {
      throw ArgumentError.value(cycleIndex, 'cycleIndex', 'Must be >= 0');
    }

    final anchor = dateOnly(anchorDate);
    if (cycleIndex == 0) return anchor;

    switch (policy) {
      case DailyCycleAnchorPolicy.preserveOriginalAnchorDay:
        return _dateInMonth(
          anchor.year,
          anchor.month + cycleIndex,
          anchor.day,
        );
      case DailyCycleAnchorPolicy.rollForwardFromPreviousCycle:
        var result = anchor;
        for (var i = 0; i < cycleIndex; i++) {
          result = _dateInMonth(result.year, result.month + 1, result.day);
        }
        return result;
    }
  }

  /// Validates an explicit Temporary Booking date range and selected dates.
  ///
  /// The range is inclusive. At least one selected date is required, and
  /// every selected date must fall inside the normalized range.
  static bool isTemporaryRangeValid({
    required DateTime startDate,
    required DateTime endDate,
    required List<DateTime> selectedDates,
  }) {
    final start = dateOnly(startDate);
    final end = dateOnly(endDate);

    if (end.isBefore(start) || selectedDates.isEmpty) return false;

    return selectedDates.every((value) {
      final date = dateOnly(value);
      return !date.isBefore(start) && !date.isAfter(end);
    });
  }

  static DateTime _dateInMonth(int year, int month, int requestedDay) {
    final firstOfMonth = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = requestedDay > lastDay ? lastDay : requestedDay;
    return DateTime(firstOfMonth.year, firstOfMonth.month, day);
  }
}
