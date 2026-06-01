import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/account.dart';

abstract final class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'ordo_credit_cuts',
    'Fechas de corte',
    description: 'Avisos de próxima fecha de corte de tarjetas de crédito.',
    importance: Importance.high,
  );

  static Future<void> init() async {
    if (kIsWeb) return;

    tz_data.initializeTimeZones();
    final local = tz.getLocation('America/Mexico_City');
    tz.setLocalLocation(local);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  static Future<void> requestPermission() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleForAccounts(List<Account> accounts) async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
    var idBase = 0;
    for (final account in accounts) {
      if (account.type == AccountType.credit &&
          account.cutDay != null &&
          account.isActive) {
        await _scheduleAccount(account, idBase);
        idBase += 3;
      }
    }
  }

  static Future<void> _scheduleAccount(Account account, int idBase) async {
    for (final daysAhead in [15, 7, 1]) {
      final scheduledDate = _nextScheduledDate(account.cutDay!, daysAhead);
      if (scheduledDate == null) continue;

      final title = daysAhead == 1
          ? '¡Corte mañana! ${account.name}'
          : 'Corte en $daysAhead días — ${account.name}';

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'ordo_credit_cuts',
          'Fechas de corte',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      await _plugin.zonedSchedule(
        idBase + (daysAhead == 15 ? 0 : daysAhead == 7 ? 1 : 2),
        title,
        'Revisa tu saldo y asegúrate de tener liquidez suficiente para pagar.',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    }
  }

  // Devuelve la próxima fecha en que falten exactamente [daysAhead] días para el corte.
  static tz.TZDateTime? _nextScheduledDate(int cutDay, int daysAhead) {
    final now = tz.TZDateTime.now(tz.local);
    // Día objetivo = cutDay - daysAhead del mes actual
    var targetDay = cutDay - daysAhead;
    var month = now.month;
    var year = now.year;

    if (targetDay < 1) {
      // Retrocede al mes anterior
      month--;
      if (month < 1) {
        month = 12;
        year--;
      }
      final daysInMonth = DateTime(year, month + 1, 0).day;
      targetDay = daysInMonth + targetDay;
    }

    var scheduled = tz.TZDateTime(tz.local, year, month, targetDay, 9, 0);
    if (scheduled.isBefore(now)) {
      // Ya pasó este mes, programa para el mes siguiente
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      targetDay = cutDay - daysAhead;
      if (targetDay < 1) {
        month--;
        if (month < 1) {
          month = 12;
          year--;
        }
        final daysInMonth = DateTime(year, month + 1, 0).day;
        targetDay = daysInMonth + targetDay;
      }
      scheduled = tz.TZDateTime(tz.local, year, month, targetDay, 9, 0);
    }
    return scheduled;
  }
}
