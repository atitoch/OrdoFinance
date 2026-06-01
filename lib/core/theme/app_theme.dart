import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final textTheme = TextTheme(
      displayLarge: GoogleFonts.instrumentSans(
        fontSize: 40,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: GoogleFonts.instrumentSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.instrumentSans(
        fontSize: 19,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.instrumentSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.instrumentSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.instrumentSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.72,
      ),
      labelSmall: GoogleFonts.instrumentSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.88,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.gray50,
      fontFamily: GoogleFonts.instrumentSans().fontFamily,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.gray900,
        surface: AppColors.gray50,
      ),
    );
  }
}
