import 'package:intl/intl.dart';

class NumberFormatter {
  NumberFormatter._();

  static final _format = NumberFormat('#,##0.########', 'ko');

  static String format(double value) {
    if (value == value.truncateToDouble()) {
      return NumberFormat('#,##0', 'ko').format(value.toInt());
    }
    return _format.format(value);
  }

  static String formatDisplay(String rawInput) {
    if (rawInput.isEmpty || rawInput == '-') return rawInput;
    final parts = rawInput.split('.');
    final intPart = parts[0];
    final hasDecimal = rawInput.endsWith('.');
    final decPart = parts.length > 1 ? parts[1] : null;

    String formatted;
    try {
      final intVal = int.parse(intPart.replaceAll('-', ''));
      final sign = intPart.startsWith('-') ? '-' : '';
      formatted = '$sign${NumberFormat('#,##0', 'ko').format(intVal)}';
    } catch (_) {
      formatted = intPart;
    }

    if (hasDecimal && decPart == null) return '$formatted.';
    if (decPart != null) return '$formatted.$decPart';
    return formatted;
  }

  static String adaptiveFontSize(String text) => text;
}
