import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/category.dart';
import 'category_icon.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({required this.category, super.key});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: parseCategoryColor(category.color),
            shape: BoxShape.circle,
          ),
          child: Icon(
            parseCategoryIcon(category.icon),
            color: AppColors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          category.name,
          style: GoogleFonts.instrumentSans(
            color: AppColors.gray600,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
