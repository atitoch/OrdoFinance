import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/utils/date_formatter.dart';

class AppSettings {
  const AppSettings({this.currency = 'USD', this.dateFormat = 'DD/MM/YYYY'});

  final String currency;
  final String dateFormat;

  AppSettings copyWith({String? currency, String? dateFormat}) => AppSettings(
    currency: currency ?? this.currency,
    dateFormat: dateFormat ?? this.dateFormat,
  );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Box<String> get _box => Hive.box<String>('settings');

  void _load() {
    state = AppSettings(
      currency: _box.get('currency', defaultValue: 'USD')!,
      dateFormat: _box.get('dateFormat', defaultValue: 'DD/MM/YYYY')!,
    );
  }

  Future<void> setCurrency(String currency) async {
    await _box.put('currency', currency);
    state = state.copyWith(currency: currency);
  }

  Future<void> setDateFormat(String dateFormat) async {
    await _box.put('dateFormat', dateFormat);
    state = state.copyWith(dateFormat: dateFormat);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
      (_) => SettingsNotifier(),
    );

/// Moneda con la que se muestran los totales cuando no hay una cuenta
/// concreta de la cual tomarla.
final defaultCurrencyProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).currency;
});

/// Formateador de fechas que respeta la preferencia de Ajustes.
final dateFormatsProvider = Provider<AppDateFormats>((ref) {
  return AppDateFormats(ref.watch(settingsProvider).dateFormat);
});
