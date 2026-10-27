import 'package:flutter/foundation.dart';

enum TransactionType {
  income,
  expense;

  String get displayName => switch (this) {
        TransactionType.income => 'Income',
        TransactionType.expense => 'Expense',
      };
}

/// Plain Dart model representing an Income or Expense transaction.
@immutable
class TransactionEntry {
  const TransactionEntry({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.categoryId,
    required this.type,
    required this.amount,
    this.note,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.synced = false,
  });

  final String id;
  final String userId;
  final String walletId;
  final String categoryId;
  final TransactionType type;
  /// Amount in whole rupees.
  final int amount;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool synced;

  TransactionEntry copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? categoryId,
    TransactionType? type,
    int? amount,
    String? note,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? synced,
  }) {
    return TransactionEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      synced: synced ?? this.synced,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionEntry &&
        other.id == id &&
        other.userId == userId &&
        other.walletId == walletId &&
        other.categoryId == categoryId &&
        other.type == type &&
        other.amount == amount &&
        other.note == note &&
        other.date == date &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isDeleted == isDeleted &&
        other.synced == synced;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        walletId,
        categoryId,
        type,
        amount,
        note,
        date,
        createdAt,
        updatedAt,
        isDeleted,
        synced,
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'wallet_id': walletId,
      'category_id': categoryId,
      'type': type.name,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'synced': synced ? 1 : 0,
    };
  }

  factory TransactionEntry.fromMap(Map<String, dynamic> map) {
    return TransactionEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      walletId: map['wallet_id'] as String,
      categoryId: map['category_id'] as String,
      type: TransactionType.values.byName(map['type'] as String),
      amount: (map['amount'] as num).toInt(),
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  @override
  String toString() =>
      'TransactionEntry(id: $id, type: $type, amount: $amount, date: $date, note: $note)';
}
