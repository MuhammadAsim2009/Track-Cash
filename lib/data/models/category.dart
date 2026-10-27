import 'package:flutter/foundation.dart';

enum CategoryType {
  income,
  expense;

  String get displayName => switch (this) {
        CategoryType.income => 'Income',
        CategoryType.expense => 'Expense',
      };
}

/// Plain Dart model representing an expense/income category.
@immutable
class AppCategory {
  const AppCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isDefault = false,
    this.isHidden = false,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.synced = false,
  });

  final String id;
  final String userId;
  final String name;
  final CategoryType type;
  final String icon;
  final int color;
  final bool isDefault;
  final bool isHidden;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool synced;

  AppCategory copyWith({
    String? id,
    String? userId,
    String? name,
    CategoryType? type,
    String? icon,
    int? color,
    bool? isDefault,
    bool? isHidden,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? synced,
  }) {
    return AppCategory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      synced: synced ?? this.synced,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppCategory &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.type == type &&
        other.icon == icon &&
        other.color == color &&
        other.isDefault == isDefault &&
        other.isHidden == isHidden &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isDeleted == isDeleted &&
        other.synced == synced;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        name,
        type,
        icon,
        color,
        isDefault,
        isHidden,
        createdAt,
        updatedAt,
        isDeleted,
        synced,
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.name,
      'icon': icon,
      'color': color,
      'is_default': isDefault ? 1 : 0,
      'is_hidden': isHidden ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'synced': synced ? 1 : 0,
    };
  }

  factory AppCategory.fromMap(Map<String, dynamic> map) {
    return AppCategory(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      type: CategoryType.values.byName(map['type'] as String),
      icon: map['icon'] as String,
      color: (map['color'] as num).toInt(),
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      isHidden: (map['is_hidden'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  @override
  String toString() =>
      'AppCategory(id: $id, name: $name, type: $type, isDefault: $isDefault, isHidden: $isHidden)';
}
