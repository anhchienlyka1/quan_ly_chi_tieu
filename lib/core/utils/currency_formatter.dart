import 'package:intl/intl.dart';

/// Utility class for formatting currency values.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final _numberFormat = NumberFormat('#,###', 'vi_VN');

  /// Format a number as Vietnamese currency
  static String format(num amount) => _currencyFormat.format(amount);

  /// Format number with separators (no currency symbol)
  static String formatNumber(num amount) => _numberFormat.format(amount);

  /// Parse a formatted currency string back to a number
  static num? parse(String value) {
    try {
      final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
      return num.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }
}
