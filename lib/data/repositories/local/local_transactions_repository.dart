import 'package:hive_flutter/hive_flutter.dart';

import '../../../data/models/transaction.dart';
import '../../../features/transactions/data/transactions_repository.dart';

class LocalTransactionsRepository implements TransactionsRepository {
  Box<Transaction> get _box => Hive.box<Transaction>('transactions');

  @override
  Future<List<Transaction>> getAll() async {
    final items = _box.values.where((t) => t.deletedAt == null).toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<List<Transaction>> getByMonth(int year, int month) async {
    final all = await getAll();
    return all
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
  }

  Future<List<Transaction>> getByAccount(String accountId) async {
    final all = await getAll();
    return all
        .where(
          (t) => t.accountId == accountId || t.toAccountId == accountId,
        )
        .toList();
  }

  @override
  Future<Transaction> create(Transaction transaction) async {
    await _box.put(transaction.id, transaction);
    return transaction;
  }

  @override
  Future<Transaction> update(Transaction transaction) async {
    await _box.put(transaction.id, transaction);
    return transaction;
  }

  Future<Transaction?> getById(String id) async => _box.get(id);

  @override
  Future<void> delete(String id) async {
    final transaction = _box.get(id);
    if (transaction == null) return;
    await _box.put(id, transaction.copyWith(deletedAt: DateTime.now()));
  }
}
