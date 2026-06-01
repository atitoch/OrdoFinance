import 'package:dio/dio.dart';

import '../../../core/offline/local_store.dart';

import '../../../data/models/category.dart';

abstract interface class CategoriesRepository {
  Future<List<Category>> getAll();
  Future<Category> create(Category category);
  Future<Category> update(Category category);
  Future<void> delete(String id);
}

class HttpCategoriesRepository implements CategoriesRepository {
  const HttpCategoriesRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Category>> getAll() async {
    if (_dio.options.baseUrl.isEmpty) return const [];
    final response = await _dio.get<List<dynamic>>('/categories');
    return (response.data ?? const [])
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<Category> create(Category category) async {
    if (_dio.options.baseUrl.isEmpty) return category;
    final response = await _dio.post<Map<String, dynamic>>(
      '/categories',
      data: category.toJson(),
    );
    return Category.fromJson(response.data!);
  }

  @override
  Future<Category> update(Category category) async {
    if (_dio.options.baseUrl.isEmpty) return category;
    final response = await _dio.put<Map<String, dynamic>>(
      '/categories/${category.id}',
      data: category.toJson(),
    );
    return Category.fromJson(response.data!);
  }

  @override
  Future<void> delete(String id) async {
    if (_dio.options.baseUrl.isEmpty) return;
    await _dio.delete<void>('/categories/$id');
  }
}

class OfflineFirstCategoriesRepository implements CategoriesRepository {
  const OfflineFirstCategoriesRepository({
    required CategoriesRepository remote,
    required LocalJsonStore cache,
    required PendingOperationStore pendingOperations,
    required bool remoteEnabled,
  }) : _remote = remote,
       _cache = cache,
       _pendingOperations = pendingOperations,
       _remoteEnabled = remoteEnabled;

  final CategoriesRepository _remote;
  final LocalJsonStore _cache;
  final PendingOperationStore _pendingOperations;
  final bool _remoteEnabled;

  @override
  Future<List<Category>> getAll() async {
    final cached = await _readCache();
    if (!_remoteEnabled) {
      if (cached.isNotEmpty) return cached;
      await _seedDefaults();
      return _readCache();
    }

    try {
      await _flushPending();
      final remote = await _remote.getAll();
      await _cache.replaceAll(remote.map((category) => category.toJson()));
      return remote;
    } catch (_) {
      return cached;
    }
  }

  @override
  Future<Category> create(Category category) async {
    await _cache.put(category.id, category.toJson());
    if (!_remoteEnabled) {
      await _queue('create', category.id, category.toJson());
      return category;
    }

    try {
      final remote = await _remote.create(category);
      await _cache.put(remote.id, remote.toJson());
      return remote;
    } catch (_) {
      await _queue('create', category.id, category.toJson());
      return category;
    }
  }

  @override
  Future<Category> update(Category category) async {
    await _cache.put(category.id, category.toJson());
    if (!_remoteEnabled) {
      await _queue('update', category.id, category.toJson());
      return category;
    }

    try {
      final remote = await _remote.update(category);
      await _cache.put(remote.id, remote.toJson());
      return remote;
    } catch (_) {
      await _queue('update', category.id, category.toJson());
      return category;
    }
  }

  @override
  Future<void> delete(String id) async {
    await _cache.delete(id);
    if (!_remoteEnabled) {
      await _pendingOperations.add(
        entity: 'categories',
        action: 'delete',
        id: id,
      );
      return;
    }

    try {
      await _remote.delete(id);
    } catch (_) {
      await _pendingOperations.add(
        entity: 'categories',
        action: 'delete',
        id: id,
      );
    }
  }

  Future<void> _flushPending() async {
    final operations = await _pendingOperations.getAll();
    for (final operation in operations.where(
      (item) => item['entity'] == 'categories',
    )) {
      try {
        final action = operation['action'] as String;
        final id = operation['entityId'] as String;
        final payload = operation['payload'] == null
            ? null
            : Map<String, dynamic>.from(operation['payload'] as Map);
        if (action == 'create' && payload != null) {
          await _remote.create(Category.fromJson(payload));
        } else if (action == 'update' && payload != null) {
          await _remote.update(Category.fromJson(payload));
        } else if (action == 'delete') {
          await _remote.delete(id);
        }
        await _pendingOperations.remove(operation['id'] as String);
      } catch (_) {
        return;
      }
    }
  }

  Future<List<Category>> _readCache() async {
    final items = await _cache.getAll();
    return items.map(Category.fromJson).toList(growable: false);
  }

  Future<void> _queue(String action, String id, Map<String, dynamic> payload) {
    return _pendingOperations.add(
      entity: 'categories',
      action: action,
      id: id,
      payload: payload,
    );
  }

  Future<void> _seedDefaults() async {
    await _cache.replaceAll(
      _systemCategories.map((category) => category.toJson()),
    );
  }
}

const _systemCategories = [
  Category(
    id: 'system-groceries',
    name: 'Groceries',
    type: CategoryType.expense,
    color: '#16A34A',
    icon: 'shopping_cart',
    isSystem: true,
  ),
  Category(
    id: 'system-dining',
    name: 'Dining',
    type: CategoryType.expense,
    color: '#F97316',
    icon: 'utensils',
    isSystem: true,
  ),
  Category(
    id: 'system-transport',
    name: 'Transport',
    type: CategoryType.expense,
    color: '#3B82F6',
    icon: 'car',
    isSystem: true,
  ),
  Category(
    id: 'system-entertainment',
    name: 'Entertainment',
    type: CategoryType.expense,
    color: '#8B5CF6',
    icon: 'zap',
    isSystem: true,
  ),
  Category(
    id: 'system-health',
    name: 'Health',
    type: CategoryType.expense,
    color: '#EF4444',
    icon: 'heart',
    isSystem: true,
  ),
  Category(
    id: 'system-salary',
    name: 'Salary',
    type: CategoryType.income,
    color: '#16A34A',
    icon: 'trending_up',
    isSystem: true,
  ),
  Category(
    id: 'system-freelance',
    name: 'Freelance',
    type: CategoryType.income,
    color: '#2563EB',
    icon: 'briefcase',
    isSystem: true,
  ),
  Category(
    id: 'system-utilities',
    name: 'Utilities',
    type: CategoryType.expense,
    color: '#71717A',
    icon: 'zap',
    isSystem: true,
  ),
];
