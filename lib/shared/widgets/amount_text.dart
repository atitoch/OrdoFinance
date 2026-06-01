import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/transaction.dart';

class AmountText extends StatelessWidget {
  const AmountText({
    required this.cents,
    required this.currency,
    required this.type,
    this.fontSize = 18,
    super.key,
  });

  final int cents;
  final String currency;
  final TransactionType type;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_prefix(type)}${formatAmount(cents, currency)}',
      style: GoogleFonts.ibmPlexMono(
        color: _color(type),
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  static String _prefix(TransactionType type) {
    return switch (type) {
      TransactionType.expense => '−',
      TransactionType.income => '+',
      TransactionType.transfer => '',
    };
  }

  static Color _color(TransactionType type) {
    return switch (type) {
      TransactionType.expense => AppColors.expense,
      TransactionType.income => AppColors.income,
      TransactionType.transfer => AppColors.transfer,
    };
  }
}
