import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ulid/ulid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/ordo_button.dart';
import '../../../shared/widgets/ordo_text_field.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../categories/providers/categories_provider.dart';
import '../providers/transactions_provider.dart';

Future<String?> showAmountNumpadSheet(
  BuildContext context,
  String initialValue,
) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AmountNumpadSheet(initialValue: initialValue),
  );
}

class _AmountNumpadSheet extends StatefulWidget {
  const _AmountNumpadSheet({required this.initialValue});

  final String initialValue;

  @override
  State<_AmountNumpadSheet> createState() => _AmountNumpadSheetState();
}

class _AmountNumpadSheetState extends State<_AmountNumpadSheet> {
  late String _value = widget.initialValue.isEmpty ? '0' : widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _value,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexMono(
                        color: AppColors.gray900,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(_value),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.gray900,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: const [
                  _NumpadRow(keys: ['7', '8', '9', 'backspace']),
                  _NumpadRow(keys: ['4', '5', '6', '']),
                  _NumpadRow(keys: ['1', '2', '3', '']),
                  _NumpadRow(keys: ['.', '0', '', '']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _tap(String key) {
    if (key.isEmpty) return;
    setState(() {
      if (key == 'backspace') {
        _value = _value.length <= 1
            ? '0'
            : _value.substring(0, _value.length - 1);
      } else if (key == '.') {
        if (!_value.contains('.')) _value += '.';
      } else {
        _value = _value == '0' ? key : '$_value$key';
      }
    });
  }
}

class _NumpadRow extends StatelessWidget {
  const _NumpadRow({required this.keys});

  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_AmountNumpadSheetState>()!;
    return Expanded(
      child: Row(
        children: keys.map((key) {
          return Expanded(
            child: InkWell(
              onTap: key.isEmpty ? null : () => state._tap(key),
              child: Container(
                height: 56,
                color: AppColors.gray50,
                alignment: Alignment.center,
                child: key == 'backspace'
                    ? const Icon(
                        Icons.backspace_outlined,
                        color: AppColors.gray900,
                        size: 20,
                      )
                    : Text(
                        key,
                        style: GoogleFonts.instrumentSans(
                          color: AppColors.gray900,
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CategoryPickerSheet extends ConsumerStatefulWidget {
  const CategoryPickerSheet({
    required this.type,
    this.selectedCategoryId,
    super.key,
  });

  final TransactionType type;
  final String? selectedCategoryId;

  @override
  ConsumerState<CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<CategoryPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.type == TransactionType.income ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesListProvider);
    final expense = categories
        .where(
          (item) =>
              item.type == CategoryType.expense ||
              item.type == CategoryType.both,
        )
        .toList();
    final income = categories
        .where(
          (item) =>
              item.type == CategoryType.income ||
              item.type == CategoryType.both,
        )
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              Text(
                'Seleccionar categoría',
                style: GoogleFonts.instrumentSans(
                  color: AppColors.gray900,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Gasto'),
                  Tab(text: 'Ingreso'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _CategoryGrid(
                      categories: expense,
                      selectedCategoryId: widget.selectedCategoryId,
                    ),
                    _CategoryGrid(
                      categories: income,
                      selectedCategoryId: widget.selectedCategoryId,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selectedCategoryId,
  });

  final List<Category> categories;
  final String? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 90,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
        childAspectRatio: 80 / 76,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final color = parseCategoryColor(category.color);
        final selected = category.id == selectedCategoryId;
        return InkWell(
          onTap: () => Navigator.of(context).pop(category),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.08) : AppColors.white,
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(
                    parseCategoryIcon(category.icon),
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.instrumentSans(
                      color: AppColors.gray900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _scrollController = ScrollController();
  final _amountKey = GlobalKey();
  final _descriptionKey = GlobalKey();
  final _accountKey = GlobalKey();
  final _toAccountKey = GlobalKey();
  final _categoryKey = GlobalKey();

  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  String _amount = '0';
  String? _accountId;
  String? _toAccountId;
  Category? _category;
  String? _descriptionError;
  String? _amountError;
  String? _accountError;
  String? _toAccountError;
  String? _categoryError;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _scrollController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref
        .watch(accountsListProvider)
        .where((account) => account.isActive)
        .toList();
    _accountId ??= accounts.firstOrNull?.id;
    final currency = accounts
            .firstWhereOrNull((a) => a.id == _accountId)
            ?.currency ??
        'USD';
    final amountCents = _amountToCents(_amount);
    final amountIsZero = amountCents <= 0;

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
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // ── Type selector ──────────────────────────────────
                    _TypeSelector(
                      selected: _type,
                      onChanged: (type) => setState(() {
                        _type = type;
                        _categoryError = null;
                        _toAccountError = null;
                      }),
                    ),
                    const SizedBox(height: 20),

                    // ── Amount ─────────────────────────────────────────
                    GestureDetector(
                      key: _amountKey,
                      onTap: _editAmount,
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                formatAmount(amountCents, currency),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.ibmPlexMono(
                                  color: _amountError != null
                                      ? AppColors.expense
                                      : amountIsZero
                                      ? AppColors.gray300
                                      : AppColors.gray900,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                child: Text(
                                  amountIsZero
                                      ? 'Toca para ingresar el monto'
                                      : '',
                                  style: GoogleFonts.instrumentSans(
                                    color: AppColors.gray400,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 150),
                            child: _amountError != null
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: AppColors.expense,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _amountError!,
                                          style: GoogleFonts.instrumentSans(
                                            color: AppColors.expense,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Description ────────────────────────────────────
                    OrdoTextField(
                      key: _descriptionKey,
                      label: 'DESCRIPCIÓN',
                      controller: _descriptionController,
                      maxLength: 80,
                      errorText: _descriptionError,
                      onChanged: (_) =>
                          setState(() => _descriptionError = null),
                    ),
                    const SizedBox(height: 16),

                    // ── Account ────────────────────────────────────────
                    _FieldLabel(
                      text: _type == TransactionType.transfer
                          ? 'CUENTA ORIGEN'
                          : 'CUENTA',
                    ),
                    const SizedBox(height: 4),
                    _DropdownField(
                      key: _accountKey,
                      value: _accountId,
                      hint: 'Selecciona una cuenta',
                      error: _accountError,
                      items: accounts.map(_accountDropdownItem).toList(),
                      onChanged: (value) => setState(() {
                        _accountId = value;
                        _accountError = null;
                        _toAccountError = null;
                      }),
                    ),
                    const SizedBox(height: 16),

                    // ── To account (transfer) ──────────────────────────
                    if (_type == TransactionType.transfer) ...[
                      _FieldLabel(text: 'CUENTA DESTINO'),
                      const SizedBox(height: 4),
                      _DropdownField(
                        key: _toAccountKey,
                        value: _toAccountId,
                        hint: 'Selecciona cuenta destino',
                        error: _toAccountError,
                        items: accounts.map(_accountDropdownItem).toList(),
                        onChanged: (value) => setState(() {
                          _toAccountId = value;
                          _toAccountError = null;
                        }),
                      ),
                      if (_toAccountId != null &&
                          accounts
                                  .firstWhereOrNull((a) => a.id == _toAccountId)
                                  ?.type ==
                              AccountType.credit) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.incomeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.credit_card_outlined,
                                color: AppColors.income,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Este pago reducirá la deuda de la tarjeta',
                                style: GoogleFonts.instrumentSans(
                                  color: AppColors.income,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],

                    // ── Category ───────────────────────────────────────
                    if (_type != TransactionType.transfer) ...[
                      _FieldLabel(text: 'CATEGORÍA'),
                      const SizedBox(height: 4),
                      _CategoryField(
                        key: _categoryKey,
                        category: _category,
                        error: _categoryError,
                        onTap: _pickCategory,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Date ───────────────────────────────────────────
                    _FieldLabel(text: 'FECHA'),
                    const SizedBox(height: 4),
                    _TappableField(
                      icon: Icons.calendar_today_outlined,
                      label: DateFormat('MMM d, yyyy · HH:mm').format(_date),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 16),

                    // ── Note ───────────────────────────────────────────
                    OrdoTextField(
                      label: 'NOTA (OPCIONAL)',
                      controller: _noteController,
                    ),
                  ],
                ),
              ),

              // ── Save button ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.gray200)),
                ),
                child: SafeArea(
                  top: false,
                  child: OrdoButton.primary(
                    label: 'Guardar movimiento',
                    onPressed: _save,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editAmount() async {
    final value = await showAmountNumpadSheet(context, _amount);
    if (value != null) {
      setState(() {
        _amount = value;
        _amountError = null;
      });
    }
  }

  Future<void> _pickCategory() async {
    final category = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CategoryPickerSheet(type: _type, selectedCategoryId: _category?.id),
    );
    if (category != null) {
      setState(() {
        _category = category;
        _categoryError = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final isToday =
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final initialTime = TimeOfDay.fromDateTime(_date);
    final latestTime = TimeOfDay.fromDateTime(now);
    final time = await showTimePicker(
      context: context,
      initialTime: isToday && _timeExceeds(initialTime, latestTime)
          ? latestTime
          : initialTime,
    );
    if (time == null || !mounted) return;
    final clamped =
        isToday && _timeExceeds(time, latestTime) ? latestTime : time;
    setState(
      () => _date = DateTime(
        date.year,
        date.month,
        date.day,
        clamped.hour,
        clamped.minute,
      ),
    );
  }

  Future<void> _save() async {
    if (!_validate()) {
      _scrollToFirstError();
      return;
    }
    final transaction = Transaction(
      id: Ulid().toString(),
      type: _type,
      amount: _amountToCents(_amount),
      currency: ref
              .read(accountsListProvider)
              .firstWhereOrNull((a) => a.id == _accountId)
              ?.currency ??
          'USD',
      accountId: _accountId!,
      toAccountId: _type == TransactionType.transfer ? _toAccountId : null,
      categoryId: _category?.id,
      description: _descriptionController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      tags: const [],
      date: _date,
      createdAt: DateTime.now(),
    );
    await ref.read(transactionsProvider.notifier).addTransaction(transaction);
    if (mounted) Navigator.of(context).pop();
  }

  bool _validate() {
    final description = _descriptionController.text.trim();
    final amount = _amountToCents(_amount);
    setState(() {
      _amountError =
          amount <= 0 ? 'Ingresa un monto mayor a \$0' : null;
      _descriptionError =
          description.isEmpty ? 'Agrega una descripción para este movimiento' : null;
      _accountError = _accountId == null ? 'Selecciona una cuenta para continuar' : null;
      _toAccountError = null;
      if (_type == TransactionType.transfer) {
        if (_toAccountId == null) {
          _toAccountError = 'Selecciona la cuenta destino';
        } else if (_toAccountId == _accountId) {
          _toAccountError = 'La cuenta origen y destino deben ser diferentes';
        }
      }
      _categoryError =
          _type == TransactionType.transfer || _category != null
              ? null
              : 'Selecciona una categoría para este movimiento';
    });
    return _amountError == null &&
        _descriptionError == null &&
        _accountError == null &&
        _toAccountError == null &&
        _categoryError == null;
  }

  void _scrollToFirstError() {
    final keys = [
      if (_amountError != null) _amountKey,
      if (_descriptionError != null) _descriptionKey,
      if (_accountError != null) _accountKey,
      if (_toAccountError != null) _toAccountKey,
      if (_categoryError != null) _categoryKey,
    ];
    if (keys.isEmpty) return;
    final ctx = keys.first.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    }
  }
}

// ── Type selector ───────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});

  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  static const _segments = [
    (type: TransactionType.expense, label: 'Gasto', color: AppColors.expense),
    (type: TransactionType.income, label: 'Ingreso', color: AppColors.income),
    (
      type: TransactionType.transfer,
      label: 'Transferencia',
      color: AppColors.transfer,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var i = 0; i < _segments.length; i++) ...[
            if (i > 0)
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.gray200,
              ),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(_segments[i].type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  color: selected == _segments[i].type
                      ? _segments[i].color.withValues(alpha: 0.08)
                      : Colors.transparent,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _segments[i].label,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 13,
                      fontWeight: selected == _segments[i].type
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: selected == _segments[i].type
                          ? _segments[i].color
                          : AppColors.gray500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared field helpers ────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.instrumentSans(
        color: AppColors.gray400,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.66,
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.error,
    super.key,
  });

  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? AppColors.expense : AppColors.gray200,
              width: hasError ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                hint,
                style: GoogleFonts.instrumentSans(
                  color: AppColors.gray400,
                  fontSize: 14,
                ),
              ),
              isExpanded: true,
              items: items,
              onChanged: onChanged,
              style: GoogleFonts.instrumentSans(
                color: AppColors.gray900,
                fontSize: 14,
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.expense,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        error!,
                        style: GoogleFonts.instrumentSans(
                          color: AppColors.expense,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.category,
    required this.onTap,
    this.error,
    super.key,
  });

  final Category? category;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final hasCategory = category != null;
    final color = hasCategory
        ? parseCategoryColor(category!.color)
        : AppColors.gray300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(
                color: hasError
                    ? AppColors.expense
                    : hasCategory
                    ? AppColors.gray300
                    : AppColors.gray200,
                width: hasError ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                if (hasCategory) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      parseCategoryIcon(category!.icon),
                      color: AppColors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
                  Icon(
                    Icons.category_outlined,
                    color: hasError ? AppColors.expense : AppColors.gray300,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    hasCategory
                        ? category!.name
                        : 'Selecciona una categoría',
                    style: GoogleFonts.instrumentSans(
                      color: hasError
                          ? AppColors.expense
                          : hasCategory
                          ? AppColors.gray900
                          : AppColors.gray400,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: hasError ? AppColors.expense : AppColors.gray400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.expense,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        error!,
                        style: GoogleFonts.instrumentSans(
                          color: AppColors.expense,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _TappableField extends StatelessWidget {
  const _TappableField({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray200),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gray400, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.instrumentSans(
                color: AppColors.gray900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int amountStringToCents(String value) => _amountToCents(value);

int _amountToCents(String value) {
  final cleaned = value.trim();
  if (cleaned.isEmpty) return 0;
  final parts = cleaned.split('.');
  final whole = int.tryParse(parts.first.isEmpty ? '0' : parts.first) ?? 0;
  final fraction = parts.length > 1
      ? parts[1].padRight(2, '0').substring(0, 2)
      : '00';
  return whole * 100 + (int.tryParse(fraction) ?? 0);
}

String centsToAmountString(int cents) {
  final whole = cents ~/ 100;
  final fraction = cents % 100;
  return '$whole.${fraction.toString().padLeft(2, '0')}';
}

DropdownMenuItem<String> _accountDropdownItem(Account account) {
  return DropdownMenuItem(
    value: account.id,
    child: Row(
      children: [
        Expanded(
          child: Text(
            account.name,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.instrumentSans(
              color: AppColors.gray900,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            account.type.label,
            style: GoogleFonts.instrumentSans(
              color: AppColors.gray500,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

bool _timeExceeds(TimeOfDay a, TimeOfDay b) =>
    a.hour > b.hour || (a.hour == b.hour && a.minute > b.minute);

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
