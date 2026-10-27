import 'package:flutter/foundation.dart';

/// Plain Dart model representing a money transfer between two wallets.
@immutable
class Transfer {
  const Transfer({
    required this.id,
    required this.userId,
    required this.fromWalletId,
    required this.toWalletId,
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
  final String fromWalletId;
  final String toWalletId;
  /// Amount transferred in whole rupees.
  final int amount;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool synced;

  Transfer copyWith({
    String? id,
    String? userId,
    String? fromWalletId,
    String? toWalletId,
    int? amount,
    String? note,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? synced,
  }) {
    return Transfer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fromWalletId: fromWalletId ?? this.fromWalletId,
      toWalletId: toWalletId ?? this.toWalletId,
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
    return other is Transfer &&
        other.id == id &&
        other.userId == userId &&
        other.fromWalletId == fromWalletId &&
        other.toWalletId == toWalletId &&
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
        fromWalletId,
        toWalletId,
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
      'from_wallet_id': fromWalletId,
      'to_wallet_id': toWalletId,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'synced': synced ? 1 : 0,
    };
  }

  factory Transfer.fromMap(Map<String, dynamic> map) {
    return Transfer(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      fromWalletId: map['from_wallet_id'] as String,
      toWalletId: map['to_wallet_id'] as String,
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
      'Transfer(id: $id, from: $fromWalletId, to: $toWalletId, amount: $amount, date: $date)';
}
