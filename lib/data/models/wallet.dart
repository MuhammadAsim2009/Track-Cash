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
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.synced = false,
  });

  final String id;
  final String userId;
  final String name;
  final WalletType type;
  final int openingBalance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool synced;

  Wallet copyWith({
    String? id,
    String? userId,
    String? name,
    WalletType? type,
    int? openingBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? synced,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      synced: synced ?? this.synced,
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
        openingBalance,
        createdAt,
        updatedAt,
        isDeleted,
        synced,
      );

  @override
  String toString() =>
      'Wallet(id: $id, name: $name, type: $type, openingBalance: $openingBalance, isDeleted: $isDeleted, synced: $synced)';
}
