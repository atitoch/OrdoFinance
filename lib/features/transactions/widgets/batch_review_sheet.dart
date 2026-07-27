import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ulid/ulid.dart';

import '../../../core/ai/parsed_transaction.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/ordo_button.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../categories/providers/categories_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/transactions_provider.dart';
import 'transaction_edit_sheets.dart';

/// Revisión de los movimientos detectados en una captura antes de guardarlos.
/// La IA se equivoca leyendo listados, así que nada entra a las cuentas sin
/// pasar por aquí.
Future<bool?> showBatchReviewSheet(
  BuildContext context,
  List<ParsedTransaction> parsed,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Cerrar por accidente aquí tira todo el trabajo de revisión.
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (context) => BatchReviewSheet(parsed: parsed),
  );
}

class BatchReviewSheet extends ConsumerStatefulWidget {
  const BatchReviewSheet({required this.parsed, super.key});

  final List<ParsedTransaction> parsed;

  @override
  ConsumerState<BatchReviewSheet> createState() => _BatchReviewSheetState();
}

class _BatchReviewSheetState extends ConsumerState<BatchReviewSheet> {
  late List<_DraftMovement> _drafts;
  String? _accountId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final categories = ref.read(categoriesListProvider);
    _drafts = widget.parsed
        .map((item) => _DraftMovement.fromParsed(item, categories))
        .toList();
    _accountId = ref.read(accountsListProvider).firstOrNull?.id;
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  int get _selectedCount => _drafts.where((d) => d.included).length;

