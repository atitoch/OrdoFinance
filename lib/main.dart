import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/network/app_keys.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/storage/hive_seeder.dart';
import 'core/storage/hive_storage.dart';
import 'core/theme/app_theme.dart';
import 'data/models/account.dart';

/// La interfaz está escrita en español; sin fijar el locale, `intl` cae en
/// `en_US` y las fechas y los selectores nativos salen en inglés.
const appLocale = Locale('es', 'MX');
const _intlLocale = 'es_MX';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = _intlLocale;
  await initializeDateFormatting(_intlLocale);
  await HiveStorage.init();
  await HiveSeeder.seedIfEmpty();
  await NotificationService.init();
  // Reprograma los avisos de corte en cada arranque: hasta ahora sólo se
  // programaban al crear o editar una cuenta.
  await NotificationService.scheduleForAccounts(
    Hive.box<Account>('accounts').values.toList(growable: false),
  );
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
      locale: appLocale,
      supportedLocales: const [appLocale, Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
