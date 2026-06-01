import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/app_keys.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/storage/hive_seeder.dart';
import 'core/storage/hive_storage.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorage.init();
  await HiveSeeder.seedIfEmpty();
  await NotificationService.init();
  runApp(const ProviderScope(child: OrdoFinanceApp()));
}

class OrdoFinanceApp extends StatelessWidget {
  const OrdoFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ordo Finance',
      theme: AppTheme.light,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: appRouter,
    );
  }
}
