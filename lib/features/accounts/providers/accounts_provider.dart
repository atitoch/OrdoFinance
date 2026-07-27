import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/state/resource_state.dart';
import '../../../data/models/account.dart';
import '../../../data/models/transaction.dart';
import '../../../data/repositories/local/local_accounts_repository.dart';
import '../data/accounts_repository.dart';
import '../../transactions/providers/transactions_provider.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return LocalAccountsRepository();
});

final accountsProvider =
    StateNotifierProvider<AccountsNotifier, ResourceState<Account>>(
      (ref) => AccountsNotifier(ref.watch(accountsRepositoryProvider)),
    );

final accountsListProvider = Provider<List<Account>>((ref) {
  return ref.watch(accountsProvider).items;
});

/// Fecha desde la que los movimientos afectan al saldo de la cuenta. El saldo
/// capturado corresponde a ese día, así que lo anterior ya está incluido en él.
/// Las cuentas creadas antes de que existiera el campo usan su fecha de alta.
DateTime balanceCutoffFor(Account account) {
  final reference = account.balanceAsOf ?? account.createdAt;
  // Se compara contra el inicio del día: lo que registres el mismo día que
  // capturas el saldo debe contar, o parecería que la app ignora el gasto.
  return DateTime(reference.year, reference.month, reference.day);
}

/// Efecto de los movimientos sobre el saldo de una cuenta a partir de
/// [cutoff]. Función pura para poder probarla y reutilizarla desde el
/// formulario, que necesita el cálculo con una fecha aún no guardada.
int computeBalanceDelta({
  required List<Transaction> transactions,
  required String accountId,
  required bool isCredit,
  required DateTime cutoff,
}) {
  var delta = 0;
  for (final tx in transactions) {
    if (tx.date.isBefore(cutoff)) continue;
    switch (tx.type) {
      case TransactionType.income:
        if (tx.accountId == accountId) {
          // Pago a crédito reduce deuda; ingreso en activo aumenta saldo
          delta += isCredit ? -tx.amount : tx.amount;
        }
      case TransactionType.expense:
        if (tx.accountId == accountId) {
          // Gasto en crédito aumenta deuda; gasto en activo reduce saldo
          delta += isCredit ? tx.amount : -tx.amount;
        }
      case TransactionType.transfer:
        if (tx.accountId == accountId) {
          // Sale dinero: activo disminuye, crédito aumenta deuda
          delta += isCredit ? tx.amount : -tx.amount;
        }
        if (tx.toAccountId == accountId) {
          // Llega dinero: activo aumenta, crédito reduce deuda (pago)
          delta += isCredit ? -tx.amount : tx.amount;
        }
    }
  }
  return delta;
}

final computedBalanceProvider = Provider.autoDispose.family<int, String>((ref, accountId) {
  final accounts = ref.watch(accountsListProvider);
  final account = accounts.where((a) => a.id == accountId).firstOrNull;
  if (account == null) return 0;
  return computeBalanceDelta(
    transactions: ref.watch(transactionsListProvider),
    accountId: accountId,
    isCredit: account.type == AccountType.credit,
    cutoff: balanceCutoffFor(account),
  );
});

// Para crédito: deuda actual (positivo = cuánto debes)
// Para activos: saldo actual (positivo = cuánto tienes)
final currentBalanceProvider = Provider.autoDispose.family<int, String>((ref, accountId) {
  final accounts = ref.watch(accountsListProvider);
  final account = accounts.where((a) => a.id == accountId).firstOrNull;
  if (account == null) return 0;
  return account.balance + ref.watch(computedBalanceProvider(accountId));
});

// Advertencia de liquidez: true si activos líquidos < deuda total de crédito
final liquidityWarningProvider = Provider<bool>((ref) {
  final accounts = ref.watch(accountsListProvider);
  const liquid = {AccountType.checking, AccountType.savings, AccountType.cash};
  var liquidAssets = 0;
  var creditDebt = 0;
  for (final account in accounts.where((a) => a.isActive)) {
    final balance = ref.watch(currentBalanceProvider(account.id));
    if (liquid.contains(account.type)) liquidAssets += balance;
    if (account.type == AccountType.credit) creditDebt += balance;
  }
  return creditDebt > 0 && liquidAssets < creditDebt;
});

// Patrimonio total: activos suman, crédito resta
final netWorthProvider = Provider<int>((ref) {
  final accounts = ref.watch(accountsListProvider);
  return accounts.fold<int>(0, (sum, account) {
    final balance = ref.watch(currentBalanceProvider(account.id));
    return account.type == AccountType.credit ? sum - balance : sum + balance;
  });
});

class AccountsNotifier extends StateNotifier<ResourceState<Account>> {
  AccountsNotifier(this._repository) : super(ResourceState<Account>.initial()) {
    refresh();
  }

  final AccountsRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: state.items.isEmpty,
      isSyncing: state.items.isNotEmpty,
      clearError: true,
    );
    try {
      final accounts = await _repository.getAll();
      state = ResourceState(items: accounts);
    } catch (error) {
      state = state.copyWith(isLoading: false, isSyncing: false, error: error);
    }
  }

  Future<void> addAccount(Account account) async {
    final previous = state;
    state = state.copyWith(
      items: [...state.items, account],
      isSyncing: true,
      clearError: true,
    );
    try {
      final created = await _repository.create(account);
      final next = state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id == account.id) created else item,
        ],
        isSyncing: false,
      );
      state = next;
      await NotificationService.scheduleForAccounts(next.items);
    } catch (error) {
      state = previous.copyWith(error: error);
    }
  }

  Future<void> updateAccount(Account account) async {
    final previous = state;
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == account.id) account else item,
      ],
      isSyncing: true,
      clearError: true,
    );
    try {
      final updated = await _repository.update(account);
      final next = state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id == updated.id) updated else item,
        ],
        isSyncing: false,
      );
      state = next;
      await NotificationService.scheduleForAccounts(next.items);
    } catch (error) {
      state = previous.copyWith(error: error);
    }
  }

  Future<void> archiveAccount(String id) async {
    final previous = state;
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == id) item.copyWith(isActive: false) else item,
      ],
      isSyncing: true,
      clearError: true,
    );
    try {
      final archived = await _repository.archive(id);
      state = state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id == archived.id) archived else item,
        ],
        isSyncing: false,
      );
    } catch (error) {
      state = previous.copyWith(error: error);
    }
  }
}
