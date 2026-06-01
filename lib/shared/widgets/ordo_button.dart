import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class OrdoButton extends StatelessWidget {
  const OrdoButton._({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 48,
    super.key,
  });

  factory OrdoButton.primary({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    double width = double.infinity,
    double height = 48,
    Key? key,
  }) {
    return OrdoButton._(
      key: key,
      label: label,
      onPressed: onPressed,
      backgroundColor: AppColors.gray900,
      foregroundColor: AppColors.white,
      isLoading: isLoading,
      width: width,
      height: height,
    );
  }

  factory OrdoButton.destructive({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    double width = double.infinity,
    double height = 48,
    Key? key,
  }) {
    return OrdoButton._(
      key: key,
      label: label,
      onPressed: onPressed,
      backgroundColor: AppColors.expense,
      foregroundColor: AppColors.white,
      isLoading: isLoading,
      width: width,
      height: height,
    );
  }

  factory OrdoButton.outlined({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    double width = double.infinity,
    double height = 48,
    Key? key,
  }) {
    return OrdoButton._(
      key: key,
      label: label,
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.gray900,
      borderColor: AppColors.gray900,
      isLoading: isLoading,
      width: width,
      height: height,
    );
  }

  factory OrdoButton.destructiveOutlined({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    double width = double.infinity,
    double height = 48,
    Key? key,
  }) {
    return OrdoButton._(
      key: key,
      label: label,
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.expense,
      borderColor: AppColors.expense,
      isLoading: isLoading,
      width: width,
      height: height,
    );
  }

  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final bool isLoading;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final borderColor = this.borderColor;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStatePropertyAll(
            foregroundColor.withValues(alpha: 0.08),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => backgroundColor,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => foregroundColor,
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              side: borderColor == null
                  ? BorderSide.none
                  : BorderSide(color: borderColor, width: 1.5),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.instrumentSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(label),
      ),
    );
  }
}
