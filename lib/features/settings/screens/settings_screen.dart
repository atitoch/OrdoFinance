import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ordo_app_bar.dart';
import '../../../shared/widgets/section_label.dart';
import '../../accounts/widgets/account_form_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currency = 'USD';
  String _dateFormat = 'MM/DD/YYYY';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: const OrdoAppBar(title: 'Ajustes'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SectionLabel('CUENTAS'),
          _SettingsRow(
            label: 'Administrar cuentas',
            onTap: () => context.go('/accounts'),
          ),
          _SettingsRow(label: '+ Agregar cuenta', onTap: _showAccountSheet),
          const SectionLabel('CATEGORÍAS'),
          _SettingsRow(
            label: 'Administrar categorías',
            onTap: () => context.go('/categories'),
          ),
          const SectionLabel('PREFERENCIAS'),
          _SettingsRow(
            label: 'Moneda predeterminada',
            value: _currency,
            onTap: _showCurrencySheet,
          ),
          _SettingsRow(
            label: 'Formato de fecha',
            value: _dateFormat,
            onTap: _showDateFormatSheet,
          ),
          const SectionLabel('DATOS'),
          _SettingsRow(
            label: 'Exportar a CSV',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Próximamente')));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAccountSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AccountFormSheet(),
    );
  }

  Future<void> _showCurrencySheet() async {
    final value = await _showOptionsSheet('Moneda predeterminada', const [
      'USD',
      'EUR',
      'ARS',
      'CLP',
      'MXN',
      'BRL',
      'COP',
    ]);
    if (value != null) setState(() => _currency = value);
  }

  Future<void> _showDateFormatSheet() async {
    final value = await _showOptionsSheet('Formato de fecha', const [
      'MM/DD/YYYY',
      'DD/MM/YYYY',
      'YYYY-MM-DD',
    ]);
    if (value != null) setState(() => _dateFormat = value);
  }

  Future<String?> _showOptionsSheet(String title, List<String> options) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            for (final option in options)
              ListTile(
                title: Text(option),
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label, this.value, this.onTap});

  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(bottom: BorderSide(color: AppColors.gray200)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.instrumentSans(
                  color: AppColors.gray900,
                  fontSize: 14,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: GoogleFonts.instrumentSans(
                  color: AppColors.gray500,
                  fontSize: 14,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.gray400, size: 18),
          ],
        ),
      ),
    );
  }
}
