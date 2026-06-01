import 'package:hive_flutter/hive_flutter.dart';

part 'category.g.dart';

@HiveType(typeId: 5)
enum CategoryType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
  @HiveField(2)
  both;

  static CategoryType fromJson(String value) => CategoryType.values.firstWhere(
    (type) => type.name == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'Unknown category type'),
  );
}

@HiveType(typeId: 4)
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
    required this.isSystem,
    this.parentId,
    this.budgetLimit,
  });

  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final CategoryType type;
  @HiveField(3)
  final String color;
  @HiveField(4)
  final String icon;
  @HiveField(5)
  final String? parentId;
  @HiveField(6)
  final int? budgetLimit;
  @HiveField(7)
  final bool isSystem;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      type: CategoryType.fromJson(json['type'] as String),
      color: json['color'] as String,
      icon: json['icon'] as String,
      parentId: json['parentId'] as String?,
      budgetLimit: json['budgetLimit'] as int?,
      isSystem: json['isSystem'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'color': color,
      'icon': icon,
      'parentId': parentId,
      'budgetLimit': budgetLimit,
      'isSystem': isSystem,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    CategoryType? type,
    String? color,
    String? icon,
    String? parentId,
    int? budgetLimit,
    bool? isSystem,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      isSystem: isSystem ?? this.isSystem,
    );
  }
}
