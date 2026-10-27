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

  @override
  String toString() =>
      'Budget(id: $id, month: $month, mode: $mode, categoryId: $categoryId, amount: $amount)';
}
