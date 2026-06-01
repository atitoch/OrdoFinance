import 'package:hive_flutter/hive_flutter.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
  @HiveField(2)
  transfer;

  static TransactionType fromJson(String value) =>
      TransactionType.values.firstWhere(
        (type) => type.name == value,
        orElse: () => throw ArgumentError.value(
          value,
          'value',
          'Unknown transaction type',
        ),
      );
}

@HiveType(typeId: 0)
class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.accountId,
    required this.description,
    required this.tags,
    required this.date,
    required this.createdAt,
    this.toAccountId,
    this.categoryId,
    this.note,
    this.deletedAt,
  });

  @HiveField(0)
  final String id;
  @HiveField(1)
  final TransactionType type;
  @HiveField(2)
  final int amount;
  @HiveField(3)
  final String currency;
  @HiveField(4)
  final String accountId;
  @HiveField(5)
  final String? toAccountId;
  @HiveField(6)
  final String? categoryId;
  @HiveField(7)
  final String description;
  @HiveField(8)
  final String? note;
  @HiveField(9)
  final List<String> tags;
  @HiveField(10)
  final DateTime date;
  @HiveField(11)
  final DateTime createdAt;
  @HiveField(12)
  final DateTime? deletedAt;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      type: TransactionType.fromJson(json['type'] as String),
      amount: json['amount'] as int,
      currency: json['currency'] as String,
      accountId: json['accountId'] as String,
      toAccountId: json['toAccountId'] as String?,
      categoryId: json['categoryId'] as String?,
      description: json['description'] as String,
      note: json['note'] as String?,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'categoryId': categoryId,
      'description': description,
      'note': note,
      'tags': tags,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  Transaction copyWith({
    String? id,
    TransactionType? type,
    int? amount,
    String? currency,
    String? accountId,
    String? toAccountId,
    String? categoryId,
    String? description,
    String? note,
    List<String>? tags,
    DateTime? date,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
