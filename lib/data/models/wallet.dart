import 'package:flutter/foundation.dart';

enum WalletType {
  cash,
  savings,
  mobileWallet;

  String get displayName => switch (this) {
        WalletType.cash => 'Cash in hand',
        WalletType.savings => 'Savings',
        WalletType.mobileWallet => 'Easypaisa / JazzCash',
      };
}

/// Plain Dart model representing a money place (Wallet).
@immutable
class Wallet {
  const Wallet({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.openingBalance,
    this.currentBalance = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.synced = false,
    this.countInDailyExpense = true,
  });

  final String id;
  final String userId;
  final String name;
  final WalletType type;
  final int openingBalance;
  /// Live current balance in whole rupees.
  final int currentBalance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool synced;
  /// Whether money in this wallet counts towards daily expenses.
  final bool countInDailyExpense;

  Wallet copyWith({
    String? id,
    String? userId,
    String? name,
    WalletType? type,
    int? openingBalance,
    int? currentBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? synced,
    bool? countInDailyExpense,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      synced: synced ?? this.synced,
      countInDailyExpense: countInDailyExpense ?? this.countInDailyExpense,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Wallet &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.type == type &&
        other.openingBalance == openingBalance &&
        other.currentBalance == currentBalance &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isDeleted == isDeleted &&
        other.synced == synced &&
        other.countInDailyExpense == countInDailyExpense;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        name,
        type,
        openingBalance,
        currentBalance,
        createdAt,
        updatedAt,
        isDeleted,
        synced,
        countInDailyExpense,
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.name,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'synced': synced ? 1 : 0,
      'count_in_daily_expense': countInDailyExpense ? 1 : 0,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    final opening = (map['opening_balance'] as num).toInt();
    final current = (map['current_balance'] as num?)?.toInt() ?? opening;
    return Wallet(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      type: WalletType.values.byName(map['type'] as String),
      openingBalance: opening,
      currentBalance: current,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      synced: (map['synced'] as int? ?? 0) == 1,
      countInDailyExpense: (map['count_in_daily_expense'] as int? ?? 1) == 1,
    );
  }

  @override
  String toString() =>
      'Wallet(id: $id, name: $name, type: $type, openingBalance: $openingBalance, currentBalance: $currentBalance, countInDailyExpense: $countInDailyExpense, isDeleted: $isDeleted)';
}
