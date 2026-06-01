import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.instrumentSans(
          color: AppColors.gray400,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.88,
        ),
      ),
    );
  }
}
