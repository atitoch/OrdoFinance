import 'package:intl/intl.dart';

String formatAmount(int cents, String currency) {
  final locale = Intl.getCurrentLocale();
  final currencyFormat = NumberFormat.simpleCurrency(
    locale: locale,
    name: currency,
  );
  final decimalFormat = NumberFormat.decimalPattern(locale);

  final isNegative = cents < 0;
  final absoluteCents = cents.abs();
  final wholeUnits = absoluteCents ~/ 100;
  final fractionalUnits = absoluteCents % 100;
  final groupedWholeUnits = decimalFormat.format(wholeUnits);
  final fraction = fractionalUnits.toString().padLeft(2, '0');
  final sign = isNegative ? '-' : '';

  return '$sign${currencyFormat.currencySymbol}$groupedWholeUnits.$fraction';
}
