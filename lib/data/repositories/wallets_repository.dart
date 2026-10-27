import '../models/wallet.dart';

/// Repository interface for Wallet operations.
abstract class WalletsRepository {
  /// Returns all active (non-deleted) wallets.
  Future<List<Wallet>> getWallets();

  /// Watches all active wallets as a stream.
  Stream<List<Wallet>> watchWallets();

  /// Gets a single wallet by ID.
  Future<Wallet?> getWalletById(String id);

  /// Computes the current balance of a specific wallet.
  /// Balance = opening + income - expenses + transfersIn - transfersOut.
  Future<int> getWalletBalance(String walletId);

  /// Computes the total balance across all active wallets.
  Future<int> getTotalBalance();

  /// Creates a new wallet.
  Future<void> createWallet(Wallet wallet);

  /// Updates an existing wallet.
  Future<void> updateWallet(Wallet wallet);

  /// Soft-deletes a wallet.
  Future<void> deleteWallet(String id);
}
