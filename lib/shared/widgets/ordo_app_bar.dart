import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class OrdoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OrdoAppBar({
    required this.title,
    this.leading,
    this.leadingWidth,
    this.actions,
    super.key,
  });

  final String title;
  final Widget? leading;
  final double? leadingWidth;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: true,
      leading: leading,
      leadingWidth: leadingWidth,
      actions: actions,
      title: Text(
        title,
        style: GoogleFonts.instrumentSans(
          color: AppColors.gray900,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      shape: const Border(bottom: BorderSide(color: AppColors.gray200)),
    );
  }
}
