import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/account.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';

abstract final class HiveStorage {
  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(AccountAdapter());
    Hive.registerAdapter(AccountTypeAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(CategoryTypeAdapter());

    await Future.wait([
      Hive.openBox<Transaction>('transactions'),
      Hive.openBox<Account>('accounts'),
      Hive.openBox<Category>('categories'),
      Hive.openBox<dynamic>('ordo_pending_operations'),
      Hive.openBox<String>('settings'),
    ]);
  }
}
