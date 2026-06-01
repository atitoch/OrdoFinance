import 'package:hive_flutter/hive_flutter.dart';

abstract final class LocalBoxNames {
  static const accounts = 'ordo_accounts';
  static const categories = 'ordo_categories';
  static const transactions = 'ordo_transactions';
  static const pendingOperations = 'ordo_pending_operations';
}

Future<void> initializeLocalStore({String? path}) async {
  if (path == null) {
    await Hive.initFlutter();
  } else {
    Hive.init(path);
  }
  await Future.wait([
    Hive.openBox<dynamic>(LocalBoxNames.accounts),
    Hive.openBox<dynamic>(LocalBoxNames.categories),
    Hive.openBox<dynamic>(LocalBoxNames.transactions),
    Hive.openBox<dynamic>(LocalBoxNames.pendingOperations),
  ]);
}

class LocalJsonStore {
  const LocalJsonStore(this.boxName);

  final String boxName;

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  Future<List<Map<String, dynamic>>> getAll() async {
    return _box.values
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<void> replaceAll(Iterable<Map<String, dynamic>> items) async {
    await _box.clear();
    await _box.putAll({for (final item in items) item['id'] as String: item});
  }

  Future<void> put(String id, Map<String, dynamic> value) async {
    await _box.put(id, value);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}

class PendingOperationStore {
  PendingOperationStore()
    : _box = Hive.box<dynamic>(LocalBoxNames.pendingOperations);

  final Box<dynamic> _box;

  Future<void> add({
    required String entity,
    required String action,
    required String id,
    Map<String, dynamic>? payload,
  }) async {
    final operationId =
        '${DateTime.now().microsecondsSinceEpoch}-$entity-$action-$id';
    await _box.put(operationId, {
      'id': operationId,
      'entity': entity,
      'action': action,
      'entityId': id,
      'payload': payload,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    return _box.values
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
  }
}
