import 'package:hive_flutter/hive_flutter.dart';

part 'account.g.dart';

@HiveType(typeId: 3)
enum AccountType {
  @HiveField(0)
  checking,
  @HiveField(1)
  savings,
  @HiveField(2)
  cash,
  @HiveField(3)
  credit,
  @HiveField(4)
  investment;

  static AccountType fromJson(String value) => AccountType.values.firstWhere(
    (type) => type.name == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'Unknown account type'),
  );
}

@HiveType(typeId: 2)
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    required this.isActive,
    required this.createdAt,
    this.color,
    this.icon,
    this.cutDay,
  });

  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final AccountType type;
  @HiveField(3)
  final int balance;
  @HiveField(4)
  final String currency;
  @HiveField(5)
  final String? color;
  @HiveField(6)
  final String? icon;
  @HiveField(7)
  final bool isActive;
  @HiveField(8)
  final DateTime createdAt;
  @HiveField(9)
  final int? cutDay;

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AccountType.fromJson(json['type'] as String),
      balance: json['balance'] as int,
      currency: json['currency'] as String,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      cutDay: json['cutDay'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'balance': balance,
      'currency': currency,
      'color': color,
      'icon': icon,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'cutDay': cutDay,
    };
  }

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    int? balance,
    String? currency,
    String? color,
    String? icon,
    bool? isActive,
    DateTime? createdAt,
    Object? cutDay = _sentinel,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      cutDay: cutDay == _sentinel ? this.cutDay : cutDay as int?,
    );
  }
}

const _sentinel = Object();
