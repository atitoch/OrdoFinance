import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ulid/ulid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/account.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/ordo_button.dart';
import '../../../shared/widgets/ordo_text_field.dart';
import '../providers/accounts_provider.dart';

class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({this.account, super.key});

  final Account? account;

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late AccountType _type;
  late String _currency;
  late String _color;
  bool _isSubmitting = false;
  String? _nameError;
  String? _balanceError;

  bool get _isEditing => widget.account != null;

  bool get _canSubmit =>
      !_isSubmitting &&
      _nameController.text.trim().isNotEmpty &&
      _balanceController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _nameController = TextEditingController(text: account?.name ?? '');
    _balanceController = TextEditingController(
      text: account == null ? '' : (account.balance ~/ 100).toString(),
    );
    _type = account?.type ?? AccountType.checking;
    _currency = account?.currency ?? 'USD';
    _color = account?.color ?? _accountColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.9,
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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    OrdoTextField(
                      label: 'NOMBRE DE CUENTA',
                      controller: _nameController,
                      maxLength: 60,
                      errorText: _nameError,
                      onChanged: (_) => setState(() => _nameError = null),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<AccountType>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: AccountType.checking,
                            label: Text('Corriente'),
                          ),
                          ButtonSegment(
                            value: AccountType.savings,
                            label: Text('Ahorro'),
                          ),
                          ButtonSegment(
                            value: AccountType.cash,
                            label: Text('Efectivo'),
                          ),
                          ButtonSegment(
                            value: AccountType.credit,
                            label: Text('Crédito'),
                          ),
                          ButtonSegment(
                            value: AccountType.investment,
                            label: Text('Inversión'),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (selection) {
                          setState(() => _type = selection.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'Moneda'),
                      items: _currencies
                          .map(
                            (currency) => DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _currency = value ?? _currency),
                    ),
                    OrdoTextField(
                      label: 'SALDO ACTUAL',
                      controller: _balanceController,
                      errorText: _balanceError,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() => _balanceError = null),
                      helperText:
                          'Ingresa tu saldo actual para comenzar a registrar desde hoy.',
                      textStyle: GoogleFonts.ibmPlexMono(
                        color: AppColors.gray900,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      children: _accountColors.map((hex) {
                        final color = parseCategoryColor(hex);
                        final selected = hex == _color;
                        return InkWell(
                          onTap: () => setState(() => _color = hex),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: selected ? color : AppColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: color),
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check,
                                    color: AppColors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: AppColors.gray200)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OrdoButton.primary(
                        label: _isEditing ? 'Guardar cambios' : 'Agregar cuenta',
                        onPressed: _canSubmit ? _submit : null,
                        isLoading: _isSubmitting,
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 12),
                        OrdoButton.outlined(
                          label: 'Archivar cuenta',
                          onPressed: _archive,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_validate() || _isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    final account = Account(
      id: widget.account?.id ?? Ulid().toString(),
      name: _nameController.text.trim(),
      type: _type,
      balance: _balanceController.text.trim().isEmpty
          ? 0
          : int.parse(_balanceController.text.trim()) * 100,
      currency: _currency,
      color: _color,
      icon: widget.account?.icon,
      isActive: widget.account?.isActive ?? true,
      createdAt: widget.account?.createdAt ?? DateTime.now(),
    );
    final notifier = ref.read(accountsProvider.notifier);
    if (_isEditing) {
      await notifier.updateAccount(account);
    } else {
      await notifier.addAccount(account);
    }
    if (mounted) Navigator.of(context).pop();
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final balance = _balanceController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? 'El nombre de cuenta es obligatorio' : null;
      _balanceError = balance.isEmpty ? 'El saldo actual es obligatorio' : null;
    });
    return _nameError == null && _balanceError == null;
  }

  Future<void> _archive() async {
    final account = widget.account;
    if (account == null) return;
    await ref.read(accountsProvider.notifier).archiveAccount(account.id);
    if (mounted) Navigator.of(context).pop();
  }
}

const _currencies = ['USD', 'EUR', 'ARS', 'CLP', 'MXN', 'BRL', 'COP'];
const _accountColors = [
  '#18181B',
  '#EF4444',
  '#F97316',
  '#22C55E',
  '#3B82F6',
  '#8B5CF6',
];
