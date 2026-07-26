import 'package:hive_flutter/hive_flutter.dart';
import 'package:ulid/ulid.dart';

import '../../data/models/category.dart';

abstract final class HiveSeeder {
  /// Categorías por omisión del primer arranque.
  static const _defaults = [
    (
      name: 'Supermercado',
      type: CategoryType.expense,
      color: '#16A34A',
      icon: 'shopping_cart',
    ),
    (
      name: 'Restaurantes',
      type: CategoryType.expense,
      color: '#F97316',
      icon: 'restaurant',
    ),
    (
      name: 'Transporte',
      type: CategoryType.expense,
      color: '#3B82F6',
      icon: 'directions_car',
    ),
    (
      name: 'Entretenimiento',
      type: CategoryType.expense,
      color: '#8B5CF6',
      icon: 'entertainment',
    ),
    (
      name: 'Salud',
      type: CategoryType.expense,
      color: '#EF4444',
      icon: 'favorite',
    ),
    (
      name: 'Servicios',
      type: CategoryType.expense,
      color: '#71717A',
      icon: 'bolt',
    ),
    (
      name: 'Sueldo',
      type: CategoryType.income,
      color: '#16A34A',
      icon: 'trending_up',
    ),
    (
      name: 'Freelance',
      type: CategoryType.income,
      color: '#2563EB',
      icon: 'work',
    ),
  ];

  /// Nombres de las categorías de sistema sembradas en inglés en versiones
  /// anteriores. Se renombran en sitio para no dejar la app a medio traducir
  /// ni romper las referencias de los movimientos ya registrados.
  static const _legacyNames = {
    'Groceries': 'Supermercado',
    'Dining': 'Restaurantes',
    'Transport': 'Transporte',
    'Entertainment': 'Entretenimiento',
    'Health': 'Salud',
    'Utilities': 'Servicios',
    'Salary': 'Sueldo',
  };

  static Future<void> seedIfEmpty() async {
    final box = Hive.box<Category>('categories');
    if (box.isNotEmpty) {
      await _migrateLegacyNames(box);
      return;
    }

    final categories = _defaults
        .map(
          (item) => Category(
            id: Ulid().toString(),
            name: item.name,
            type: item.type,
            color: item.color,
            icon: item.icon,
            isSystem: true,
          ),
        )
        .toList(growable: false);

    await box.putAll({for (final c in categories) c.id: c});
  }

  static Future<void> _migrateLegacyNames(Box<Category> box) async {
    final updates = <String, Category>{};
    for (final category in box.values) {
      if (!category.isSystem) continue;
      final translated = _legacyNames[category.name];
      if (translated == null) continue;
      updates[category.id] = category.copyWith(
        name: translated,
        // "Entertainment" venía sembrada con el icono de servicios (un rayo).
        icon: category.name == 'Entertainment' ? 'entertainment' : null,
      );
    }
    if (updates.isNotEmpty) await box.putAll(updates);
  }
}
