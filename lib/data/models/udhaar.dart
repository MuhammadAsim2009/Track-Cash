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

  @override
  String toString() =>
      'Udhaar(id: $id, person: $personName, amount: $amount, direction: $direction, status: $status, due: $dueDate)';
}
