import 'package:intl/intl.dart';

import '../../data/models/account.dart';

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
  // El separador decimal tiene que venir del locale igual que el de miles;
  // con un '.' fijo, en es-MX se leería "1.234.56".
  final decimalSeparator = decimalFormat.symbols.DECIMAL_SEP;
  final sign = isNegative ? '-' : '';

  return '$sign${currencyFormat.currencySymbol}'
      '$groupedWholeUnits$decimalSeparator$fraction';
}

/// Formatea el saldo de una cuenta teniendo en cuenta que en las tarjetas de
/// crédito el saldo representa deuda y se muestra en negativo.
///
/// Sólo antepone el signo cuando realmente hay deuda: con saldo 0 produciría
/// `-$0.00` y con la tarjeta sobrepagada `--$50.00`. Una tarjeta sobrepagada
/// tiene saldo a favor, así que se muestra en positivo.
String formatAccountBalance(int balance, String currency, AccountType type) {
  if (type != AccountType.credit) return formatAmount(balance, currency);
  if (balance > 0) return '-${formatAmount(balance, currency)}';
  return formatAmount(balance.abs(), currency);
}

/// `true` cuando el saldo debe pintarse en rojo: deuda en tarjetas de crédito
/// o números rojos en cuentas de activo.
bool accountBalanceIsNegative(int balance, AccountType type) {
  return type == AccountType.credit ? balance > 0 : balance < 0;
}

/// Antepone el signo cuando el monto es negativo. Para totales como el balance
/// del mes, donde `formatAmount(x.abs())` escondía el signo.
String formatSignedAmount(int cents, String currency) {
  return cents < 0
      ? '−${formatAmount(cents.abs(), currency)}'
      : formatAmount(cents, currency);
}

/// Convierte lo escrito en un campo de monto a centavos, aceptando coma o
/// punto como separador decimal. Devuelve `null` cuando el texto no es un
/// número usable ("1.2.3", ".", "", o un número que desborda un `int`).
int? parseAmountToCents(String raw) {
  final normalized = raw.trim().replaceAll(',', '.');
  if (normalized.isEmpty || normalized == '.' || normalized == '-') return null;
  if (!RegExp(r'^-?\d*\.?\d*$').hasMatch(normalized)) return null;
  final value = double.tryParse(normalized);
  if (value == null || !value.isFinite) return null;
  final cents = value * 100;
  // Más allá de esto la aritmética entera deja de ser exacta y el monto se
  // convertiría en basura silenciosamente.
  if (cents.abs() > 9007199254740991) return null;
  return cents.round();
}

/// Texto editable para un campo de monto: sin separadores de miles y con
/// decimales sólo cuando los hay.
String centsToAmountInput(int cents) {
  return cents % 100 == 0
      ? (cents ~/ 100).toString()
      : (cents / 100).toStringAsFixed(2);
}
