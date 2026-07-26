import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
    await _configureLocalTimeZone();

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

  /// Usa la zona horaria del dispositivo. Estaba fija en America/Mexico_City,
  /// así que fuera de esa zona los avisos salían a una hora ajena.
  static Future<void> _configureLocalTimeZone() async {
    try {
      // flutter_timezone devuelve String en 3.x y un objeto con `identifier`
      // en 4.x; se acepta cualquiera de las dos formas.
      final dynamic result = await FlutterTimezone.getLocalTimezone();
      final name = result is String ? result : result.identifier as String;
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Si el sistema no da la zona, UTC es preferible a imponer una ajena.
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
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
    final withCutDay = accounts.where(
      (account) =>
          account.type == AccountType.credit &&
          account.cutDay != null &&
          account.isActive,
    );

    await _plugin.cancelAll();
    if (withCutDay.isEmpty) return;

    // Sin este permiso (Android 13+ e iOS) las alertas se programan pero
    // nunca se muestran.
    await requestPermission();

    var idBase = 0;
    for (final account in withCutDay) {
      await _scheduleAccount(account, idBase);
      idBase += 3;
    }
  }

  static Future<void> _scheduleAccount(Account account, int idBase) async {
    for (final daysAhead in [15, 7, 1]) {
      final scheduledDate = nextScheduledDate(account.cutDay!, daysAhead);
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

  /// Próxima fecha, a las 9:00, en la que faltan [daysAhead] días para el
  /// corte. Se prueban los cortes de los meses siguientes hasta dar con uno
  /// cuyo aviso siga en el futuro.
  ///
  /// La versión anterior calculaba el día restando a mano y, cuando el aviso
  /// ya había pasado, hacía `month++` seguido de `month--`: para un corte del
  /// 1 al 15 devolvía la misma fecha pasada una y otra vez.
  @visibleForTesting
  static tz.TZDateTime? nextScheduledDate(
    int cutDay,
    int daysAhead, {
    tz.TZDateTime? from,
  }) {
    final now = from ?? tz.TZDateTime.now(tz.local);
    for (var offset = 0; offset <= 2; offset++) {
      final cut = _cutDateFor(now.year, now.month + offset, cutDay);
      final notice = cut.subtract(Duration(days: daysAhead));
      final scheduled = tz.TZDateTime(
        tz.local,
        notice.year,
        notice.month,
        notice.day,
        9,
      );
      if (scheduled.isAfter(now)) return scheduled;
    }
    return null;
  }

  /// Fecha de corte de un mes. [month] puede desbordar 12: `TZDateTime` y
  /// `DateTime` normalizan el año. El día se recorta a la longitud del mes,
  /// para que un corte 31 caiga el 28 en febrero en vez de irse a marzo.
  static tz.TZDateTime _cutDateFor(int year, int month, int cutDay) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return tz.TZDateTime(tz.local, year, month, cutDay.clamp(1, daysInMonth), 9);
  }
}
