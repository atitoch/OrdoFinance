import 'package:hive_flutter/hive_flutter.dart';
import 'package:ulid/ulid.dart';

import '../../data/models/category.dart';

abstract final class HiveSeeder {
  static Future<void> seedIfEmpty() async {
    final box = Hive.box<Category>('categories');
    if (box.isNotEmpty) return;

    final categories = [
      Category(
        id: Ulid().toString(),
        name: 'Groceries',
        type: CategoryType.expense,
        color: '#16A34A',
        icon: 'shopping_cart',
        isSystem: true,
      ),
      Category(
        id: Ulid().toString(),
        name: 'Dining',
        type: CategoryType.expense,
        color: '#F97316',
        icon: 'restaurant',
        isSystem: true,
      ),
      Category(
        id: Ulid().toString(),
        name: 'Transport',
        type: CategoryType.expense,
        color: '#3B82F6',
        icon: 'directions_car',
        isSystem: true,
      ),
      Category(
        id: Ulid().toString(),
        name: 'Entertainment',
        type: CategoryType.expense,
        color: '#8B5CF6',
        icon: 'bolt',
        isSystem: true,
      ),
      Category(
        id: Ulid().toString(),
        name: 'Health',
        type: CategoryType.expense,
        color: '#EF4444',
        icon: 'favorite',
        isSystem: true,
      ),
      Category(
        id: Ulid().toString(),
        name: 'Utilities',
        type: CategoryType.expense,
        color: '#71717A',
        icon: 'bolt',
        isSystem: true,
      ),
      Category(
        id: Ulid().toString(),
        name: 'Salary',
        type: CategoryType.income,
        color: '#16A34A',
        icon: 'trending_up',
        isSystem: true,
      ),
      Category(
        id: Ulid().toString(),
        name: 'Freelance',
        type: CategoryType.income,
        color: '#2563EB',
        icon: 'work',
        isSystem: true,
      ),
    ];

    await box.putAll({for (final c in categories) c.id: c});
  }
}
