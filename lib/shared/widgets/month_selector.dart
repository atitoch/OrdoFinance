import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onTapLabel,
    this.canGoNext = true,
    super.key,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTapLabel;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left, color: AppColors.gray900),
          ),
          InkWell(
            onTap: onTapLabel,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                DateFormat.yMMMM().format(month),
                style: GoogleFonts.instrumentSans(
                  color: AppColors.gray900,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: canGoNext ? onNext : null,
            icon: Icon(
              Icons.chevron_right,
              color: canGoNext ? AppColors.gray900 : AppColors.gray300,
            ),
          ),
        ],
      ),
    );
  }
}
