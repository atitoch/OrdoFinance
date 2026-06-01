import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/month_selector.dart';
import '../../../shared/widgets/ordo_app_bar.dart';
import '../../../shared/widgets/resource_status_banner.dart';
import '../../../shared/widgets/section_label.dart';
import '../../categories/providers/categories_provider.dart';
import '../../transactions/providers/transactions_provider.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsStatus = ref.watch(transactionsProvider.select((s) => s.status));
    final categoriesStatus = ref.watch(categoriesProvider.select((s) => s.status));
    final transactions = ref.watch(transactionsListProvider);
    final categories = ref.watch(categoriesListProvider);
    final monthTransactions = transactions
        .where(
          (tx) => tx.date.year == _month.year && tx.date.month == _month.month,
        )
        .toList();
    final income = _sum(monthTransactions, TransactionType.income);
    final expense = _sum(monthTransactions, TransactionType.expense);
    final currency = monthTransactions.firstOrNull?.currency ?? 'USD';
    final breakdown = _buildBreakdown(monthTransactions, categories);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: const OrdoAppBar(title: 'Estadísticas'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ResourceStatusBanner(
            isLoading: transactionsStatus.isLoading || categoriesStatus.isLoading,
            isSyncing: transactionsStatus.isSyncing || categoriesStatus.isSyncing,
            error: transactionsStatus.error ?? categoriesStatus.error,
            onRetry: () {
              ref.read(transactionsProvider.notifier).refresh();
              ref.read(categoriesProvider.notifier).refresh();
            },
          ),
          MonthSelector(
            month: _month,
            canGoNext: !_isCurrentMonth,
            onPrevious: () => setState(
              () => _month = DateTime(_month.year, _month.month - 1),
            ),
            onNext: () => setState(
              () => _month = DateTime(_month.year, _month.month + 1),
            ),
            onTapLabel: _pickMonth,
          ),
          SizedBox(
            height: 130,
            child: ListView(
              padding: const EdgeInsets.all(16),
              scrollDirection: Axis.horizontal,
              children: [
                _SummaryCard(
                  label: 'INGRESOS',
                  amount: income,
                  currency: currency,
                  color: AppColors.income,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'GASTOS',
                  amount: expense,
                  currency: currency,
                  color: AppColors.expense,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'BALANCE',
                  amount: income - expense,
                  currency: currency,
                  color: income - expense >= 0
                      ? AppColors.income
                      : AppColors.expense,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SectionLabel('POR CATEGORÍA'),
          ),
          if (transactionsStatus.isLoading && breakdown.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SkeletonBlock(height: 48),
                  SizedBox(height: 8),
                  SkeletonBlock(height: 48),
                ],
              ),
            )
          else if (breakdown.isEmpty)
            const EmptyState(
              icon: Icons.pie_chart_outline,
              title: 'Sin datos de gastos',
              subtitle: 'El desglose aparece cuando registres gastos.',
              compact: true,
            )
          else
            ...breakdown.map(
              (item) => _CategoryBreakdownRow(item: item, currency: currency),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SectionLabel('TENDENCIA MENSUAL'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 190,
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              color: AppColors.white,
              child: transactionsStatus.isLoading && transactions.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gray900,
                      ),
                    )
                  : transactions.isEmpty
                  ? const EmptyState(
                      icon: Icons.show_chart,
                      title: 'Sin tendencia aún',
                      subtitle: 'Agrega movimientos para ver la tendencia mensual.',
                      compact: true,
                    )
                  : RepaintBoundary(child: LineChart(_trendData(transactions))),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month),
    );
    if (picked != null) {
      setState(() => _month = DateTime(picked.year, picked.month));
    }
  }

  int _sum(List<Transaction> transactions, TransactionType type) => transactions
      .where((tx) => tx.type == type)
      .fold<int>(0, (sum, tx) => sum + tx.amount);

  List<_CategoryBreakdown> _buildBreakdown(
    List<Transaction> transactions,
    List<Category> categories,
  ) {
    final expenses = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .toList();
    final total = expenses.fold<int>(0, (sum, tx) => sum + tx.amount);
    final grouped = <String, int>{};
    for (final tx in expenses) {
      grouped.update(
        tx.categoryId ?? 'uncategorized',
        (value) => value + tx.amount,
        ifAbsent: () => tx.amount,
      );
    }
    final items = grouped.entries.map((entry) {
      final category =
          categories.firstWhereOrNull((item) => item.id == entry.key) ??
          const Category(
            id: 'uncategorized',
            name: 'Sin categoría',
            type: CategoryType.expense,
            color: '#71717A',
            icon: 'category',
            isSystem: true,
          );
      return _CategoryBreakdown(
        category: category,
        total: entry.value,
        percentage: total == 0 ? 0 : entry.value / total,
      );
    }).toList();
    items.sort((a, b) => b.total.compareTo(a.total));
    return items;
  }

  LineChartData _trendData(List<Transaction> transactions) {
    final months = List.generate(
      6,
      (index) => DateTime(_month.year, _month.month - (5 - index)),
    );
    final income = <FlSpot>[];
    final expense = <FlSpot>[];
    for (var i = 0; i < months.length; i++) {
      final month = months[i];
      final txs = transactions
          .where(
            (tx) => tx.date.year == month.year && tx.date.month == month.month,
          )
          .toList();
      income.add(FlSpot(i.toDouble(), _sum(txs, TransactionType.income) / 100));
      expense.add(
        FlSpot(i.toDouble(), _sum(txs, TransactionType.expense) / 100),
      );
    }
    return LineChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= months.length) {
                return const SizedBox.shrink();
              }
              return Text(
                DateFormat.MMM().format(months[index]),
                style: GoogleFonts.instrumentSans(
                  color: AppColors.gray500,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        _line(income, AppColors.income),
        _line(expense, AppColors.expense),
      ],
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
    spots: spots,
    color: color,
    barWidth: 2,
    dotData: FlDotData(
      getDotPainter: (spot, percent, bar, index) =>
          FlDotCirclePainter(radius: 4, color: color, strokeWidth: 0),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 140),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.gray200),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.instrumentSans(
            color: AppColors.gray400,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.88,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formatAmount(amount.abs(), currency),
          style: GoogleFonts.ibmPlexMono(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _CategoryBreakdownRow extends StatelessWidget {
  const _CategoryBreakdownRow({required this.item, required this.currency});
  final _CategoryBreakdown item;
  final String currency;
  @override
  Widget build(BuildContext context) {
    final color = parseCategoryColor(item.category.color);
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 140, child: CategoryChip(category: item.category)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: item.percentage,
                    minHeight: 4,
                    color: color,
                    backgroundColor: AppColors.gray100,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${(item.percentage * 100).round()}%',
                  style: GoogleFonts.instrumentSans(
                    color: AppColors.gray400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatAmount(item.total, currency),
            style: GoogleFonts.ibmPlexMono(
              color: AppColors.gray900,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown {
  const _CategoryBreakdown({
    required this.category,
    required this.total,
    required this.percentage,
  });
  final Category category;
  final int total;
  final double percentage;
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
