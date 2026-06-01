import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class ResourceStatusBanner extends StatelessWidget {
  const ResourceStatusBanner({
    required this.isLoading,
    required this.isSyncing,
    required this.error,
    required this.onRetry,
    super.key,
  });

  final bool isLoading;
  final bool isSyncing;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LinearProgressIndicator(
        minHeight: 2,
        color: AppColors.gray900,
      );
    }

    if (error != null) {
      return Container(
        width: double.infinity,
        color: AppColors.expenseBg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Could not sync latest data.',
                style: GoogleFonts.instrumentSans(
                  color: AppColors.expense,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (isSyncing) {
      return Container(
        width: double.infinity,
        color: AppColors.warningBg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Syncing local changes...',
          style: GoogleFonts.instrumentSans(
            color: AppColors.warning,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
