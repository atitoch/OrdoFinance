import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordo_finance/core/offline/local_store.dart';
import 'package:ordo_finance/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = await Directory.systemTemp.createTemp('ordo_finance_test_');
    await initializeLocalStore(path: tempDir.path);
  });

  testWidgets('renders the app shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OrdoFinanceApp()));

    expect(find.text('INICIO'), findsOneWidget);
    expect(find.text('ESTADÍSTICAS'), findsOneWidget);
    expect(find.text('MOVIMIENTOS'), findsOneWidget);
    expect(find.text('AJUSTES'), findsOneWidget);
  });
}
