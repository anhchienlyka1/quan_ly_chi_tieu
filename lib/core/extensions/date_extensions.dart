import 'package:intl/intl.dart';

/// Extensions on DateTime for common formatting needs.
extension DateExtensions on DateTime {
  /// Format: 10/02/2026
  String get toShortDate => DateFormat('dd/MM/yyyy').format(this);

  /// Format: 10 tháng 2, 2026
  String get toLongDate => DateFormat('dd \'tháng\' M, yyyy').format(this);

  /// Format: Thứ 3, 10/02
  String get toDayAndDate {
    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return '${weekdays[weekday % 7]}, ${DateFormat('dd/MM').format(this)}';
  }

  /// Format: 10:30
  String get toTime => DateFormat('HH:mm').format(this);

  /// Check if this date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if this date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Get the start of the month
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Get the end of the month
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);

  /// Get a human-friendly relative date string
  String get relativeDate {
    if (isToday) return 'Hôm nay';
    if (isYesterday) return 'Hôm qua';
    return toShortDate;
  }

  /// Method alias for relativeDate getter
  String toRelativeDate() => relativeDate;
}