  @override
  Widget build(BuildContext context) {
    final accounts = ref
        .watch(accountsListProvider)
        .where((account) => account.isActive)
        .toList();
    final existing = ref.watch(transactionsListProvider);
    final dateFormats = ref.watch(dateFormatsProvider);
    final String currency =
        accounts.firstWhereOrNull((a) => a.id == _accountId)?.currency ??
        ref.watch(defaultCurrencyProvider);

    // Marcar posibles repetidos: al reimportar una captura que solapa con otra
    // anterior es fácil duplicar medio mes sin darse cuenta.
    for (final draft in _drafts) {
      draft.isDuplicate = existing.any(
        (tx) =>
            tx.amount == draft.cents &&
            tx.type == draft.type &&
            _sameDay(tx.date, draft.date),
      );
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _Header(
                total: _drafts.length,
                onClose: () => Navigator.of(context).pop(false),
              ),
              _AccountPicker(
                accounts: accounts,
                accountId: _accountId,
                onChanged: (value) => setState(() => _accountId = value),
              ),
              const Divider(height: 1, color: AppColors.gray200),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: _drafts.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.gray100),
                  itemBuilder: (context, index) => _DraftRow(
                    draft: _drafts[index],
                    currency: currency,
                    dateFormats: dateFormats,
                    onChanged: () => setState(() {}),
                    onPickCategory: () => _pickCategory(_drafts[index]),
                    onPickAmount: () => _pickAmount(_drafts[index]),
                    onPickDate: () => _pickDate(_drafts[index]),
                  ),
                ),
              ),
              _Footer(
                selectedCount: _selectedCount,
                isSaving: _isSaving,
                canSave:
                    _accountId != null && _selectedCount > 0 && !_isSaving,
                onSave: _save,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickCategory(_DraftMovement draft) async {
    final category = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryPickerSheet(
        type: draft.type,
        selectedCategoryId: draft.category?.id,
      ),
    );
    if (category != null) setState(() => draft.category = category);
  }

  Future<void> _pickAmount(_DraftMovement draft) async {
    final value = await showAmountNumpadSheet(
      context,
      centsToAmountInput(draft.cents),
    );
    if (value != null) {
      setState(() => draft.cents = amountStringToCents(value));
    }
  }

  Future<void> _pickDate(_DraftMovement draft) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.date.isAfter(now) ? now : draft.date,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) setState(() => draft.date = picked);
  }

  Future<void> _save() async {
    final accountId = _accountId;
    if (accountId == null || _isSaving) return;

    final accounts = ref.read(accountsListProvider);
    final String currency =
        accounts.firstWhereOrNull((a) => a.id == accountId)?.currency ??
        ref.read(defaultCurrencyProvider);
    final now = DateTime.now();

    final transactions = <Transaction>[];
    for (final draft in _drafts.where((d) => d.included)) {
      transactions.add(
        Transaction(
          id: Ulid().toString(),
          type: draft.type,
          amount: draft.cents,
          currency: currency,
          accountId: accountId,
          categoryId: draft.category?.id,
          description: draft.descriptionController.text.trim().isEmpty
              ? 'Movimiento importado'
              : draft.descriptionController.text.trim(),
          tags: const [],
          date: draft.date,
          createdAt: now,
        ),
      );
    }
    if (transactions.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(transactionsProvider.notifier)
          .addTransactions(transactions);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Estado editable de cada movimiento detectado.
class _DraftMovement {
  _DraftMovement({
    required this.type,
    required this.cents,
    required this.date,
    required this.descriptionController,
    this.category,
  });

  factory _DraftMovement.fromParsed(
    ParsedTransaction parsed,
    List<Category> categories,
  ) {
    // Una captura no dice a qué cuenta va un traspaso, y una transferencia sin
    // destino es inválida: se trata como gasto y ya se corrige a mano.
    final type = parsed.type == 'income'
        ? TransactionType.income
        : TransactionType.expense;
    final name = parsed.categoryName?.toLowerCase();
    return _DraftMovement(
      type: type,
      cents: (parsed.amount * 100).round().abs(),
      date: parsed.date ?? DateTime.now(),
      descriptionController: TextEditingController(text: parsed.description),
      category: name == null
          ? null
          : categories.firstWhereOrNull((c) => c.name.toLowerCase() == name),
    );
  }

  TransactionType type;
  int cents;
  DateTime date;
  Category? category;
  final TextEditingController descriptionController;
  bool included = true;
  bool isDuplicate = false;

  void dispose() => descriptionController.dispose();
}

class _Header extends StatelessWidget {
  const _Header({required this.total, required this.onClose});

  final int total;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.gray200,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      total == 1
                          ? 'Se detectó 1 movimiento'
                          : 'Se detectaron $total movimientos',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Revisa y corrige antes de guardar.',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.gray500,
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({
    required this.accounts,
    required this.accountId,
    required this.onChanged,
  });

  final List<Account> accounts;
  final String? accountId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Text(
            'CUENTA',
            style: GoogleFonts.instrumentSans(
              color: AppColors.gray400,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.66,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gray200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: accountId,
                  isExpanded: true,
                  hint: Text(
                    'Selecciona una cuenta',
                    style: GoogleFonts.instrumentSans(
                      color: AppColors.gray400,
                      fontSize: 14,
                    ),
                  ),
                  items: accounts
                      .map(
                        (account) => DropdownMenuItem(
                          value: account.id,
                          child: Text(
                            account.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.instrumentSans(
                              color: AppColors.gray900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftRow extends StatelessWidget {
  const _DraftRow({
    required this.draft,
    required this.currency,
    required this.dateFormats,
    required this.onChanged,
    required this.onPickCategory,
    required this.onPickAmount,
    required this.onPickDate,
  });

  final _DraftMovement draft;
  final String currency;
  final AppDateFormats dateFormats;
  final VoidCallback onChanged;
  final VoidCallback onPickCategory;
  final VoidCallback onPickAmount;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final isExpense = draft.type == TransactionType.expense;
    final color = isExpense ? AppColors.expense : AppColors.income;

    return Opacity(
      opacity: draft.included ? 1 : 0.45,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: draft.included,
                  onChanged: (value) {
                    draft.included = value ?? false;
                    onChanged();
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: draft.descriptionController,
                    enabled: draft.included,
                    style: GoogleFonts.instrumentSans(
                      color: AppColors.gray900,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Descripción',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: draft.included ? onPickAmount : null,
                  child: Text(
                    formatAmount(draft.cents, currency),
                    style: GoogleFonts.ibmPlexMono(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _TypeToggle(
                    type: draft.type,
                    onChanged: (value) {
                      draft.type = value;
                      onChanged();
                    },
                  ),
                  _Chip(
                    icon: draft.category == null
                        ? Icons.category_outlined
                        : parseCategoryIcon(draft.category!.icon),
                    iconColor: draft.category == null
                        ? AppColors.gray400
                        : parseCategoryColor(draft.category!.color),
                    label: draft.category?.name ?? 'Sin categoría',
                    onTap: draft.included ? onPickCategory : null,
                  ),
                  _Chip(
                    icon: Icons.calendar_today_outlined,
                    iconColor: AppColors.gray400,
                    label: dateFormats.date(draft.date),
                    onTap: draft.included ? onPickDate : null,
                  ),
                ],
              ),
            ),
            if (draft.isDuplicate && draft.included) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 13,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Ya hay un movimiento igual ese día',
                        style: GoogleFonts.instrumentSans(
                          color: AppColors.warning,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.type, required this.onChanged});

  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final isExpense = type == TransactionType.expense;
    return GestureDetector(
      onTap: () => onChanged(
        isExpense ? TransactionType.income : TransactionType.expense,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isExpense ? AppColors.expenseBg : AppColors.incomeBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          isExpense ? 'Gasto' : 'Ingreso',
          style: GoogleFonts.instrumentSans(
            color: isExpense ? AppColors.expense : AppColors.income,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray200),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.instrumentSans(
                color: AppColors.gray600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.selectedCount,
    required this.isSaving,
    required this.canSave,
    required this.onSave,
  });

  final int selectedCount;
  final bool isSaving;
  final bool canSave;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      child: SafeArea(
        top: false,
        child: OrdoButton.primary(
          label: selectedCount == 1
              ? 'Guardar 1 movimiento'
              : 'Guardar $selectedCount movimientos',
          onPressed: canSave ? onSave : null,
          isLoading: isSaving,
        ),
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
