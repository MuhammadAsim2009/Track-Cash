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

  @override
  String toString() =>
      'AppCategory(id: $id, name: $name, type: $type, isDefault: $isDefault, isHidden: $isHidden)';
}
