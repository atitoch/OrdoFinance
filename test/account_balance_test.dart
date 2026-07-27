import 'package:flutter_test/flutter_test.dart';
import 'package:ordo_finance/data/models/account.dart';
import 'package:ordo_finance/data/models/transaction.dart';
import 'package:ordo_finance/features/accounts/providers/accounts_provider.dart';

void main() {
  Account account({DateTime? balanceAsOf, DateTime? createdAt}) => Account(
    id: 'a1',
    name: 'Débito',
    type: AccountType.checking,
    balance: 1000000, // $10,000.00
    currency: 'MXN',
    isActive: true,
    createdAt: createdAt ?? DateTime(2026, 7, 26),
    balanceAsOf: balanceAsOf,
  );

  Transaction expense(DateTime date, int cents) => Transaction(
    id: 'tx-${date.millisecondsSinceEpoch}-$cents',
    type: TransactionType.expense,
    amount: cents,
    currency: 'MXN',
    accountId: 'a1',
    description: 'Gasto',
    tags: const [],
    date: date,
    createdAt: DateTime(2026, 7, 26),
  );

  int deltaFor(Account acc, List<Transaction> txs) => computeBalanceDelta(
    transactions: txs,
    accountId: acc.id,
    isCredit: acc.type == AccountType.credit,
    cutoff: balanceCutoffFor(acc),
  );

  group('balanceCutoffFor', () {
    test('usa balanceAsOf cuando existe', () {
      final acc = account(balanceAsOf: DateTime(2026, 3, 15));
      expect(balanceCutoffFor(acc), DateTime(2026, 3, 15));
    });

    test('cae en createdAt en las cuentas guardadas sin la fecha', () {
      final acc = account(createdAt: DateTime(2026, 7, 26, 19, 30));
      expect(balanceCutoffFor(acc), DateTime(2026, 7, 26));
    });
  });

  group('computeBalanceDelta', () {
    test('ignora los movimientos anteriores al saldo capturado', () {
      // El caso que descuadraba la cuenta: importar el histórico del banco
      // descontaba de nuevo lo que el saldo capturado ya incluía.
      final acc = account(balanceAsOf: DateTime(2026, 7, 26));
      final historico = [
        expense(DateTime(2026, 6, 10), 100000),
        expense(DateTime(2026, 5, 3), 200000),
      ];
      expect(deltaFor(acc, historico), 0);
    });

    test('cuenta los movimientos del mismo día que el saldo', () {
      final acc = account(balanceAsOf: DateTime(2026, 7, 26));
      expect(deltaFor(acc, [expense(DateTime(2026, 7, 26, 10), 50000)]), -50000);
    });

    test('cuenta los movimientos posteriores', () {
      final acc = account(balanceAsOf: DateTime(2026, 7, 26));
      expect(deltaFor(acc, [expense(DateTime(2026, 8, 1), 30000)]), -30000);
    });

    test('con la fecha movida atrás vuelve a contar el histórico', () {
      final acc = account(balanceAsOf: DateTime(2026, 1, 1));
      final historico = [
        expense(DateTime(2026, 6, 10), 100000),
        expense(DateTime(2026, 5, 3), 200000),
      ];
      expect(deltaFor(acc, historico), -300000);
    });

    test('en una tarjeta, un gasto posterior aumenta la deuda', () {
      final card = Account(
        id: 'a1',
        name: 'Tarjeta',
        type: AccountType.credit,
        balance: 0,
        currency: 'MXN',
        isActive: true,
        createdAt: DateTime(2026, 7, 26),
        balanceAsOf: DateTime(2026, 7, 26),
      );
      expect(deltaFor(card, [expense(DateTime(2026, 8, 2), 40000)]), 40000);
    });
  });
}
