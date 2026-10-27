import 'package:flutter/foundation.dart';

enum BudgetMode {
  total,
  category,
  both;

  String get displayName => switch (this) {
        BudgetMode.total => 'Total Monthly Budget',
        BudgetMode.category => 'Per-Category Budget',
        BudgetMode.both => 'Total & Category Budget',
      };
}

/// Plain Dart model representing a monthly budget target.
@immutable
class Budget {
  const Budget({
    required this.id,
    required this.userId,
    required this.month,
    required this.mode,
    this.categoryId,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.synced = false,
  });

  final String id;
  final String userId;
  /// Month in "YYYY-MM" format.
  final String month;
  final BudgetMode mode;
  /// Category ID if this is a per-category budget; null if total monthly budget.
  final String? categoryId;
  /// Budgeted amount in whole rupees.
  final int amount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool synced;

  Budget copyWith({
    String? id,
    String? userId,
    String? month,
    BudgetMode? mode,
    String? categoryId,
    int? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? synced,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      month: month ?? this.month,
      mode: mode ?? this.mode,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      synced: synced ?? this.synced,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget &&
        other.id == id &&
        other.userId == userId &&
        other.month == month &&
        other.mode == mode &&
        other.categoryId == categoryId &&
        other.amount == amount &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isDeleted == isDeleted &&
        other.synced == synced;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        month,
        mode,
        categoryId,
        amount,
        createdAt,
        updatedAt,
        isDeleted,
        synced,
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'month': month,
      'mode': mode.name,
      'category_id': categoryId,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'synced': synced ? 1 : 0,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      month: map['month'] as String,
      mode: BudgetMode.values.byName(map['mode'] as String),
      categoryId: map['category_id'] as String?,
      amount: (map['amount'] as num).toInt(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  @override
  String toString() =>
      'Budget(id: $id, month: $month, mode: $mode, categoryId: $categoryId, amount: $amount)';
}
