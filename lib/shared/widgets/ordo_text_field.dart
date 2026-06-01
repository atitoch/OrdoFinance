import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'section_label.dart';

class OrdoTextField extends StatelessWidget {
  const OrdoTextField({
    required this.label,
    this.controller,
    this.initialValue,
    this.hintText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.prefixText,
    this.helperText,
    this.buildCounter,
    this.textStyle,
    this.onChanged,
    this.obscureText = false,
    this.enabled = true,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final String? prefixText;
  final String? helperText;
  final InputCounterWidgetBuilder? buildCounter;
  final TextStyle? textStyle;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppSpacing.radiusMd);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          buildCounter: buildCounter,
          onChanged: onChanged,
          obscureText: obscureText,
          enabled: enabled,
          style:
              textStyle ??
              GoogleFonts.instrumentSans(
                color: AppColors.gray900,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            prefixText: prefixText,
            helperText: helperText,
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.all(14),
            hintStyle: GoogleFonts.instrumentSans(
              color: AppColors.gray400,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            helperStyle: GoogleFonts.instrumentSans(
              color: AppColors.gray500,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            errorStyle: GoogleFonts.instrumentSans(
              color: AppColors.expense,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            border: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: const BorderSide(
                color: AppColors.gray900,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: const BorderSide(
                color: AppColors.expense,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: const BorderSide(
                color: AppColors.expense,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
