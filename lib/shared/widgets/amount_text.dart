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
    this.isIncoming = false,
    this.fontSize = 18,
    super.key,
  });

  final int cents;
  final String currency;
  final TransactionType type;
  /// For transfers shown from the destination account's perspective.
  final bool isIncoming;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final prefix = _prefix(type, isIncoming);
    final color = _color(type, isIncoming);
    return Text(
      '$prefix${formatAmount(cents, currency)}',
      style: GoogleFonts.ibmPlexMono(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  static String _prefix(TransactionType type, bool isIncoming) {
    if (type == TransactionType.transfer) return isIncoming ? '−' : '';
    return switch (type) {
      TransactionType.expense => '−',
      TransactionType.income => '+',
      _ => '',
    };
  }

  static Color _color(TransactionType type, bool isIncoming) {
    if (type == TransactionType.transfer) {
      return isIncoming ? AppColors.income : AppColors.transfer;
    }
    return switch (type) {
      TransactionType.expense => AppColors.expense,
      TransactionType.income => AppColors.income,
      _ => AppColors.transfer,
    };
  }
}
