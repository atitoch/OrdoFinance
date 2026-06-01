import 'package:hive_flutter/hive_flutter.dart';

import '../../../data/models/category.dart';
import '../../../features/categories/data/categories_repository.dart';

class LocalCategoriesRepository implements CategoriesRepository {
  Box<Category> get _box => Hive.box<Category>('categories');

  @override
  Future<List<Category>> getAll() async {
    final items = _box.values.toList();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  @override
  Future<Category> create(Category category) async {
    await _box.put(category.id, category);
    return category;
  }

  @override
  Future<Category> update(Category category) async {
    await _box.put(category.id, category);
    return category;
  }

  @override
  Future<void> delete(String id) async {
    final category = _box.get(id);
    if (category == null) return;
    if (category.isSystem) {
      throw StateError('System categories cannot be deleted');
    }
    await _box.delete(id);
  }

  Future<Category?> getById(String id) async => _box.get(id);
}
