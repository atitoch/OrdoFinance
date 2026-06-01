import 'package:dio/dio.dart';

import '../../../core/offline/local_store.dart';

import '../../../data/models/account.dart';

abstract interface class AccountsRepository {
  Future<List<Account>> getAll();
  Future<Account> create(Account account);
  Future<Account> update(Account account);
  Future<Account> archive(String id);
}

class HttpAccountsRepository implements AccountsRepository {
  const HttpAccountsRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Account>> getAll() async {
    if (_dio.options.baseUrl.isEmpty) return const [];
    final response = await _dio.get<List<dynamic>>('/accounts');
    return (response.data ?? const [])
        .map((json) => Account.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<Account> create(Account account) async {
    if (_dio.options.baseUrl.isEmpty) return account;
    final response = await _dio.post<Map<String, dynamic>>(
      '/accounts',
      data: account.toJson(),
    );
    return Account.fromJson(response.data!);
  }

  @override
  Future<Account> update(Account account) async {
    if (_dio.options.baseUrl.isEmpty) return account;
    final response = await _dio.put<Map<String, dynamic>>(
      '/accounts/${account.id}',
      data: account.toJson(),
    );
    return Account.fromJson(response.data!);
  }

  @override
  Future<Account> archive(String id) async {
    if (_dio.options.baseUrl.isEmpty) {
      throw StateError('ORDO_API_URL is not configured');
    }
    final response = await _dio.patch<Map<String, dynamic>>(
      '/accounts/$id',
      data: const {'isActive': false},
    );
    return Account.fromJson(response.data!);
  }
}

class OfflineFirstAccountsRepository implements AccountsRepository {
  const OfflineFirstAccountsRepository({
    required AccountsRepository remote,
    required LocalJsonStore cache,
    required PendingOperationStore pendingOperations,
    required bool remoteEnabled,
  }) : _remote = remote,
       _cache = cache,
       _pendingOperations = pendingOperations,
       _remoteEnabled = remoteEnabled;

  final AccountsRepository _remote;
  final LocalJsonStore _cache;
  final PendingOperationStore _pendingOperations;
  final bool _remoteEnabled;

  @override
  Future<List<Account>> getAll() async {
    final cached = await _readCache();
    if (!_remoteEnabled) {
      if (cached.isNotEmpty) return cached;
      await _seedDefaults();
      return _readCache();
    }

    try {
      await _flushPending();
      final remote = await _remote.getAll();
      await _cache.replaceAll(remote.map((account) => account.toJson()));
      return remote;
    } catch (_) {
      return cached;
    }
  }

  @override
  Future<Account> create(Account account) async {
    await _cache.put(account.id, account.toJson());
    if (!_remoteEnabled) {
      await _queue('create', account.id, account.toJson());
      return account;
    }

    try {
      final remote = await _remote.create(account);
      await _cache.put(remote.id, remote.toJson());
      return remote;
    } catch (_) {
      await _queue('create', account.id, account.toJson());
      return account;
    }
  }

  @override
  Future<Account> update(Account account) async {
    await _cache.put(account.id, account.toJson());
    if (!_remoteEnabled) {
      await _queue('update', account.id, account.toJson());
      return account;
    }

    try {
      final remote = await _remote.update(account);
      await _cache.put(remote.id, remote.toJson());
      return remote;
    } catch (_) {
      await _queue('update', account.id, account.toJson());
      return account;
    }
  }

  @override
  Future<Account> archive(String id) async {
    final accounts = await _readCache();
    final account = accounts
        .firstWhere((item) => item.id == id)
        .copyWith(isActive: false);
    await _cache.put(id, account.toJson());
    if (!_remoteEnabled) {
      await _queue('archive', id, account.toJson());
      return account;
    }

    try {
      final remote = await _remote.archive(id);
      await _cache.put(remote.id, remote.toJson());
      return remote;
    } catch (_) {
      await _queue('archive', id, account.toJson());
      return account;
    }
  }

  Future<void> _flushPending() async {
    final operations = await _pendingOperations.getAll();
    for (final operation in operations.where(
      (item) => item['entity'] == 'accounts',
    )) {
      try {
        final action = operation['action'] as String;
        final id = operation['entityId'] as String;
        final payload = operation['payload'] == null
            ? null
            : Map<String, dynamic>.from(operation['payload'] as Map);
        if (action == 'create' && payload != null) {
          await _remote.create(Account.fromJson(payload));
        } else if (action == 'update' && payload != null) {
          await _remote.update(Account.fromJson(payload));
        } else if (action == 'archive') {
          await _remote.archive(id);
        }
        await _pendingOperations.remove(operation['id'] as String);
      } catch (_) {
        return;
      }
    }
  }

  Future<List<Account>> _readCache() async {
    final items = await _cache.getAll();
    return items.map(Account.fromJson).toList(growable: false);
  }

  Future<void> _queue(String action, String id, Map<String, dynamic> payload) {
    return _pendingOperations.add(
      entity: 'accounts',
      action: action,
      id: id,
      payload: payload,
    );
  }

  Future<void> _seedDefaults() async {
    await _cache.replaceAll(
      _defaultAccounts.map((account) => account.toJson()),
    );
  }
}

final _defaultAccounts = [
  Account(
    id: 'account-checking',
    name: 'Checking',
    type: AccountType.checking,
    balance: 1245000,
    currency: 'USD',
    color: '#18181B',
    isActive: true,
    createdAt: DateTime(2026),
  ),
  Account(
    id: 'account-savings',
    name: 'Savings',
    type: AccountType.savings,
    balance: 8420000,
    currency: 'USD',
    color: '#3B82F6',
    isActive: true,
    createdAt: DateTime(2026),
  ),
];
