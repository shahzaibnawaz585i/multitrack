/// Normalized date ranges for report filter chips (Today, Yesterday, Week, Month).
class ReportPeriod {
  ReportPeriod._();

  static DateTime startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }

  static bool contains(DateTime value, DateTime from, DateTime to) {
    final DateTime normalized = value;
    return !normalized.isBefore(from) && !normalized.isAfter(to);
  }

  /// History tab ranges aligned with `get_history` (Today 00:00 → 23:59 same day).
  static ({DateTime from, DateTime to}) historyRangeFor(String key, DateTime now) {
    switch (key) {
      case '1h':
        return (
          from: now.subtract(const Duration(hours: 1)),
          to: now,
        );
      case 'yesterday':
        final DateTime yesterday = now.subtract(const Duration(days: 1));
        return (
          from: startOfDay(yesterday),
          to: endOfDay(yesterday),
        );
      case 'week':
        return (
          from: startOfDay(now.subtract(const Duration(days: 6))),
          to: endOfDay(now),
        );
      case 'month':
        return (
          from: startOfDay(DateTime(now.year, now.month, 1)),
          to: endOfDay(now),
        );
      case 'custom':
        return (from: startOfDay(now), to: endOfDay(now));
      case 'today':
      default:
        return (from: startOfDay(now), to: endOfDay(now));
    }
  }

  /// Statistics tab chip ranges (full calendar days where applicable).
  static ({DateTime from, DateTime to}) statisticsRangeFor(
    String filter,
    DateTime now,
  ) {
    switch (filter) {
      case 'Yesterday':
        final DateTime yesterday = now.subtract(const Duration(days: 1));
        return (from: startOfDay(yesterday), to: endOfDay(yesterday));
      case '2 Days':
        return (
          from: startOfDay(now.subtract(const Duration(days: 1))),
          to: endOfDay(now),
        );
      case '3 Days':
        return (
          from: startOfDay(now.subtract(const Duration(days: 2))),
          to: endOfDay(now),
        );
      case 'This Week':
        final int weekday = now.weekday;
        final DateTime start = startOfDay(
          now.subtract(Duration(days: weekday - 1)),
        );
        return (from: start, to: endOfDay(now));
      case 'Last Week':
        final int weekday = now.weekday;
        final DateTime startOfThisWeek = startOfDay(
          now.subtract(Duration(days: weekday - 1)),
        );
        final DateTime start = startOfThisWeek.subtract(const Duration(days: 7));
        final DateTime end =
            endOfDay(startOfThisWeek.subtract(const Duration(days: 1)));
        return (from: start, to: end);
      case 'This Month':
        return (
          from: startOfDay(DateTime(now.year, now.month, 1)),
          to: endOfDay(now),
        );
      case 'Last Month':
        final DateTime start = DateTime(now.year, now.month - 1, 1);
        final DateTime end = endOfDay(DateTime(now.year, now.month, 0));
        return (from: startOfDay(start), to: end);
      case 'Today':
      default:
        return (from: startOfDay(now), to: endOfDay(now));
    }
  }

  /// Returns inclusive [from, to] for filter chip [index].
  static ({DateTime from, DateTime to}) rangeForChip(int index, DateTime now) {
    switch (index) {
      case 0:
        return (from: startOfDay(now), to: endOfDay(now));
      case 1:
        final DateTime yesterday = now.subtract(const Duration(days: 1));
        return (
          from: startOfDay(yesterday),
          to: endOfDay(yesterday),
        );
      case 2:
        return (
          from: startOfDay(now.subtract(const Duration(days: 6))),
          to: endOfDay(now),
        );
      case 3:
      default:
        return (
          from: startOfDay(DateTime(now.year, now.month, 1)),
          to: endOfDay(now),
        );
    }
  }
}
