import 'package:intl/intl.dart';

/// Money formatter utility strictly adhering to integer rupee currency formatting ("Rs 12,500").
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');

  /// Formats an integer amount to standard rupee representation:
  /// Examples:
  ///   12500 -> "Rs 12,500"
  ///   0 -> "Rs 0"
  ///   -500 -> "-Rs 500"
  static String format(int amount) {
    if (amount < 0) {
      return '-Rs ${_formatter.format(amount.abs())}';
    }
    return 'Rs ${_formatter.format(amount)}';
  }

  /// Formats money with an explicit '+' or '-' sign:
  /// Examples:
  ///   formatSigned(5000, isIncome: true) -> "+Rs 5,000"
  ///   formatSigned(5000, isIncome: false) -> "-Rs 5,000"
  ///   formatSigned(-500) -> "-Rs 500"
  static String formatSigned(int amount, {bool? isIncome}) {
    if (isIncome == true && amount > 0) {
      return '+Rs ${_formatter.format(amount)}';
    }
    if (isIncome == false && amount > 0) {
      return '-Rs ${_formatter.format(amount)}';
    }
    return format(amount);
  }

  /// Parses user string input into integer rupees, ignoring currency symbols and commas.
  /// Returns 0 if parsing fails.
  static int parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9\-]'), '');
    return int.tryParse(cleaned) ?? 0;
  }
}
