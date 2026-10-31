/// Pure booking schedule rules shared by the Customer booking UI and unit tests.
class BookingScheduleSlot {
  const BookingScheduleSlot({
    required this.start,
    required this.durationMinutes,
  });

  final DateTime start;
  final int durationMinutes;
}

class BookingScheduleRules {
  BookingScheduleRules._();

  /// Returns true when any sorted slot starts before the previous slot ends.
  /// A slot starting exactly at the previous slot's end is allowed.
  static bool hasOverlap(List<BookingScheduleSlot> slots) {
    if (slots.length < 2) return false;

    final sorted = [...slots]..sort((a, b) => a.start.compareTo(b.start));

    for (var index = 0; index < sorted.length - 1; index++) {
      final current = sorted[index];
      final next = sorted[index + 1];
      final currentEnd = current.start.add(
        Duration(minutes: current.durationMinutes),
      );

      if (next.start.isBefore(currentEnd)) return true;
    }

    return false;
  }

  /// A scheduled walk must be strictly later than the supplied clock time.
  static bool isFutureStart(DateTime start, DateTime now) {
    return start.isAfter(now);
  }

  /// Regular bookings begin today if at least one selected slot is still
  /// ahead of [now]; otherwise they begin tomorrow.
  static DateTime regularStartDate({
    required DateTime now,
    required Iterable<DateTime> slotStarts,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final hasFutureSlotToday = slotStarts.any(
      (start) => isFutureStart(start, now),
    );

    return hasFutureSlotToday
        ? today
        : today.add(const Duration(days: 1));
  }

  /// Normalizes and sorts dates so selection order cannot affect the payload.
  static List<DateTime> sortDates(Iterable<DateTime> dates) {
    final normalized = dates
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    return normalized;
  }
}
