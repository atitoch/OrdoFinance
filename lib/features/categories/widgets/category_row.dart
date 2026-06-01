import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/category.dart';
import '../../../shared/widgets/category_icon.dart';

class CategoryRow extends StatelessWidget {
  const CategoryRow({
    required this.category,
    this.indent = 0,
    this.currency = 'USD',
    super.key,
  });

  final Category category;
  final double indent;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final color = parseCategoryColor(category.color);

    return Container(
      height: 56,
      padding: EdgeInsets.only(left: 16 + indent, right: 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Row(
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
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.instrumentSans(
                      color: AppColors.gray900,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CategoryTypeBadge(type: category.type),
              ],
            ),
          ),
          if (category.budgetLimit != null) ...[
            Text(
              formatAmount(category.budgetLimit!, currency),
              style: GoogleFonts.ibmPlexMono(
                color: AppColors.gray400,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(
            category.isSystem ? Icons.lock_outline : Icons.drag_handle,
            color: AppColors.gray400,
            size: 16,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.gray400, size: 18),
        ],
      ),
    );
  }
}

class _CategoryTypeBadge extends StatelessWidget {
  const _CategoryTypeBadge({required this.type});

  final CategoryType type;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          type.name.toUpperCase(),
          style: GoogleFonts.instrumentSans(
            color: _textColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  Color get _backgroundColor {
    return switch (type) {
      CategoryType.expense => AppColors.expenseBg,
      CategoryType.income => AppColors.incomeBg,
      CategoryType.both => AppColors.transferBg,
    };
  }

  Color get _textColor {
    return switch (type) {
      CategoryType.expense => AppColors.expense,
      CategoryType.income => AppColors.income,
      CategoryType.both => AppColors.transfer,
    };
  }
}
