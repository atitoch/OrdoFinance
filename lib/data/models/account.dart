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

  String get label => switch (this) {
    AccountType.checking => 'Corriente',
    AccountType.savings => 'Ahorro',
    AccountType.cash => 'Efectivo',
    AccountType.credit => 'Crédito',
    AccountType.investment => 'Inversión',
  };
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
    this.balanceAsOf,
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

  /// Fecha a la que corresponde [balance]. Los movimientos anteriores ya están
  /// incluidos en ese saldo, así que no vuelven a sumarse: sin esto, importar
  /// el histórico de la cuenta descontaba dos veces lo mismo.
  @HiveField(10)
  final DateTime? balanceAsOf;

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
      balanceAsOf: json['balanceAsOf'] == null
          ? null
          : DateTime.parse(json['balanceAsOf'] as String),
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
      'balanceAsOf': balanceAsOf?.toIso8601String(),
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
    DateTime? balanceAsOf,
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
      balanceAsOf: balanceAsOf ?? this.balanceAsOf,
    );
  }
}

const _sentinel = Object();
