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
import '../../settings/providers/settings_provider.dart';
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
  int? _cutDay;
  bool _isSubmitting = false;
  String? _nameError;
  String? _balanceError;

  bool get _isEditing => widget.account != null;

  bool get _canSubmit => !_isSubmitting;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _nameController = TextEditingController(text: account?.name ?? '');
    _balanceController = TextEditingController(
      text: account == null ? '' : (account.balance ~/ 100).toString(),
    );
    _type = account?.type ?? AccountType.checking;
    _currency = account?.currency ?? ref.read(settingsProvider).currency;
    _color = account?.color ?? _accountColors.first;
    _cutDay = account?.cutDay;
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing ? 'Editar cuenta' : 'Nueva cuenta',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.gray500,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.gray100),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    OrdoTextField(
                      label: 'NOMBRE DE CUENTA',
                      controller: _nameController,
                      maxLength: 60,
                      errorText: _nameError,
                      onChanged: (_) => setState(() => _nameError = null),
                    ),
                    const SizedBox(height: 16),
                    _AccountTypeSelector(
                      selected: _type,
                      onChanged: (type) => setState(() => _type = type),
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
                      label: _type == AccountType.credit
                          ? 'DEUDA ACTUAL'
                          : 'SALDO ACTUAL',
                      controller: _balanceController,
                      errorText: _balanceError,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() => _balanceError = null),
                      helperText: _type == AccountType.credit
                          ? 'Ingresa cuánto debes actualmente en esta tarjeta.'
                          : 'Ingresa tu saldo actual para comenzar a registrar desde hoy.',
                      textStyle: GoogleFonts.ibmPlexMono(
                        color: AppColors.gray900,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (_type == AccountType.credit) ...[
                      const SizedBox(height: 16),
                      _CutDaySelector(
                        selected: _cutDay,
                        onChanged: (day) => setState(() => _cutDay = day),
                      ),
                    ],
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
      cutDay: _type == AccountType.credit ? _cutDay : null,
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

class _CutDaySelector extends StatelessWidget {
  const _CutDaySelector({required this.selected, required this.onChanged});

  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DÍA DE CORTE',
          style: GoogleFonts.instrumentSans(
            color: AppColors.gray400,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.66,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 28,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final day = index + 1;
              final isSelected = selected == day;
              return GestureDetector(
                onTap: () => onChanged(isSelected ? null : day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gray900 : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.gray900 : AppColors.gray200,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.white : AppColors.gray600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Recibirás avisos 15, 7 y 1 día antes del corte.',
              style: GoogleFonts.instrumentSans(
                color: AppColors.gray400,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}

class _AccountTypeSelector extends StatelessWidget {
  const _AccountTypeSelector({required this.selected, required this.onChanged});

  final AccountType selected;
  final ValueChanged<AccountType> onChanged;

  static const _types = [
    (type: AccountType.checking, label: 'Corriente', icon: Icons.account_balance_outlined),
    (type: AccountType.savings, label: 'Ahorro', icon: Icons.savings_outlined),
    (type: AccountType.cash, label: 'Efectivo', icon: Icons.payments_outlined),
    (type: AccountType.credit, label: 'Crédito', icon: Icons.credit_card),
    (type: AccountType.investment, label: 'Inversión', icon: Icons.show_chart),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _types.map((item) {
        final isSelected = selected == item.type;
        return GestureDetector(
          onTap: () => onChanged(item.type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.gray900 : AppColors.white,
              border: Border.all(
                color: isSelected ? AppColors.gray900 : AppColors.gray200,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 16,
                  color: isSelected ? AppColors.white : AppColors.gray500,
                ),
                const SizedBox(width: 6),
                Text(
                  item.label,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.white : AppColors.gray700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
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
