import '../models/udhaar.dart';

/// Repository interface for Udhaar (informal debts / loans).
abstract class UdhaarRepository {
  /// Returns udhaar items matching optional direction and status filters.
  Future<List<Udhaar>> getUdhaarList({
    UdhaarDirection? direction,
    UdhaarStatus? status,
  });

  /// Watches all active udhaar items.
  Stream<List<Udhaar>> watchUdhaarList();

  /// Gets a single udhaar record by ID.
  Future<Udhaar?> getUdhaarById(String id);

  /// Returns upcoming pending udhaar items (for dashboard / reminders).
  Future<List<Udhaar>> getUpcomingUdhaar({int limit = 5});

  /// Adds a new udhaar record.
  Future<void> addUdhaar(Udhaar udhaar);

  /// Updates an existing udhaar record.
  Future<void> updateUdhaar(Udhaar udhaar);

  /// Marks an udhaar entry as settled, optionally recording which wallet paid/received the settlement.
  Future<void> markAsSettled(String id, {String? settleWalletId});

  /// Soft-deletes an udhaar entry.
  Future<void> deleteUdhaar(String id);
}
