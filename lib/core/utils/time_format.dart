// Formats 24-hour transit times, dates, and EUR currency amounts using intl.

import 'package:intl/intl.dart';

/// Locale-aware 24-hour time, date, and Euro currency formatting helpers.
abstract final class TimeFormatUtils {
  /// Formats [dateTime] in 24-hour clock format (e.g., `14:35`).
  static String formatTime24(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Formats [dateTime] as compact local date and 24-hour time.
  static String formatDateTime24(DateTime dateTime, {String locale = 'sl'}) {
    final safeLocale = _normalizeIntlLocale(locale);
    try {
      return DateFormat.yMd(safeLocale).add_Hm().format(dateTime);
    } catch (_) {
      return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
    }
  }

  /// Formats an amount in Euros using locale-appropriate grouping and symbol.
  static String formatEur(double amount, {String locale = 'sl'}) {
    final safeLocale = _normalizeIntlLocale(locale);
    try {
      return NumberFormat.currency(
        locale: safeLocale,
        symbol: '€',
        decimalDigits: 2,
      ).format(amount);
    } catch (_) {
      return '${amount.toStringAsFixed(2)} €';
    }
  }

  static String _normalizeIntlLocale(String locale) {
    if (locale == 'sr_Latn') return 'sr_Latn';
    if (const ['sl', 'en', 'de', 'sr'].contains(locale)) return locale;
    return 'sl';
  }
}
