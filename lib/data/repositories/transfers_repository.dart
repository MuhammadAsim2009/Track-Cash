import '../models/transfer.dart';

/// Repository interface for Transfers between wallets.
abstract class TransfersRepository {
  /// Returns all active transfers, newest first.
  Future<List<Transfer>> getTransfers();

  /// Watches transfers as a stream.
  Stream<List<Transfer>> watchTransfers();

  /// Gets a single transfer by ID.
  Future<Transfer?> getTransferById(String id);

  /// Records a new transfer between two wallets.
  Future<void> addTransfer(Transfer transfer);

  /// Soft-deletes a transfer.
  Future<void> deleteTransfer(String id);
}
