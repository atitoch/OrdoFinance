import 'package:flutter_test/flutter_test.dart';
import 'package:ordo_finance/core/backup/backup_service.dart';

void main() {
  group('BackupService.import', () {
    // Los casos válidos necesitan Hive abierto; aquí se cubre lo que falla
    // antes de tocar Hive, que es donde salía el TypeError crudo.
    test('un registro incompleto da un mensaje legible', () async {
      final data = {
        'accounts': [
          {'id': 'a1'}, // faltan name, type, balance, ...
        ],
        'categories': <dynamic>[],
        'transactions': <dynamic>[],
      };

      await expectLater(
        BackupService.import(data),
        throwsA(
          isA<BackupImportException>().having(
            (e) => e.message,
            'message',
            allOf(contains('cuentas'), contains('registro 1')),
          ),
        ),
      );
    });

    test('una lista con basura da un mensaje legible', () async {
      final data = {
        'accounts': <dynamic>[],
        'categories': ['no soy un objeto'],
        'transactions': <dynamic>[],
      };

      await expectLater(
        BackupService.import(data),
        throwsA(
          isA<BackupImportException>().having(
            (e) => e.message,
            'message',
            contains('categorías'),
          ),
        ),
      );
    });

    test('un campo que no es lista da un mensaje legible', () async {
      final data = {
        'accounts': <dynamic>[],
        'categories': <dynamic>[],
        'transactions': 'esto no es una lista',
      };

      await expectLater(
        BackupService.import(data),
        throwsA(
          isA<BackupImportException>().having(
            (e) => e.message,
            'message',
            contains('movimientos'),
          ),
        ),
      );
    });
  });
}
