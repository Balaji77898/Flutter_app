import 'package:intl/intl.dart';

class CurrencyUtils {
  static final _indianFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String format(num amount) {
    return _indianFormat.format(amount);
  }

  static String formatPlain(num amount) {
    return NumberFormat.decimalPattern('en_IN').format(amount);
  }
}
