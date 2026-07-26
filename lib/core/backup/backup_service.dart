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

const _backupVersion = 1;

class BackupImportException implements Exception {
  BackupImportException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract final class BackupService {
  static Future<File> export() async {
    final accountsBox = Hive.box<Account>('accounts');
    final categoriesBox = Hive.box<Category>('categories');
    final transactionsBox = Hive.box<Transaction>('transactions');

    final data = {
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': accountsBox.values.map((a) => a.toJson()).toList(),
      'categories': categoriesBox.values.map((c) => c.toJson()).toList(),
      'transactions': transactionsBox.values.map((t) => t.toJson()).toList(),
    };

    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/ordofinance_backup_$timestamp.json');
    await file.writeAsString(jsonEncode(data));
    return file;
  }

  static Future<void> exportAndShare() async {
    final file = await export();
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Respaldo de Ordo Finance',
    );
  }

  static Future<Map<String, dynamic>?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return null;

    final content = await File(path).readAsString();
    Map<String, dynamic> data;
    try {
      data = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      throw BackupImportException('El archivo no es un respaldo válido.');
    }

    if (data['accounts'] == null ||
        data['categories'] == null ||
        data['transactions'] == null) {
      throw BackupImportException('El archivo no tiene el formato esperado.');
    }
    return data;
  }

  static Future<void> import(Map<String, dynamic> data) async {
    // Se parsea todo antes de tocar Hive: si el respaldo viene dañado, los
    // datos actuales quedan intactos.
    final accounts = _parseAll(data['accounts'], Account.fromJson, 'cuentas');
    final categories = _parseAll(
      data['categories'],
      Category.fromJson,
      'categorías',
    );
    final transactions = _parseAll(
      data['transactions'],
      Transaction.fromJson,
      'movimientos',
    );

    final accountsBox = Hive.box<Account>('accounts');
    final categoriesBox = Hive.box<Category>('categories');
    final transactionsBox = Hive.box<Transaction>('transactions');

    await accountsBox.clear();
    await categoriesBox.clear();
    await transactionsBox.clear();

    await accountsBox.putAll({for (final a in accounts) a.id: a});
    await categoriesBox.putAll({for (final c in categories) c.id: c});
    await transactionsBox.putAll({for (final t in transactions) t.id: t});
  }

  /// Convierte una lista del respaldo, traduciendo cualquier fallo de formato
  /// a un mensaje legible: sin esto salía el TypeError crudo de `fromJson`.
  static List<T> _parseAll<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
    String label,
  ) {
    if (raw is! List) {
      throw BackupImportException(
        'El respaldo no tiene una lista de $label válida.',
      );
    }
    final items = <T>[];
    for (var i = 0; i < raw.length; i++) {
      final entry = raw[i];
      if (entry is! Map) {
        throw BackupImportException(
          'El respaldo tiene $label con formato inválido (registro ${i + 1}).',
        );
      }
      try {
        items.add(fromJson(Map<String, dynamic>.from(entry)));
      } catch (_) {
        throw BackupImportException(
          'El respaldo tiene $label con formato inválido (registro ${i + 1}).',
        );
      }
    }
    return items;
  }
}
