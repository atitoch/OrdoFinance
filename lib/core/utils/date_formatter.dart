import 'package:intl/intl.dart';

/// Formatos de fecha derivados de la preferencia elegida en Ajustes.
class AppDateFormats {
  const AppDateFormats(this.preference);

  /// Uno de los valores expuestos en Ajustes: `DD/MM/YYYY`, `MM/DD/YYYY`
  /// o `YYYY-MM-DD`.
  final String preference;

  static const options = ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'];

  String get _pattern => switch (preference) {
    'MM/DD/YYYY' => 'MM/dd/y',
    'YYYY-MM-DD' => 'y-MM-dd',
    _ => 'dd/MM/y',
  };

  /// `26/07/2026`
  String date(DateTime value) => DateFormat(_pattern).format(value);

  /// `26/07/2026 · 14:05`
  String dateTime(DateTime value) =>
      '${date(value)} · ${DateFormat.Hm().format(value)}';

  /// `domingo, 26/07/2026 · 14:05`
  String weekdayDateTime(DateTime value) =>
      '${DateFormat.EEEE().format(value)}, ${dateTime(value)}';
}
