import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/account.dart';
import '../../../data/models/transaction.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ordo_app_bar.dart';
import '../../../shared/widgets/resource_status_banner.dart';
import '../../../shared/widgets/transaction_row.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../categories/providers/categories_provider.dart';
import '../providers/transactions_provider.dart';
import '../widgets/transaction_edit_sheets.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({this.accountId, super.key});

  final String? accountId;

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  late String? _selectedAccountId = widget.accountId;

  @override
  Widget build(BuildContext context) {
    final transactionsStatus = ref.watch(transactionsProvider.select((s) => s.status));
    final accounts = ref.watch(accountsListProvider)
        .where((a) => a.isActive)
        .toList();
    final categories = ref.watch(categoriesListProvider);
    final transactions = ref.watch(transactionsListProvider).where((tx) {
      final matchesMonth =
          tx.date.year == _selectedMonth.year &&
          tx.date.month == _selectedMonth.month;
      final matchesAccount =
          _selectedAccountId == null ||
          tx.accountId == _selectedAccountId ||
          tx.toAccountId == _selectedAccountId;
      return matchesMonth && matchesAccount;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    final groups = _groupByDate(transactions);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: OrdoAppBar(
        title: 'Movimientos',
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.gray900),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          ResourceStatusBanner(
            isLoading: transactionsStatus.isLoading,
            isSyncing: transactionsStatus.isSyncing,
            error: transactionsStatus.error,
            onRetry: () => ref.read(transactionsProvider.notifier).refresh(),
          ),
          _MonthSelectorBar(
            month: _selectedMonth,
            onPrevious: () => setState(
              () => _selectedMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month - 1,
              ),
            ),
            onNext: () => setState(
              () => _selectedMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month + 1,
              ),
            ),
            onPick: _showMonthPicker,
          ),
          if (accounts.isNotEmpty)
            _AccountFilterBar(
              accounts: accounts,
              selectedAccountId: _selectedAccountId,
              onSelected: (id) => setState(() => _selectedAccountId = id),
            ),
          Expanded(
            child: transactionsStatus.isLoading && transactions.isEmpty
                ? const _TransactionListSkeleton()
                : transactions.isEmpty
                ? const _EmptyTransactions()
                : CustomScrollView(
                    slivers: [
                      for (final group in groups.entries)
                        SliverMainAxisGroup(
                          slivers: [
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _DateHeaderDelegate(
                                label: _dateLabel(group.key),
                              ),
                            ),
                            SliverList.builder(
                              itemCount: group.value.length,
                              itemBuilder: (context, index) {
                                final transaction = group.value[index];
                                final category = categories.firstWhereOrNull(
                                  (item) => item.id == transaction.categoryId,
                                );
                                final account = accounts.firstWhereOrNull(
                                  (item) => item.id == transaction.accountId,
                                );
                                return InkWell(
                                  onTap: () => context.go(
                                    '/transactions/${transaction.id}',
                                  ),
                                  child: TransactionRow(
                                    transaction: transaction,
                                    category: category,
                                    account: account,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16),
        child: FloatingActionButton.extended(
          onPressed: _showAddSheet,
          backgroundColor: AppColors.gray900,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          icon: const Icon(Icons.add, color: AppColors.white),
          label: Text(
            'Agregar',
            style: GoogleFonts.instrumentSans(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMonthPicker() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.white,
      builder: (context) => _MonthPickerSheet(selectedMonth: _selectedMonth),
    );
    if (picked != null) setState(() => _selectedMonth = picked);
  }

  Future<void> _showAddSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
    );
  }
}

class _AccountFilterBar extends StatelessWidget {
  const _AccountFilterBar({
    required this.accounts,
    required this.selectedAccountId,
    required this.onSelected,
  });

  final List<Account> accounts;
  final String? selectedAccountId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: accounts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final selected = selectedAccountId == null;
            return _FilterChip(
              label: 'Todas',
              selected: selected,
              onTap: () => onSelected(null),
            );
          }
          final account = accounts[index - 1];
          final selected = selectedAccountId == account.id;
          return _FilterChip(
            label: account.name,
            selected: selected,
            onTap: () => onSelected(account.id),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.gray900 : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.gray900 : AppColors.gray200,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.instrumentSans(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.white : AppColors.gray600,
          ),
        ),
      ),
    );
  }
}

class _MonthSelectorBar extends StatelessWidget {
  const _MonthSelectorBar({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left, color: AppColors.gray900),
          ),
          Expanded(
            child: InkWell(
              onTap: onPick,
              child: Center(
                child: Text(
                  DateFormat.yMMMM().format(month),
                  style: GoogleFonts.instrumentSans(
                    color: AppColors.gray900,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, color: AppColors.gray900),
          ),
        ],
      ),
    );
  }
}

class _MonthPickerSheet extends StatefulWidget {
  const _MonthPickerSheet({required this.selectedMonth});

  final DateTime selectedMonth;

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year = widget.selectedMonth.year;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SizedBox(
      height: 360,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _year--),
                icon: const Icon(Icons.chevron_left),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  '$_year',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.instrumentSans(
                    color: AppColors.gray900,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _year++),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisExtent: 48,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = DateTime(_year, index + 1);
                final selected =
                    month.year == widget.selectedMonth.year &&
                    month.month == widget.selectedMonth.month;
                final disabled = month.isAfter(DateTime(now.year, now.month));
                return InkWell(
                  onTap: disabled
                      ? null
                      : () => Navigator.of(context).pop(month),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.gray900 : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormat.MMM().format(month),
                      style: GoogleFonts.instrumentSans(
                        color: disabled
                            ? AppColors.gray400
                            : selected
                            ? AppColors.white
                            : AppColors.gray900,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _DateHeaderDelegate({required this.label});

  final String label;

  @override
  double get minExtent => 32;

  @override
  double get maxExtent => 32;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: 32,
      color: AppColors.gray50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.instrumentSans(
          color: AppColors.gray400,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.88,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DateHeaderDelegate oldDelegate) =>
      oldDelegate.label != label;
}

class _TransactionListSkeleton extends StatelessWidget {
  const _TransactionListSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SkeletonBlock(height: 64),
          SizedBox(height: 8),
          SkeletonBlock(height: 64),
          SizedBox(height: 8),
          SkeletonBlock(height: 64),
          SizedBox(height: 8),
          SkeletonBlock(height: 64),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.gray300,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin movimientos',
            style: GoogleFonts.instrumentSans(
              color: AppColors.gray900,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toca + para agregar el primero',
            style: GoogleFonts.instrumentSans(
              color: AppColors.gray500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

Map<DateTime, List<Transaction>> _groupByDate(List<Transaction> transactions) {
  final groups = <DateTime, List<Transaction>>{};
  for (final transaction in transactions) {
    final key = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );
    groups.putIfAbsent(key, () => []).add(transaction);
  }
  return groups;
}

String _dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  if (date == today) return 'HOY';
  if (date == yesterday) return 'AYER';
  return DateFormat.MMMd().format(date).toUpperCase();
}

extension _IterableExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
