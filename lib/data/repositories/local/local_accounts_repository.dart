import 'package:hive_flutter/hive_flutter.dart';

import '../../../data/models/account.dart';
import '../../../data/models/transaction.dart';
import '../../../features/accounts/data/accounts_repository.dart';

class LocalAccountsRepository implements AccountsRepository {
  Box<Account> get _box => Hive.box<Account>('accounts');

  @override
  Future<List<Account>> getAll() async {
    final items = _box.values.where((a) => a.isActive).toList();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  @override
  Future<Account> create(Account account) async {
    await _box.put(account.id, account);
    return account;
  }

  @override
  Future<Account> update(Account account) async {
    await _box.put(account.id, account);
    return account;
  }

  @override
  Future<Account> archive(String id) async {
    final account = _box.get(id);
    if (account == null) throw StateError('Account $id not found');
    final archived = account.copyWith(isActive: false);
    await _box.put(id, archived);
    return archived;
  }

  Future<Account?> getById(String id) async => _box.get(id);

  Future<int> computeBalance(
    String accountId,
    List<Transaction> transactions,
  ) async {
    var balance = 0;
    for (final tx in transactions) {
      if (tx.deletedAt != null) continue;
      switch (tx.type) {
        case TransactionType.income:
          if (tx.accountId == accountId) balance += tx.amount;
        case TransactionType.expense:
          if (tx.accountId == accountId) balance -= tx.amount;
        case TransactionType.transfer:
          if (tx.accountId == accountId) balance -= tx.amount;
          if (tx.toAccountId == accountId) balance += tx.amount;
      }
    }
    return balance;
  }
}
