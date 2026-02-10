import 'package:intl/intl.dart';

/// Extensions on num for currency and number formatting.
extension NumberExtensions on num {
  /// Format as Vietnamese currency: 1,000,000 ₫
  String get toCurrency {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(this);
  }

  /// Format as compact currency: 1Tr, 500K
  String get toCompactCurrency {
    if (this >= 1000000000) {
      return '${(this / 1000000000).toStringAsFixed(1)}Tỷ';
    } else if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}Tr';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(0)}K';
    }
    return toStringAsFixed(0);
  }

  /// Format with dot separators: 1.000.000
  String get toFormattedNumber {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(this);
  }
}
