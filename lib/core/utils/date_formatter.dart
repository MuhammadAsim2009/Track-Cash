import 'package:intl/intl.dart';

/// Date formatting and helper utilities.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _fullDateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _shortDateFormat = DateFormat('dd MMM');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _monthKeyFormat = DateFormat('yyyy-MM');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  /// Formats date as e.g. "27 Oct 2026"
  static String formatDate(DateTime date) => _fullDateFormat.format(date);

  /// Formats date as e.g. "27 Oct"
  static String formatDateShort(DateTime date) => _shortDateFormat.format(date);

  /// Formats date as e.g. "October 2026"
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  /// Formats date as budget month key "2026-10"
  static String formatMonthKey(DateTime date) => _monthKeyFormat.format(date);

  /// Parses "2026-10" back to DateTime(2026, 10, 1)
  static DateTime parseMonthKey(String key) {
    try {
      final parts = key.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        return DateTime(year, month, 1);
      }
    } catch (_) {}
    return DateTime.now();
  }

  /// Formats time as e.g. "08:15 AM"
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Checks if [date] is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Checks if [date] was yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Returns friendly relative date label: "Today", "Yesterday", or "27 Oct 2026"
  static String formatRelativeOrDate(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isYesterday(date)) return 'Yesterday';
    return formatDate(date);
  }

  /// Checks if a due date is in the past (overdue), ignoring hours/minutes.
  static bool isOverdue(DateTime dueDate) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final dueStart = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueStart.isBefore(todayStart);
  }

  /// Returns days remaining between now and [dueDate] (negative if overdue).
  static int daysRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final dueStart = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueStart.difference(todayStart).inDays;
  }

  /// Returns number of days left in the current month.
  static int daysLeftInMonth([DateTime? date]) {
    final target = date ?? DateTime.now();
    final lastDayOfMonth = DateTime(target.year, target.month + 1, 0);
    return lastDayOfMonth.day - target.day;
  }
}
