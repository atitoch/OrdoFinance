import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ordo_app_bar.dart';
import '../../../shared/widgets/resource_status_banner.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../shared/widgets/transaction_row.dart';
import '../../categories/providers/categories_provider.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../providers/accounts_provider.dart';
import '../widgets/account_form_sheet.dart';

class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({required this.accountId, super.key});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsStatus = ref.watch(accountsProvider.select((s) => s.status));
    final transactionsStatus = ref.watch(transactionsProvider.select((s) => s.status));
    final accounts = ref.watch(accountsListProvider);
    final account = accounts.firstWhereOrNull((item) => item.id == accountId);
    if (account == null) {
      return const Scaffold(
        appBar: OrdoAppBar(title: 'Cuenta'),
        body: Center(child: Text('Cuenta no encontrada')),
      );
    }

    final categories = ref.watch(categoriesListProvider);
    final transactions =
        ref
            .watch(transactionsListProvider)
            .where((tx) => tx.accountId == accountId)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final lastDate = transactions.firstOrNull?.date;
    final currentBalance = ref.watch(currentBalanceProvider(accountId));
    final isCredit = account.type == AccountType.credit;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: OrdoAppBar(
        title: account.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.gray900),
            onPressed: () => _showAccountSheet(context, account),
          ),
        ],
      ),
      body: Column(
        children: [
          ResourceStatusBanner(
            isLoading: accountsStatus.isLoading || transactionsStatus.isLoading,
            isSyncing: accountsStatus.isSyncing || transactionsStatus.isSyncing,
            error: accountsStatus.error ?? transactionsStatus.error,
            onRetry: () {
              ref.read(accountsProvider.notifier).refresh();
              ref.read(transactionsProvider.notifier).refresh();
            },
          ),
          Container(
            width: double.infinity,
            color: AppColors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _AccountTypeChip(type: account.type),
                const SizedBox(height: 12),
                Text(
                  isCredit
                      ? '-${formatAmount(currentBalance, account.currency)}'
                      : formatAmount(currentBalance, account.currency),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexMono(
                    color: isCredit ? AppColors.expense : AppColors.gray900,
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  account.name,
                  style: GoogleFonts.instrumentSans(
                    color: AppColors.gray500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lastDate == null
                      ? 'Sin actividad'
                      : 'Última actividad ${DateFormat.MMMd().format(lastDate)}',
                  style: GoogleFonts.ibmPlexMono(
                    color: AppColors.gray400,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: AppColors.gray200),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(child: SectionLabel('MOVIMIENTOS')),
                TextButton(
                  onPressed: () =>
                      context.go('/transactions?accountId=$accountId'),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
          ),
          Expanded(
            child: transactionsStatus.isLoading && transactions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SkeletonBlock(height: 64),
                        SizedBox(height: 8),
                        SkeletonBlock(height: 64),
                      ],
                    ),
                  )
                : transactions.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Sin movimientos aún',
                    subtitle: 'Los movimientos de esta cuenta aparecerán aquí.',
                    compact: true,
                  )
                : ListView(
                    children: transactions.take(10).map((transaction) {
                      final category = categories.firstWhereOrNull(
                        (item) => item.id == transaction.categoryId,
                      );
                      return TransactionRow(
                        transaction: transaction,
                        category: category,
                        account: account,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAccountSheet(BuildContext context, Account account) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AccountFormSheet(account: account),
    );
  }
}

class _AccountTypeChip extends StatelessWidget {
  const _AccountTypeChip({required this.type});

  final AccountType type;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          _label.toUpperCase(),
          style: GoogleFonts.instrumentSans(
            color: _textColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.66,
          ),
        ),
      ),
    );
  }

  String get _label => switch (type) {
    AccountType.checking => 'Checking',
    AccountType.savings => 'Savings',
    AccountType.cash => 'Cash',
    AccountType.credit => 'Credit',
    AccountType.investment => 'Investment',
  };

  Color get _backgroundColor => switch (type) {
    AccountType.credit => AppColors.expenseBg,
    AccountType.investment => AppColors.transferBg,
    _ => AppColors.gray100,
  };

  Color get _textColor => switch (type) {
    AccountType.credit => AppColors.expense,
    AccountType.investment => AppColors.transfer,
    _ => AppColors.gray900,
  };
}

extension _IterableExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
