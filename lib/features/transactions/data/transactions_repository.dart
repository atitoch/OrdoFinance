import 'package:dio/dio.dart';

import '../../../core/offline/local_store.dart';

import '../../../data/models/transaction.dart';

abstract interface class TransactionsRepository {
  Future<List<Transaction>> getAll();
  Future<Transaction> create(Transaction transaction);
  Future<Transaction> update(Transaction transaction);
  Future<void> delete(String id);
}

class HttpTransactionsRepository implements TransactionsRepository {
  const HttpTransactionsRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Transaction>> getAll() async {
    if (_dio.options.baseUrl.isEmpty) return const [];
    final response = await _dio.get<List<dynamic>>('/transactions');
    return (response.data ?? const [])
        .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<Transaction> create(Transaction transaction) async {
    if (_dio.options.baseUrl.isEmpty) return transaction;
    final response = await _dio.post<Map<String, dynamic>>(
      '/transactions',
      data: transaction.toJson(),
    );
    return Transaction.fromJson(response.data!);
  }

  @override
  Future<Transaction> update(Transaction transaction) async {
    if (_dio.options.baseUrl.isEmpty) return transaction;
    final response = await _dio.put<Map<String, dynamic>>(
      '/transactions/${transaction.id}',
      data: transaction.toJson(),
    );
    return Transaction.fromJson(response.data!);
  }

  @override
  Future<void> delete(String id) async {
    if (_dio.options.baseUrl.isEmpty) return;
    await _dio.delete<void>('/transactions/$id');
  }
}

class OfflineFirstTransactionsRepository implements TransactionsRepository {
  const OfflineFirstTransactionsRepository({
    required TransactionsRepository remote,
    required LocalJsonStore cache,
    required PendingOperationStore pendingOperations,
    required bool remoteEnabled,
  }) : _remote = remote,
       _cache = cache,
       _pendingOperations = pendingOperations,
       _remoteEnabled = remoteEnabled;

  final TransactionsRepository _remote;
  final LocalJsonStore _cache;
  final PendingOperationStore _pendingOperations;
  final bool _remoteEnabled;

  @override
  Future<List<Transaction>> getAll() async {
    final cached = await _readCache();
    if (!_remoteEnabled) return cached;

    try {
      await _flushPending();
      final remote = await _remote.getAll();
      await _cache.replaceAll(
        remote.map((transaction) => transaction.toJson()),
      );
      return remote;
    } catch (_) {
      return cached;
    }
  }

  @override
  Future<Transaction> create(Transaction transaction) async {
    await _cache.put(transaction.id, transaction.toJson());
    if (!_remoteEnabled) {
      await _queue('create', transaction.id, transaction.toJson());
      return transaction;
    }

    try {
      final remote = await _remote.create(transaction);
      await _cache.put(remote.id, remote.toJson());
      return remote;
    } catch (_) {
      await _queue('create', transaction.id, transaction.toJson());
      return transaction;
    }
  }

  @override
  Future<Transaction> update(Transaction transaction) async {
    await _cache.put(transaction.id, transaction.toJson());
    if (!_remoteEnabled) {
      await _queue('update', transaction.id, transaction.toJson());
      return transaction;
    }

    try {
      final remote = await _remote.update(transaction);
      await _cache.put(remote.id, remote.toJson());
      return remote;
    } catch (_) {
      await _queue('update', transaction.id, transaction.toJson());
      return transaction;
    }
  }

  @override
  Future<void> delete(String id) async {
    await _cache.delete(id);
    if (!_remoteEnabled) {
      await _pendingOperations.add(
        entity: 'transactions',
        action: 'delete',
        id: id,
      );
      return;
    }

    try {
      await _remote.delete(id);
    } catch (_) {
      await _pendingOperations.add(
        entity: 'transactions',
        action: 'delete',
        id: id,
      );
    }
  }

  Future<void> _flushPending() async {
    final operations = await _pendingOperations.getAll();
    for (final operation in operations.where(
      (item) => item['entity'] == 'transactions',
    )) {
      try {
        final action = operation['action'] as String;
        final id = operation['entityId'] as String;
        final payload = operation['payload'] == null
            ? null
            : Map<String, dynamic>.from(operation['payload'] as Map);
        if (action == 'create' && payload != null) {
          await _remote.create(Transaction.fromJson(payload));
        } else if (action == 'update' && payload != null) {
          await _remote.update(Transaction.fromJson(payload));
        } else if (action == 'delete') {
          await _remote.delete(id);
        }
        await _pendingOperations.remove(operation['id'] as String);
      } catch (_) {
        return;
      }
    }
  }

  Future<List<Transaction>> _readCache() async {
    final items = await _cache.getAll();
    return items.map(Transaction.fromJson).toList(growable: false);
  }

  Future<void> _queue(String action, String id, Map<String, dynamic> payload) {
    return _pendingOperations.add(
      entity: 'transactions',
      action: action,
      id: id,
      payload: payload,
    );
  }
}
