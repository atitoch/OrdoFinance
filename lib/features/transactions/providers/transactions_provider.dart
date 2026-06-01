import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/resource_state.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/local/local_transactions_repository.dart';
import '../data/transactions_repository.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return LocalTransactionsRepository();
});

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, ResourceState<Transaction>>((
      ref,
    ) {
      return TransactionsNotifier(ref.watch(transactionsRepositoryProvider));
    });

final transactionsListProvider = Provider<List<Transaction>>((ref) {
  return ref.watch(transactionsProvider).items;
});

final transactionsByMonthProvider =
    Provider.autoDispose.family<List<Transaction>, (int, int)>((ref, yearMonth) {
      final (year, month) = yearMonth;
      return ref.watch(transactionsListProvider).where((t) {
        return t.date.year == year && t.date.month == month;
      }).toList();
    });

final transactionsByAccountProvider =
    Provider.autoDispose.family<List<Transaction>, String>((ref, accountId) {
      return ref.watch(transactionsListProvider).where((t) {
        return t.accountId == accountId || t.toAccountId == accountId;
      }).toList();
    });

class TransactionsNotifier extends StateNotifier<ResourceState<Transaction>> {
  TransactionsNotifier(this._repository)
    : super(ResourceState<Transaction>.initial()) {
    refresh();
  }

  final TransactionsRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: state.items.isEmpty,
      isSyncing: state.items.isNotEmpty,
      clearError: true,
    );
    try {
      final transactions = await _repository.getAll();
      state = ResourceState(items: transactions);
    } catch (error) {
      state = state.copyWith(isLoading: false, isSyncing: false, error: error);
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    final previous = state;
    state = state.copyWith(
      items: [...state.items, transaction],
      isSyncing: true,
      clearError: true,
    );
    try {
      final created = await _repository.create(transaction);
      state = state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id == transaction.id) created else item,
        ],
        isSyncing: false,
      );
    } catch (error) {
      state = previous.copyWith(error: error);
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final previous = state;
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == transaction.id) transaction else item,
      ],
      isSyncing: true,
      clearError: true,
    );
    try {
      final updated = await _repository.update(transaction);
      state = state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id == updated.id) updated else item,
        ],
        isSyncing: false,
      );
    } catch (error) {
      state = previous.copyWith(error: error);
    }
  }

  Future<Transaction?> deleteTransaction(String id) async {
    final transaction = _findById(id);
    if (transaction == null) return null;
    final previous = state;
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(growable: false),
      isSyncing: true,
      clearError: true,
    );
    try {
      await _repository.delete(id);
      state = state.copyWith(isSyncing: false);
      return transaction;
    } catch (error) {
      state = previous.copyWith(error: error);
      return null;
    }
  }

  Future<void> restoreTransaction(Transaction transaction) async {
    await addTransaction(transaction);
  }

  Transaction? _findById(String id) {
    for (final transaction in state.items) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }
}
