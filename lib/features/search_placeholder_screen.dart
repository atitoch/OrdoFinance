import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../data/models/transaction.dart';
import '../shared/widgets/ordo_app_bar.dart';
import '../shared/widgets/transaction_row.dart';
import 'accounts/providers/accounts_provider.dart';
import 'categories/providers/categories_provider.dart';
import 'transactions/providers/transactions_provider.dart';

class SearchPlaceholderScreen extends ConsumerStatefulWidget {
  const SearchPlaceholderScreen({super.key});

  @override
  ConsumerState<SearchPlaceholderScreen> createState() =>
      _SearchPlaceholderScreenState();
}

class _SearchPlaceholderScreenState
    extends ConsumerState<SearchPlaceholderScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Transaction> _filter(List<Transaction> all) {
    if (_query.isEmpty) return const [];
    final q = _query.toLowerCase();
    return all.where((tx) {
      return tx.description.toLowerCase().contains(q) ||
          (tx.note?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(transactionsListProvider);
    final categories = ref.watch(categoriesListProvider);
    final accounts = ref.watch(accountsListProvider);
    final results = _filter(all);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: OrdoAppBar(
        title: '',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray900),
          onPressed: () => context.pop(),
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              style: GoogleFonts.instrumentSans(
                color: AppColors.gray900,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar movimientos…',
                hintStyle: GoogleFonts.instrumentSans(
                  color: AppColors.gray400,
                  fontSize: 15,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.gray400,
                  size: 20,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.gray400,
                          size: 20,
                        ),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.gray50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.gray900,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? _EmptyQuery()
                : results.isEmpty
                ? _NoResults(query: _query)
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final tx = results[index];
                      final category = categories.firstWhereOrNull(
                        (c) => c.id == tx.categoryId,
                      );
                      final account = accounts.firstWhereOrNull(
                        (a) => a.id == tx.accountId,
                      );
                      return InkWell(
                        onTap: () => context.push('/transactions/${tx.id}'),
                        child: TransactionRow(
                          transaction: tx,
                          category: category,
                          account: account,
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

class _EmptyQuery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search, size: 48, color: AppColors.gray300),
          const SizedBox(height: 16),
          Text(
            'Busca tus movimientos',
            style: GoogleFonts.instrumentSans(
              color: AppColors.gray900,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Escribe para filtrar por descripción o nota',
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

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_outlined,
            size: 48,
            color: AppColors.gray300,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin resultados para "$query"',
            style: GoogleFonts.instrumentSans(
              color: AppColors.gray900,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Intenta con otra palabra',
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

extension _IterableExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
