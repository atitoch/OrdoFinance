import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/ordo_app_bar.dart';
import '../../../shared/widgets/ordo_button.dart';
import '../../../shared/widgets/type_badge.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../categories/providers/categories_provider.dart';
import '../providers/transactions_provider.dart';
import '../widgets/transaction_edit_sheets.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({required this.transactionId, super.key});

  final String transactionId;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  bool _isEditing = false;
  Transaction? _original;
  late TransactionType _type;
  late String _amount;
  late TextEditingController _descriptionController;
  late TextEditingController _noteController;
  late TextEditingController _tagController;
  late List<String> _tags;
  late DateTime _date;
  String? _accountId;
  String? _toAccountId;
  String? _categoryId;
  String? _descriptionError;
  String? _amountError;
  String? _accountError;
  String? _toAccountError;
  String? _categoryError;

  bool get _canSave {
    final hasBaseFields =
        _descriptionController.text.trim().isNotEmpty &&
        amountStringToCents(_amount) > 0 &&
        _accountId != null;
    final hasCategory =
        _type == TransactionType.transfer || _categoryId != null;
    final hasTransferDestination =
        _type != TransactionType.transfer ||
        (_toAccountId != null && _toAccountId != _accountId);
    return hasBaseFields && hasCategory && hasTransferDestination;
  }

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _noteController = TextEditingController();
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _noteController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsListProvider);
    final transaction = transactions.firstWhereOrNull(
      (item) => item.id == widget.transactionId,
    );
    if (transaction == null) {
      return const Scaffold(
        appBar: OrdoAppBar(title: ''),
        body: Center(child: Text('Movimiento no encontrado')),
      );
    }

    if (_original?.id != transaction.id && !_isEditing) {
      _loadForm(transaction);
    }

    final accounts = ref.watch(accountsListProvider);
    final categories = ref.watch(categoriesListProvider);
    final account = accounts.firstWhereOrNull(
      (item) => item.id == transaction.accountId,
    );
    final toAccount = accounts.firstWhereOrNull(
      (item) => item.id == transaction.toAccountId,
    );
    final category = categories.firstWhereOrNull(
      (item) => item.id == transaction.categoryId,
    );

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: _isEditing ? _editAppBar(transaction) : _viewAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.ease,
                  switchOutCurve: Curves.ease,
                  child: _isEditing
                      ? _EditHero(
                          key: const ValueKey('edit'),
                          state: this,
                          accounts: accounts,
                        )
                      : _ViewHero(
                          key: const ValueKey('view'),
                          transaction: transaction,
                        ),
                ),
                const Divider(height: 1, color: AppColors.gray200),
                Container(
                  color: AppColors.white,
                  child: _isEditing
                      ? _EditRows(
                          state: this,
                          accounts: accounts,
                          categories: categories,
                          transaction: transaction,
                        )
                      : _ViewRows(
                          transaction: transaction,
                          account: account,
                          toAccount: toAccount,
                          category: category,
                          onEditNote: _enterEditMode,
                          onEditTags: _enterEditMode,
                          onCopyId: _copyId,
                        ),
                ),
              ],
            ),
          ),
          if (!_isEditing)
            _DeleteBar(
              onDelete: () => _showDeleteConfirmation(transaction, category),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _viewAppBar() {
    return OrdoAppBar(
      title: '',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.gray900),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.gray900),
          onPressed: _enterEditMode,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.gray900),
          onPressed: () {},
        ),
      ],
    );
  }

  PreferredSizeWidget _editAppBar(Transaction transaction) {
    return OrdoAppBar(
      title: '',
      leading: TextButton(
        onPressed: _cancelEdit,
        child: Text(
          'Cancelar',
          style: GoogleFonts.instrumentSans(
            color: AppColors.gray500,
            fontSize: 14,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: OrdoButton.primary(
            label: 'Guardar',
            onPressed: _canSave ? () => _save(transaction) : null,
            width: 76,
            height: 36,
          ),
        ),
      ],
    );
  }

  void _loadForm(Transaction transaction) {
    _original = transaction;
    _type = transaction.type;
    _amount = centsToAmountString(transaction.amount);
    _descriptionController.text = transaction.description;
    _noteController.text = transaction.note ?? '';
    _tags = [...transaction.tags];
    _date = transaction.date;
    _accountId = transaction.accountId;
    _toAccountId = transaction.toAccountId;
    _categoryId = transaction.categoryId;
    _descriptionError = null;
    _amountError = null;
    _accountError = null;
    _toAccountError = null;
    _categoryError = null;
  }

  void _enterEditMode() {
    final transaction = ref
        .read(transactionsListProvider)
        .firstWhereOrNull((item) => item.id == widget.transactionId);
    if (transaction != null) _loadForm(transaction);
    setState(() => _isEditing = true);
  }

  bool get _isDirty {
    final original = _original;
    if (original == null) return false;
    return _type != original.type ||
        amountStringToCents(_amount) != original.amount ||
        _descriptionController.text.trim() != original.description ||
        _noteController.text.trim() != (original.note ?? '') ||
        _date != original.date ||
        _accountId != original.accountId ||
        _toAccountId != original.toAccountId ||
        _categoryId != original.categoryId ||
        _tags.join('\u0000') != original.tags.join('\u0000');
  }

  Future<void> _cancelEdit() async {
    if (!_isDirty) {
      setState(() => _isEditing = false);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Seguir editando',
              style: TextStyle(color: AppColors.gray900),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Descartar',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
    if (discard ?? false) setState(() => _isEditing = false);
  }

  Future<void> _save(Transaction transaction) async {
    if (!_validate()) {
      return;
    }
    final updated = Transaction(
      id: transaction.id,
      type: _type,
      amount: amountStringToCents(_amount),
      currency: transaction.currency,
      accountId: _accountId ?? transaction.accountId,
      toAccountId: _type == TransactionType.transfer ? _toAccountId : null,
      categoryId: _categoryId,
      description: _descriptionController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      tags: _tags,
      date: _date,
      createdAt: transaction.createdAt,
      deletedAt: transaction.deletedAt,
    );
    await ref.read(transactionsProvider.notifier).updateTransaction(updated);
    setState(() {
      _isEditing = false;
      _original = updated;
    });
  }

  Future<void> _copyId(String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ID copiado', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.gray900,
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    Transaction transaction,
    Category? category,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeleteConfirmationSheet(
        transaction: transaction,
        category: category,
        onConfirm: () => _delete(transaction),
      ),
    );
  }

  Future<void> _delete(Transaction transaction) async {
    Navigator.of(context).pop();
    final deleted = await ref
        .read(transactionsProvider.notifier)
        .deleteTransaction(transaction.id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Movimiento eliminado'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: deleted == null
              ? () {}
              : () => ref
                    .read(transactionsProvider.notifier)
                    .restoreTransaction(deleted),
        ),
      ),
    );
  }

  Future<void> editAmount() async {
    final value = await showAmountNumpadSheet(context, _amount);
    if (value != null) {
      setState(() {
        _amount = value;
        _amountError = null;
      });
    }
  }

  Future<void> pickCategory() async {
    final category = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CategoryPickerSheet(type: _type, selectedCategoryId: _categoryId),
    );
    if (category != null) {
      setState(() {
        _categoryId = category.id;
        _categoryError = null;
      });
    }
  }

  Future<void> pickDate() async {
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
    if (time != null) {
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
  }

  void setTransactionType(TransactionType type) => setState(() {
    _type = type;
    _categoryError = null;
    _toAccountError = null;
  });

  void setAccountId(String? accountId) => setState(() {
    _accountId = accountId;
    _accountError = null;
    _toAccountError = null;
  });

  void setToAccountId(String? accountId) => setState(() {
    _toAccountId = accountId;
    _toAccountError = null;
  });

  bool _validate() {
    final description = _descriptionController.text.trim();
    final amount = amountStringToCents(_amount);
    setState(() {
      _descriptionError = description.isEmpty
          ? 'Description is required'
          : null;
      _amountError = amount <= 0 ? 'Amount must be greater than zero' : null;
      _accountError = _accountId == null ? 'Account is required' : null;
      _toAccountError = null;
      if (_type == TransactionType.transfer) {
        if (_toAccountId == null) {
          _toAccountError = 'Destination account is required';
        } else if (_toAccountId == _accountId) {
          _toAccountError = 'Choose a different destination account';
        }
      }
      _categoryError = _type == TransactionType.transfer || _categoryId != null
          ? null
          : 'Category is required';
    });
    return _descriptionError == null &&
        _amountError == null &&
        _accountError == null &&
        _toAccountError == null &&
        _categoryError == null;
  }

  void clearDescriptionError() => setState(() => _descriptionError = null);

  void addTag(String raw) {
    final tag = raw.replaceAll(',', '').trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void removeTag(String tag) => setState(() => _tags.remove(tag));
}

class _ViewHero extends StatelessWidget {
  const _ViewHero({required this.transaction, super.key});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TypeBadge(type: transaction.type),
          const SizedBox(height: 20),
          Center(
            child: AmountText(
              cents: transaction.amount,
              currency: transaction.currency,
              type: transaction.type,
              fontSize: 40,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              transaction.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.instrumentSans(
                color: AppColors.gray900,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              DateFormat('EEEE, MMMM d, y · HH:mm').format(transaction.date),
              style: GoogleFonts.ibmPlexMono(
                color: AppColors.gray500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditHero extends StatelessWidget {
  const _EditHero({required this.state, required this.accounts, super.key});

  final _TransactionDetailScreenState state;
  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    final currency =
        accounts
            .firstWhereOrNull((item) => item.id == state._accountId)
            ?.currency ??
        'USD';
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: SegmentedButton<TransactionType>(
              showSelectedIcon: false,
              selected: {state._type},
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text('Transfer'),
                ),
              ],
              onSelectionChanged: (selection) =>
                  state.setTransactionType(selection.first),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: state.editAmount,
            child: Column(
              children: [
                Text(
                  formatAmount(amountStringToCents(state._amount), currency),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexMono(
                    color: state._amountError == null
                        ? AppColors.gray900
                        : AppColors.expense,
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (state._amountError != null)
                  Text(
                    state._amountError!,
                    style: GoogleFonts.instrumentSans(
                      color: AppColors.expense,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: state._descriptionController,
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSans(
              color: AppColors.gray900,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            onChanged: (_) => state.clearDescriptionError(),
            decoration: InputDecoration(
              errorText: state._descriptionError,
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.gray900, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewRows extends StatelessWidget {
  const _ViewRows({
    required this.transaction,
    required this.account,
    required this.toAccount,
    required this.category,
    required this.onEditNote,
    required this.onEditTags,
    required this.onCopyId,
  });

  final Transaction transaction;
  final Account? account;
  final Account? toAccount;
  final Category? category;
  final VoidCallback onEditNote;
  final VoidCallback onEditTags;
  final ValueChanged<String> onCopyId;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _DetailRow(label: 'CUENTA', value: account?.name ?? '-'),
      if (transaction.type == TransactionType.transfer) ...[
        _DetailRow(label: 'ORIGEN', value: account?.name ?? '-'),
        _DetailRow(label: 'DESTINO', value: toAccount?.name ?? '-'),
      ],
      _DetailRow(label: 'CATEGORÍA', value: category?.name ?? '-'),
      _DetailRow(
        label: 'NOTA',
        valueWidget: transaction.note == null || transaction.note!.isEmpty
            ? _EmptyEditValue(text: 'Agregar nota', onTap: onEditNote)
            : Text(
                transaction.note!,
                textAlign: TextAlign.right,
                style: _valueStyle,
              ),
      ),
      _DetailRow(
        label: 'ETIQUETAS',
        valueWidget: transaction.tags.isEmpty
            ? _EmptyEditValue(text: 'Agregar etiquetas', onTap: onEditTags)
            : Text(
                transaction.tags.join(', '),
                textAlign: TextAlign.right,
                style: _valueStyle,
              ),
      ),
      _DetailRow(
        label: 'FECHA',
        value: DateFormat('MMM d, y · HH:mm').format(transaction.date),
      ),
      _DetailRow(
        label: 'ID',
        valueWidget: InkWell(
          onTap: () => onCopyId(transaction.id),
          child: Text(
            '${transaction.id.substring(0, transaction.id.length < 12 ? transaction.id.length : 12)}...',
            textAlign: TextAlign.right,
            style: _valueStyle,
          ),
        ),
      ),
    ];
    return Column(children: rows);
  }
}

class _EditRows extends StatelessWidget {
  const _EditRows({
    required this.state,
    required this.accounts,
    required this.categories,
    required this.transaction,
  });

  final _TransactionDetailScreenState state;
  final List<Account> accounts;
  final List<Category> categories;
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final category = categories.firstWhereOrNull(
      (item) => item.id == state._categoryId,
    );
    return Column(
      children: [
        _DetailRow(
          label: 'CUENTA',
          valueWidget: DropdownButtonFormField<String>(
            initialValue: state._accountId,
            isExpanded: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              errorText: state._accountError,
            ),
            items: accounts
                .map(
                  (account) => DropdownMenuItem(
                    value: account.id,
                    child: Text(account.name),
                  ),
                )
                .toList(),
            onChanged: state.setAccountId,
          ),
        ),
        if (state._type == TransactionType.transfer)
          _DetailRow(
            label: 'DESTINO',
            valueWidget: DropdownButtonFormField<String>(
              initialValue: state._toAccountId,
              isExpanded: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                errorText: state._toAccountError,
              ),
              items: accounts
                  .map(
                    (account) => DropdownMenuItem(
                      value: account.id,
                      child: Text(account.name),
                    ),
                  )
                  .toList(),
              onChanged: state.setToAccountId,
            ),
          ),
        _DetailRow(
          label: 'CATEGORÍA',
          valueWidget: InkWell(
            onTap: state.pickCategory,
            child: Text(
              state._categoryError ?? category?.name ?? 'Selecciona una categoría',
              textAlign: TextAlign.right,
              style: state._categoryError == null
                  ? _valueStyle
                  : _valueStyle.copyWith(color: AppColors.expense),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextFormField(
            controller: state._noteController,
            maxLines: 4,
            maxLength: 500,
            style: GoogleFonts.instrumentSans(
              color: AppColors.gray900,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              labelText: 'NOTA',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: _TagsInput(state: state),
        ),
        _DetailRow(
          label: 'FECHA',
          valueWidget: InkWell(
            onTap: state.pickDate,
            child: Text(
              DateFormat('MMM d, y · HH:mm').format(state._date),
              textAlign: TextAlign.right,
              style: _valueStyle,
            ),
          ),
        ),
        _DetailRow(label: 'ID', value: transaction.id),
        _DetailRow(
          label: 'CREADO',
          value: DateFormat('MMM d, y · HH:mm').format(transaction.createdAt),
        ),
      ],
    );
  }
}

class _TagsInput extends StatelessWidget {
  const _TagsInput({required this.state});

  final _TransactionDetailScreenState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: state._tagController,
          onSubmitted: state.addTag,
          inputFormatters: [_CommaTagFormatter(onComma: state.addTag)],
          decoration: const InputDecoration(
            labelText: 'ETIQUETAS',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: state._tags.map((tag) {
            return Chip(
              label: Text(tag),
              onDeleted: () => state.removeTag(tag),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CommaTagFormatter extends TextInputFormatter {
  _CommaTagFormatter({required this.onComma});

  final ValueChanged<String> onComma;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.endsWith(',')) {
      onComma(newValue.text);
      return const TextEditingValue();
    }
    return newValue;
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, this.value, this.valueWidget});

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label.toUpperCase(), style: _labelStyle),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  valueWidget ??
                  Text(
                    value ?? '-',
                    textAlign: TextAlign.right,
                    style: _valueStyle,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEditValue extends StatelessWidget {
  const _EmptyEditValue({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: GoogleFonts.instrumentSans(
          color: AppColors.gray400,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _DeleteBar extends StatelessWidget {
  const _DeleteBar({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      child: OrdoButton.destructiveOutlined(
        label: 'Eliminar movimiento',
        onPressed: onDelete,
      ),
    );
  }
}

class _DeleteConfirmationSheet extends StatelessWidget {
  const _DeleteConfirmationSheet({
    required this.transaction,
    required this.category,
    required this.onConfirm,
  });

  final Transaction transaction;
  final Category? category;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final color = category == null
        ? AppColors.gray200
        : parseCategoryColor(category!.color);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(
                parseCategoryIcon(category?.icon ?? ''),
                color: category == null ? AppColors.gray500 : AppColors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              transaction.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSans(
                color: AppColors.gray900,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta acción no se puede deshacer.',
              style: GoogleFonts.instrumentSans(
                color: AppColors.gray500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            OrdoButton.destructive(
              label: 'Eliminar movimiento',
              onPressed: onConfirm,
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: GoogleFonts.instrumentSans(
                  color: AppColors.gray500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _labelStyle = GoogleFonts.instrumentSans(
  color: AppColors.gray400,
  fontSize: 11,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.66,
);
final _valueStyle = GoogleFonts.instrumentSans(
  color: AppColors.gray900,
  fontSize: 14,
);

bool _timeExceeds(TimeOfDay a, TimeOfDay b) =>
    a.hour > b.hour || (a.hour == b.hour && a.minute > b.minute);

extension _IterableExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
