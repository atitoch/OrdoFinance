import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ai/gemini_service.dart';
import '../../../core/backup/backup_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ordo_app_bar.dart';
import '../../../shared/widgets/section_label.dart';
import '../../accounts/widgets/account_form_sheet.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: const OrdoAppBar(title: 'Ajustes'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SectionLabel('CUENTAS'),
          _SettingsRow(
            label: 'Administrar cuentas',
            onTap: () => context.push('/accounts'),
          ),
          _SettingsRow(
            label: '+ Agregar cuenta',
            onTap: () => _showAccountSheet(context),
          ),
          const SectionLabel('CATEGORÍAS'),
          _SettingsRow(
            label: 'Administrar categorías',
            onTap: () => context.push('/categories'),
          ),
          const SectionLabel('PREFERENCIAS'),
          _SettingsRow(
            label: 'Moneda predeterminada',
            value: settings.currency,
            onTap: () async {
              final value = await _showOptionsSheet(
                context,
                'Moneda predeterminada',
                const ['USD', 'EUR', 'ARS', 'CLP', 'MXN', 'BRL', 'COP'],
                settings.currency,
              );
              if (value != null) await notifier.setCurrency(value);
            },
          ),
          _SettingsRow(
            label: 'Formato de fecha',
            value: settings.dateFormat,
            onTap: () async {
              final value = await _showOptionsSheet(
                context,
                'Formato de fecha',
                const ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
                settings.dateFormat,
              );
              if (value != null) await notifier.setDateFormat(value);
            },
          ),
          const SectionLabel('INTELIGENCIA ARTIFICIAL'),
          _ApiKeyRow(),
          const SectionLabel('DATOS'),
          _SettingsRow(
            label: 'Exportar datos',
            onTap: () => _exportData(context),
          ),
          _SettingsRow(
            label: 'Importar datos',
            onTap: () => _importData(context),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      await BackupService.exportAndShare();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar: $e')),
      );
    }
  }

  Future<void> _importData(BuildContext context) async {
    Map<String, dynamic>? data;
    try {
      data = await BackupService.pickBackupFile();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
      return;
    }
    if (data == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar datos'),
        content: const Text(
          'Esto reemplazará todas tus cuentas, categorías y transacciones '
          'actuales con las del archivo seleccionado. Esta acción no se '
          'puede deshacer. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await BackupService.import(data);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos importados correctamente.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo importar: $e')),
      );
    }
  }

  Future<void> _showAccountSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AccountFormSheet(),
    );
  }

  Future<String?> _showOptionsSheet(
    BuildContext context,
    String title,
    List<String> options,
    String current,
  ) {
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
                trailing: option == current
                    ? const Icon(Icons.check, color: AppColors.gray900, size: 18)
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
  }
}

class _ApiKeyRow extends StatefulWidget {
  @override
  State<_ApiKeyRow> createState() => _ApiKeyRowState();
}

class _ApiKeyRowState extends State<_ApiKeyRow> {
  bool _hasKey = false;

  @override
  void initState() {
    super.initState();
    GeminiService.getApiKey().then((key) {
      if (mounted) setState(() => _hasKey = key != null && key.isNotEmpty);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      label: 'API key de Gemini',
      value: _hasKey ? 'Configurada' : 'No configurada',
      onTap: () => _showApiKeyDialog(context),
    );
  }

  Future<void> _showApiKeyDialog(BuildContext context) async {
    final current = await GeminiService.getApiKey();
    if (!context.mounted) return;

    final controller = TextEditingController(text: current ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'API key de Gemini',
          style: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Obtén tu key gratis en aistudio.google.com',
              style: GoogleFonts.instrumentSans(
                fontSize: 12,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              style: GoogleFonts.instrumentSans(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'AIza...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (saved == null) return;
    await GeminiService.saveApiKey(saved);
    if (mounted) setState(() => _hasKey = saved.isNotEmpty);
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
