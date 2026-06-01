import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/transaction.dart';

class TypeBadge extends StatelessWidget {
  const TypeBadge({required this.type, super.key});

  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _backgroundColor(type),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          type.name.toUpperCase(),
          style: GoogleFonts.instrumentSans(
            color: _textColor(type),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.66,
          ),
        ),
      ),
    );
  }

  static Color _backgroundColor(TransactionType type) {
    return switch (type) {
      TransactionType.expense => AppColors.expenseBg,
      TransactionType.income => AppColors.incomeBg,
      TransactionType.transfer => AppColors.transferBg,
    };
  }

  static Color _textColor(TransactionType type) {
    return switch (type) {
      TransactionType.expense => AppColors.expense,
      TransactionType.income => AppColors.income,
      TransactionType.transfer => AppColors.transfer,
    };
  }
}
