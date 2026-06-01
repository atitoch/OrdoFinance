import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ulid/ulid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/category.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/ordo_button.dart';
import '../../../shared/widgets/ordo_text_field.dart';
import '../providers/categories_provider.dart';

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({this.category, super.key});

  final Category? category;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _budgetController;
  late String _icon;
  late String _color;
  late CategoryType _type;
  bool _isSubmitting = false;
  String? _nameError;
  String? _budgetError;

  bool get _isEditing => widget.category != null;

  bool get _canSubmit =>
      !_isSubmitting &&
      _nameController.text.trim().isNotEmpty &&
      (_budgetController.text.trim().isEmpty ||
          int.tryParse(_budgetController.text.trim()) != null);

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _budgetController = TextEditingController(
      text: category?.budgetLimit == null
          ? ''
          : (category!.budgetLimit! ~/ 100).toString(),
    );
    _icon = category?.icon ?? _iconOptions.first.name;
    _color = category?.color ?? _colorOptions.first;
    _type = category?.type ?? CategoryType.expense;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  _isEditing ? 'Editar categoría' : 'Nueva categoría',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.instrumentSans(
                    color: AppColors.gray900,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _IconSelector(
                      selectedIcon: _icon,
                      selectedColor: _color,
                      onSelected: (icon) => setState(() => _icon = icon),
                    ),
                    const SizedBox(height: 20),
                    _ColorSelector(
                      selectedColor: _color,
                      onSelected: (color) => setState(() => _color = color),
                    ),
                    const SizedBox(height: 4),
                    OrdoTextField(
                      label: 'NOMBRE',
                      controller: _nameController,
                      errorText: _nameError,
                      onChanged: (_) => setState(() => _nameError = null),
                      maxLength: 40,
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) {
                            return Text(
                              '$currentLength/$maxLength',
                              style: GoogleFonts.instrumentSans(
                                color: AppColors.gray400,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            );
                          },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: SegmentedButton<CategoryType>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: CategoryType.expense,
                            label: Text('Gasto'),
                          ),
                          ButtonSegment(
                            value: CategoryType.income,
                            label: Text('Ingreso'),
                          ),
                          ButtonSegment(
                            value: CategoryType.both,
                            label: Text('Ambos'),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (selection) {
                          setState(() => _type = selection.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    OrdoTextField(
                      label: 'LÍMITE MENSUAL (OPCIONAL)',
                      controller: _budgetController,
                      errorText: _budgetError,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() => _budgetError = null),
                      prefixText: r'$',
                      helperText: 'Déjalo vacío para sin límite',
                      textStyle: GoogleFonts.ibmPlexMono(
                        color: AppColors.gray900,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              _SheetActions(
                isEditing: _isEditing,
                isSystem: widget.category?.isSystem ?? false,
                isSubmitting: _isSubmitting,
                onSave: _canSubmit ? _submit : null,
                onDelete: _delete,
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

    final name = _nameController.text.trim();
    setState(() => _isSubmitting = true);
    final budgetLimit = _budgetController.text.trim().isEmpty
        ? null
        : int.parse(_budgetController.text.trim()) * 100;
    final category = Category(
      id: widget.category?.id ?? Ulid().toString(),
      name: name,
      type: _type,
      color: _color,
      icon: _icon,
      parentId: widget.category?.parentId,
      budgetLimit: budgetLimit,
      isSystem: widget.category?.isSystem ?? false,
    );

    if (_isEditing) {
      await ref.read(categoriesProvider.notifier).updateCategory(category);
    } else {
      await ref.read(categoriesProvider.notifier).addCategory(category);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  bool _validate() {
    final name = _nameController.text.trim();
    final budget = _budgetController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? 'El nombre de categoría es obligatorio' : null;
      _budgetError = budget.isNotEmpty && int.tryParse(budget) == null
          ? 'Ingresa un límite válido'
          : null;
    });
    return _nameError == null && _budgetError == null;
  }

  Future<void> _delete() async {
    final category = widget.category;
    if (category == null || category.isSystem || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    await ref.read(categoriesProvider.notifier).deleteCategory(category.id);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _IconSelector extends StatelessWidget {
  const _IconSelector({
    required this.selectedIcon,
    required this.selectedColor,
    required this.onSelected,
  });

  final String selectedIcon;
  final String selectedColor;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final color = parseCategoryColor(selectedColor);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _iconOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final option = _iconOptions[index];
          final isSelected = option.name == selectedIcon;

          return InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => onSelected(option.name),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : AppColors.gray100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : AppColors.gray200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                option.icon,
                color: isSelected ? color : AppColors.gray500,
                size: 22,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ColorSelector extends StatelessWidget {
  const _ColorSelector({required this.selectedColor, required this.onSelected});

  final String selectedColor;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _colorOptions.map((hex) {
        final color = parseCategoryColor(hex);
        final isSelected = hex == selectedColor;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onSelected(hex),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? color : AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: AppColors.white, size: 14)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _SheetActions extends StatelessWidget {
  const _SheetActions({
    required this.isEditing,
    required this.isSystem,
    required this.isSubmitting,
    required this.onSave,
    required this.onDelete,
  });

  final bool isEditing;
  final bool isSystem;
  final bool isSubmitting;
  final VoidCallback? onSave;
  final VoidCallback onDelete;

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
        child: isEditing
            ? Row(
                children: [
                  Expanded(
                    child: OrdoButton.primary(
                      label: 'Guardar cambios',
                      onPressed: onSave,
                      isLoading: isSubmitting,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OrdoButton.destructive(
                      label: 'Eliminar',
                      onPressed: isSystem ? null : onDelete,
                    ),
                  ),
                ],
              )
            : OrdoButton.primary(
                label: 'Crear categoría',
                onPressed: onSave,
                isLoading: isSubmitting,
              ),
      ),
    );
  }
}

class _IconOption {
  const _IconOption(this.name, this.icon);

  final String name;
  final IconData icon;
}

const _iconOptions = [
  _IconOption('wallet', Icons.account_balance_wallet_outlined),
  _IconOption('shopping_cart', Icons.shopping_cart_outlined),
  _IconOption('home', Icons.home_outlined),
  _IconOption('directions_car', Icons.directions_car_outlined),
  _IconOption('local_cafe', Icons.local_cafe_outlined),
  _IconOption('restaurant', Icons.restaurant_outlined),
  _IconOption('favorite', Icons.favorite_outline),
  _IconOption('phone', Icons.phone_outlined),
  _IconOption('flight', Icons.flight_outlined),
  _IconOption('work', Icons.work_outline),
  _IconOption('school', Icons.school_outlined),
  _IconOption('card_giftcard', Icons.card_giftcard_outlined),
  _IconOption('bolt', Icons.bolt_outlined),
  _IconOption('autorenew', Icons.autorenew),
  _IconOption('trending_up', Icons.trending_up_outlined),
];

const _colorOptions = [
  '#18181B',
  '#EF4444',
  '#F97316',
  '#EAB308',
  '#22C55E',
  '#14B8A6',
  '#3B82F6',
  '#8B5CF6',
  '#EC4899',
  '#6B7280',
  '#92400E',
  '#065F46',
];
