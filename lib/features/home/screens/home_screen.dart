import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account.dart';
import '../../../data/models/transaction.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ordo_app_bar.dart';
import '../../../shared/widgets/resource_status_banner.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../shared/widgets/transaction_row.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../categories/providers/categories_provider.dart';
import '../../transactions/providers/transactions_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsStatus = ref.watch(accountsProvider.select((s) => s.status));
    final categoriesStatus = ref.watch(categoriesProvider.select((s) => s.status));
    final transactionsStatus = ref.watch(transactionsProvider.select((s) => s.status));
    final accounts = ref.watch(accountsListProvider);
    final categories = ref.watch(categoriesListProvider);
    final transactions = ref.watch(transactionsListProvider);
    final currency = accounts.firstOrNull?.currency ?? 'USD';
    final netWorth = ref.watch(netWorthProvider);
    final now = DateTime.now();
    final currentMonth = transactions.where(
      (tx) => tx.date.year == now.year && tx.date.month == now.month,
    );
    final income = currentMonth
        .where((tx) => tx.type == TransactionType.income)
        .fold<int>(0, (sum, tx) => sum + tx.amount);
    final expense = currentMonth
        .where((tx) => tx.type == TransactionType.expense)
        .fold<int>(0, (sum, tx) => sum + tx.amount);
    final recent = [...transactions]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: OrdoAppBar(
        title: '',
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ordo',
              style: GoogleFonts.instrumentSans(
                color: AppColors.gray900,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ResourceStatusBanner(
            isLoading: accountsStatus.isLoading || categoriesStatus.isLoading || transactionsStatus.isLoading,
            isSyncing: accountsStatus.isSyncing || categoriesStatus.isSyncing || transactionsStatus.isSyncing,
            error: accountsStatus.error ?? categoriesStatus.error ?? transactionsStatus.error,
            onRetry: () {
              ref.read(accountsProvider.notifier).refresh();
              ref.read(categoriesProvider.notifier).refresh();
              ref.read(transactionsProvider.notifier).refresh();
            },
          ),
          if (ref.watch(liquidityWarningProvider))
            const _LiquidityWarningBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patrimonio total',
                  style: GoogleFonts.instrumentSans(
                    color: AppColors.gray500,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatAmount(netWorth, currency),
                  style: GoogleFonts.ibmPlexMono(
                    color: AppColors.gray900,
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (accountsStatus.isLoading && accounts.isEmpty)
            const _AccountCardSkeletons()
          else if (accounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Sin cuentas registradas',
                subtitle: 'Crea una cuenta para comenzar a registrar tu dinero.',
                compact: true,
                action: SizedBox(
                  width: 180,
                  child: OutlinedButton(
                    onPressed: () => context.push('/accounts'),
                    child: const Text('Administrar cuentas'),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 122,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) =>
                    _AccountCard(account: accounts[index]),
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemCount: accounts.length,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _MonthSummaryBar(
              income: income,
              expense: expense,
              net: income - expense,
              currency: currency,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SectionLabel('RECIENTES'),
          ),
          if (transactionsStatus.isLoading && recent.isEmpty)
            const _RecentSkeletons()
          else if (recent.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Sin movimientos recientes',
              subtitle: 'Agrega un movimiento y aparecerá aquí.',
              compact: true,
            )
          else
            ...recent.take(5).map((transaction) {
              final category = categories.firstWhereOrNull(
                (item) => item.id == transaction.categoryId,
              );
              final account = accounts.firstWhereOrNull(
                (item) => item.id == transaction.accountId,
              );
              return TransactionRow(
                transaction: transaction,
                category: category,
                account: account,
              );
            }),
          if (recent.length > 5)
            TextButton(
              onPressed: () => context.go('/transactions'),
              child: const Text('Ver todos'),
            ),
        ],
      ),
    );
  }
}

class _AccountCardSkeletons extends StatelessWidget {
  const _AccountCardSkeletons();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => const SkeletonBlock(
          width: 168,
          height: 110,
          radius: AppSpacing.radiusLg,
        ),
      ),
    );
  }
}

class _RecentSkeletons extends StatelessWidget {
  const _RecentSkeletons();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SkeletonBlock(height: 56),
          SizedBox(height: 8),
          SkeletonBlock(height: 56),
          SizedBox(height: 8),
          SkeletonBlock(height: 56),
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = parseCategoryColor(account.color ?? '#18181B');
    final balance = ref.watch(currentBalanceProvider(account.id));
    final isCredit = account.type == AccountType.credit;
    return Container(
      width: 168,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const Spacer(),
          Text(
            account.name,
            style: GoogleFonts.instrumentSans(
              color: AppColors.gray900,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isCredit ? '-${formatAmount(balance, account.currency)}' : formatAmount(balance, account.currency),
            style: GoogleFonts.ibmPlexMono(
              color: isCredit ? AppColors.expense : AppColors.gray900,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSummaryBar extends StatelessWidget {
  const _MonthSummaryBar({
    required this.income,
    required this.expense,
    required this.net,
    required this.currency,
  });

  final int income;
  final int expense;
  final int net;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              label: 'Ingresos',
              amount: income,
              currency: currency,
              color: AppColors.income,
            ),
          ),
          Expanded(
            child: _Metric(
              label: 'Gastos',
              amount: expense,
              currency: currency,
              color: AppColors.expense,
            ),
          ),
          Expanded(
            child: _Metric(
              label: 'Balance',
              amount: net,
              currency: currency,
              color: net >= 0 ? AppColors.income : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  final String label;
  final int amount;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.instrumentSans(
            color: AppColors.gray500,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatAmount(amount.abs(), currency),
          style: GoogleFonts.ibmPlexMono(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LiquidityWarningBanner extends StatelessWidget {
  const _LiquidityWarningBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.expenseBg,
        border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.expense, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acción desfavorable para tu salud económica',
                  style: GoogleFonts.instrumentSans(
                    color: AppColors.expense,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tu liquidez disponible es menor que tu deuda en tarjetas. Considera reducir gastos o realizar un pago parcial.',
                  style: GoogleFonts.instrumentSans(
                    color: AppColors.expense,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
