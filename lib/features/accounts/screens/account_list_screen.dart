import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ordo_app_bar.dart';
import '../../../shared/widgets/resource_status_banner.dart';
import '../../../shared/widgets/section_label.dart';
import '../providers/accounts_provider.dart';
import '../widgets/account_form_sheet.dart';

class AccountListScreen extends ConsumerWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsState = ref.watch(accountsProvider);
    final accounts = ref.watch(accountsListProvider);
    final activeAccounts = accounts
        .where((account) => account.isActive)
        .toList();
    final currency = activeAccounts.firstOrNull?.currency ?? 'USD';
    final total = activeAccounts.fold<int>(0, (sum, account) {
      final balance = ref.watch(currentBalanceProvider(account.id));
      return account.type == AccountType.credit ? sum - balance : sum + balance;
    });

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: OrdoAppBar(
        title: 'Cuentas',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.gray900),
            onPressed: () => _showAccountSheet(context),
          ),
        ],
      ),
      body: ListView(
        children: [
          ResourceStatusBanner(
            isLoading: accountsState.isLoading,
            isSyncing: accountsState.isSyncing,
            error: accountsState.error,
            onRetry: () => ref.read(accountsProvider.notifier).refresh(),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BALANCE TOTAL',
                  style: GoogleFonts.instrumentSans(
                    color: AppColors.gray400,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.66,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatAmount(total, currency),
                  style: GoogleFonts.ibmPlexMono(
                    color: AppColors.gray900,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SectionLabel('MIS CUENTAS'),
          ),
          if (accountsState.isLoading && activeAccounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SkeletonBlock(height: 74, radius: AppSpacing.radiusLg),
                  SizedBox(height: 8),
                  SkeletonBlock(height: 74, radius: AppSpacing.radiusLg),
                ],
              ),
            )
          else if (activeAccounts.isEmpty)
            EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Sin cuentas',
              subtitle: 'Agrega tu primera cuenta para controlar tu dinero.',
              action: SizedBox(
                width: 180,
                child: OutlinedButton(
                  onPressed: () => _showAccountSheet(context),
                  child: const Text('Agregar cuenta'),
                ),
              ),
            )
          else
            ...activeAccounts.map(
              (account) => _AccountListTile(
                account: account,
                onTap: () => context.go('/accounts/${account.id}'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAccountSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AccountFormSheet(),
    );
  }
}

class _AccountListTile extends ConsumerWidget {
  const _AccountListTile({required this.account, required this.onTap});

  final Account account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = parseCategoryColor(account.color ?? '#18181B');
    final balance = ref.watch(currentBalanceProvider(account.id));
    final isCredit = account.type == AccountType.credit;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.gray200),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(
                _accountIcon(account.type),
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: GoogleFonts.instrumentSans(
                      color: AppColors.gray900,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _accountTypeLabel(account.type),
                    style: GoogleFonts.instrumentSans(
                      color: AppColors.gray500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isCredit
                      ? '-${formatAmount(balance, account.currency)}'
                      : formatAmount(balance, account.currency),
                  style: GoogleFonts.ibmPlexMono(
                    color: isCredit ? AppColors.expense : AppColors.gray900,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  account.currency,
                  style: GoogleFonts.instrumentSans(
                    color: AppColors.gray400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData _accountIcon(AccountType type) {
  return switch (type) {
    AccountType.checking => Icons.account_balance_outlined,
    AccountType.savings => Icons.savings_outlined,
    AccountType.cash => Icons.payments_outlined,
    AccountType.credit => Icons.credit_card,
    AccountType.investment => Icons.show_chart,
  };
}

String _accountTypeLabel(AccountType type) {
  return switch (type) {
    AccountType.checking => 'Checking',
    AccountType.savings => 'Savings',
    AccountType.cash => 'Cash',
    AccountType.credit => 'Credit',
    AccountType.investment => 'Investment',
  };
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
