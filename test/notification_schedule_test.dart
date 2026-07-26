import 'package:flutter_test/flutter_test.dart';
import 'package:ordo_finance/core/notifications/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));
  });

  tz.TZDateTime at(int year, int month, int day) =>
      tz.TZDateTime(tz.local, year, month, day, 12);

  test('el aviso siempre queda en el futuro', () {
    final now = at(2026, 7, 26);
    for (var cutDay = 1; cutDay <= 28; cutDay++) {
      for (final daysAhead in [15, 7, 1]) {
        final scheduled = NotificationService.nextScheduledDate(
          cutDay,
          daysAhead,
          from: now,
        );
        expect(
          scheduled,
          isNotNull,
          reason: 'corte $cutDay, aviso $daysAhead días',
        );
        expect(
          scheduled!.isAfter(now),
          isTrue,
          reason:
              'corte $cutDay con $daysAhead días de antelación devolvió '
              '$scheduled, que ya pasó',
        );
      }
    }
  });

  test('un corte anterior a la antelación salta al mes siguiente', () {
    // Caso que fallaba: corte el 5 con aviso de 15 días, ya pasado el de julio.
    final scheduled = NotificationService.nextScheduledDate(
      5,
      15,
      from: at(2026, 7, 26),
    );
    // El corte del 5 de agosto menos 15 días cae el 21 de julio, que ya pasó,
    // así que toca el del 5 de septiembre menos 15 días: 21 de agosto.
    expect(scheduled!.month, 8);
    expect(scheduled.day, 21);
    expect(scheduled.hour, 9);
  });

  test('avisa el día antes del corte', () {
    final scheduled = NotificationService.nextScheduledDate(
      20,
      1,
      from: at(2026, 7, 10),
    );
    expect(scheduled!.month, 7);
    expect(scheduled.day, 19);
  });

  test('un corte 31 se recorta a la longitud del mes', () {
    // Febrero de 2027 tiene 28 días: el corte cae el 28, no el 3 de marzo.
    final scheduled = NotificationService.nextScheduledDate(
      31,
      1,
      from: at(2027, 2, 1),
    );
    expect(scheduled!.month, 2);
    expect(scheduled.day, 27);
  });
}
