import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/account.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import 'amount_text.dart';
import 'category_icon.dart';

class TransactionRow extends StatelessWidget {
  const TransactionRow({
    required this.transaction,
    this.category,
    this.account,
    this.isIncoming = false,
    super.key,
  });

  final Transaction transaction;
  final Category? category;
  final Account? account;
  /// True when this transaction is a transfer arriving at the current account.
  final bool isIncoming;

  @override
  Widget build(BuildContext context) {
    final category = this.category;
    final categoryName = category?.name ?? 'Sin categoría';
    final time = DateFormat.jm().format(transaction.date);

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: category == null
                  ? AppColors.gray200
                  : parseCategoryColor(category.color),
              shape: BoxShape.circle,
            ),
            child: Icon(
              parseCategoryIcon(category?.icon ?? ''),
              color: category == null ? AppColors.gray500 : AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.instrumentSans(
                    color: AppColors.gray900,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$categoryName • $time',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.instrumentSans(
                    color: AppColors.gray500,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AmountText(
                cents: transaction.amount,
                currency: transaction.currency,
                type: transaction.type,
                isIncoming: isIncoming,
                fontSize: 16,
              ),
              const SizedBox(height: 3),
              Text(
                account?.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.instrumentSans(
                  color: AppColors.gray400,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
