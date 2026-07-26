import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/account.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';

/// Exportación e importación del respaldo local (cuentas, categorías y
/// movimientos) en un único archivo JSON.
abstract final class BackupService {
  static const _formatVersion = 1;

  static Box<Account> get _accounts => Hive.box<Account>('accounts');
  static Box<Category> get _categories => Hive.box<Category>('categories');
  static Box<Transaction> get _transactions =>
      Hive.box<Transaction>('transactions');

  /// Serializa el contenido actual de Hive al formato de respaldo.
  static Map<String, dynamic> buildBackup() {
    return {
      'formatVersion': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': _accounts.values.map((item) => item.toJson()).toList(),
      'categories': _categories.values.map((item) => item.toJson()).toList(),
      'transactions': _transactions.values.map((item) => item.toJson()).toList(),
    };
  }

  /// Escribe el respaldo en un archivo temporal y abre la hoja de compartir.
  static Future<void> exportAndShare() async {
    final json = const JsonEncoder.withIndent('  ').convert(buildBackup());
    final stamp = DateFormat('yyyy-MM-dd-HHmm').format(DateTime.now());
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/ordo-finance-$stamp.json');
    await file.writeAsString(json);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Respaldo de Ordo Finance',
    );
  }

  /// Abre el selector de archivos y devuelve el respaldo ya validado.
  /// Devuelve `null` si la persona cancela la selección.
  static Future<Map<String, dynamic>?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.first;
    final String raw;
    if (picked.bytes != null) {
      raw = utf8.decode(picked.bytes!);
    } else if (picked.path != null) {
      raw = await File(picked.path!).readAsString();
    } else {
      throw const FormatException('No se pudo leer el archivo seleccionado.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const FormatException('El archivo no es un JSON válido.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El archivo no tiene el formato esperado.');
    }
    if (decoded['accounts'] is! List ||
        decoded['categories'] is! List ||
        decoded['transactions'] is! List) {
      throw const FormatException(
        'El archivo no parece un respaldo de Ordo Finance.',
      );
    }
    return decoded;
  }

  /// Reemplaza por completo el contenido local con el del respaldo.
  ///
  /// Se valida todo el archivo antes de tocar Hive, para no dejar los datos
  /// a medias si el respaldo está corrupto.
  static Future<void> import(Map<String, dynamic> data) async {
    final accounts = _parseList(data['accounts'], Account.fromJson, 'cuentas');
    final categories = _parseList(
      data['categories'],
      Category.fromJson,
      'categorías',
    );
    final transactions = _parseList(
      data['transactions'],
      Transaction.fromJson,
      'movimientos',
    );

    await _accounts.clear();
    await _categories.clear();
    await _transactions.clear();

    await _accounts.putAll({for (final item in accounts) item.id: item});
    await _categories.putAll({for (final item in categories) item.id: item});
    await _transactions.putAll({for (final item in transactions) item.id: item});
  }

  static List<T> _parseList<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
    String label,
  ) {
    final items = <T>[];
    for (final entry in (raw as List<dynamic>)) {
      if (entry is! Map) {
        throw FormatException('El respaldo tiene $label con formato inválido.');
      }
      try {
        items.add(fromJson(Map<String, dynamic>.from(entry)));
      } catch (_) {
        throw FormatException('El respaldo tiene $label con formato inválido.');
      }
    }
    return items;
  }
}
