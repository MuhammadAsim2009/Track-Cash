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

  @override
  String toString() =>
      'TransactionEntry(id: $id, type: $type, amount: $amount, date: $date, note: $note)';
}
