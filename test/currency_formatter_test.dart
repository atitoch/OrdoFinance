import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:ordo_finance/core/utils/currency_formatter.dart';
import 'package:ordo_finance/data/models/account.dart';

void main() {
  setUpAll(() => Intl.defaultLocale = 'es_MX');

  group('formatAccountBalance', () {
    test('no antepone el signo cuando la tarjeta no tiene deuda', () {
      expect(
        formatAccountBalance(0, 'MXN', AccountType.credit),
        isNot(startsWith('-')),
      );
    });

    test('no duplica el signo con una tarjeta sobrepagada', () {
      expect(
        formatAccountBalance(-5000, 'MXN', AccountType.credit),
        isNot(startsWith('--')),
      );
    });

    test('marca la deuda en negativo', () {
      expect(
        formatAccountBalance(5000, 'MXN', AccountType.credit),
        startsWith('-'),
      );
    });

    test('deja el saldo de un activo tal cual', () {
      expect(
        formatAccountBalance(5000, 'MXN', AccountType.checking),
        isNot(startsWith('-')),
      );
    });
  });

  group('formatSignedAmount', () {
    test('conserva el signo de un balance negativo', () {
      expect(formatSignedAmount(-50000, 'MXN'), startsWith('−'));
    });

    test('no agrega signo a un balance positivo', () {
      expect(formatSignedAmount(50000, 'MXN'), isNot(startsWith('−')));
    });
  });

  group('accountBalanceIsNegative', () {
    test('una tarjeta con deuda va en rojo', () {
      expect(accountBalanceIsNegative(100, AccountType.credit), isTrue);
    });

    test('una tarjeta sin deuda no va en rojo', () {
      expect(accountBalanceIsNegative(0, AccountType.credit), isFalse);
    });

    test('un activo en números rojos va en rojo', () {
      expect(accountBalanceIsNegative(-100, AccountType.cash), isTrue);
    });
  });

  group('parseAmountToCents', () {
    test('acepta punto y coma como separador decimal', () {
      expect(parseAmountToCents('1250.50'), 125050);
      expect(parseAmountToCents('1250,50'), 125050);
      expect(parseAmountToCents('1250'), 125000);
    });

    test('rechaza lo que no es un número usable', () {
      expect(parseAmountToCents('1.2.3'), isNull);
      expect(parseAmountToCents('.'), isNull);
      expect(parseAmountToCents(''), isNull);
      expect(parseAmountToCents('abc'), isNull);
    });

    test('rechaza montos que desbordan la aritmética entera', () {
      expect(parseAmountToCents('99999999999999999999'), isNull);
    });
  });

  group('centsToAmountInput', () {
    test('conserva los centavos', () {
      expect(centsToAmountInput(125050), '1250.50');
    });

    test('omite los decimales cuando son cero', () {
      expect(centsToAmountInput(125000), '1250');
    });
  });

  test('formatAmount usa el separador decimal del locale', () {
    final formatted = formatAmount(123456, 'MXN');
    // es_MX: miles con coma y decimales con punto.
    expect(formatted, contains('1,234.56'));
  });
}
