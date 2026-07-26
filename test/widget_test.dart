import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:ordo_finance/data/models/account.dart';
import 'package:ordo_finance/data/models/category.dart';
import 'package:ordo_finance/data/models/transaction.dart';
import 'package:ordo_finance/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Intl.defaultLocale = 'es_MX';
    await initializeDateFormatting('es_MX');

    // Las mismas cajas que abre HiveStorage.init(): antes el test abría otras
    // ('ordo_*') y los providers arrancaban en estado de error.
    final tempDir = await Directory.systemTemp.createTemp('ordo_finance_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(AccountAdapter());
    Hive.registerAdapter(AccountTypeAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(CategoryTypeAdapter());
    await Future.wait([
      Hive.openBox<Transaction>('transactions'),
      Hive.openBox<Account>('accounts'),
      Hive.openBox<Category>('categories'),
      Hive.openBox<String>('settings'),
    ]);
  });

  testWidgets('renders the app shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OrdoFinanceApp()));
    await tester.pump();

    expect(find.text('INICIO'), findsOneWidget);
    expect(find.text('ESTADÍSTICAS'), findsOneWidget);
    expect(find.text('MOVIMIENTOS'), findsOneWidget);
    expect(find.text('AJUSTES'), findsOneWidget);
  });

  testWidgets('no muestra el banner de error al cargar', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OrdoFinanceApp()));
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudieron cargar los datos más recientes.'),
      findsNothing,
    );
  });
}
