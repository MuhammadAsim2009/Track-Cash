import 'package:flutter/foundation.dart';

enum UdhaarDirection {
  give,
  take;

  String get displayName => switch (this) {
        UdhaarDirection.give => 'I have to give',
        UdhaarDirection.take => 'I have to take',
      };
}

enum UdhaarStatus {
  pending,
  settled;

  String get displayName => switch (this) {
        UdhaarStatus.pending => 'Pending',
        UdhaarStatus.settled => 'Settled',
      };
}

/// Plain Dart model representing an informal loan entry (Udhaar).
@immutable
class Udhaar {
  const Udhaar({
    required this.id,
    required this.userId,
    this.walletId,
    required this.personName,
    required this.amount,
    required this.direction,
    required this.dueDate,
    this.status = UdhaarStatus.pending,
    this.note,
    this.notificationId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.synced = false,
  });

  final String id;
  final String userId;
  final String? walletId;
  final String personName;
  /// Amount in whole rupees.
  final int amount;
  final UdhaarDirection direction;
  final DateTime dueDate;
  final UdhaarStatus status;
  final String? note;
  final int? notificationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool synced;

  Udhaar copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? personName,
    int? amount,
    UdhaarDirection? direction,
    DateTime? dueDate,
    UdhaarStatus? status,
    String? note,
    int? notificationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? synced,
  }) {
    return Udhaar(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      direction: direction ?? this.direction,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      note: note ?? this.note,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      synced: synced ?? this.synced,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Udhaar &&
        other.id == id &&
        other.userId == userId &&
        other.walletId == walletId &&
        other.personName == personName &&
        other.amount == amount &&
        other.direction == direction &&
        other.dueDate == dueDate &&
        other.status == status &&
        other.note == note &&
        other.notificationId == notificationId &&
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
        personName,
        amount,
        direction,
        dueDate,
        status,
        note,
        notificationId,
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
      'person_name': personName,
      'amount': amount,
      'direction': direction.name,
      'due_date': dueDate.toIso8601String(),
      'status': status.name,
      'note': note,
      'notification_id': notificationId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'synced': synced ? 1 : 0,
    };
  }

  factory Udhaar.fromMap(Map<String, dynamic> map) {
    return Udhaar(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      walletId: map['wallet_id'] as String?,
      personName: map['person_name'] as String,
      amount: (map['amount'] as num).toInt(),
      direction: UdhaarDirection.values.byName(map['direction'] as String),
      dueDate: DateTime.parse(map['due_date'] as String),
      status: UdhaarStatus.values.byName(map['status'] as String),
      note: map['note'] as String?,
      notificationId: map['notification_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  @override
  String toString() =>
      'Udhaar(id: $id, person: $personName, amount: $amount, direction: $direction, walletId: $walletId, status: $status, due: $dueDate)';
}
