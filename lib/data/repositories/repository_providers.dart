import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'budgets_repository.dart';
import 'categories_repository.dart';
import 'sqlite/sqlite_budgets_repository.dart';
import 'sqlite/sqlite_categories_repository.dart';
import 'sqlite/sqlite_transactions_repository.dart';
import 'sqlite/sqlite_transfers_repository.dart';
import 'sqlite/sqlite_udhaar_repository.dart';
import 'sqlite/sqlite_wallets_repository.dart';
import 'transactions_repository.dart';
import 'transfers_repository.dart';
import 'udhaar_repository.dart';
import 'wallets_repository.dart';

export '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/auth_provider.dart';

// --- Base SQLite Repository Providers ---

final walletsRepositoryProvider = Provider<WalletsRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return SqliteWalletsRepository(userId: userId);
});

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return SqliteCategoriesRepository(userId: userId);
});

final transfersRepositoryProvider = Provider<TransfersRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final walletsRepo = ref.watch(walletsRepositoryProvider) as SqliteWalletsRepository;
  return SqliteTransfersRepository(
    userId: userId,
    onDataChanged: walletsRepo.notifyListeners,
  );
});

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final walletsRepo = ref.watch(walletsRepositoryProvider) as SqliteWalletsRepository;
  final transfersRepo = ref.watch(transfersRepositoryProvider) as SqliteTransfersRepository;
  return SqliteTransactionsRepository(
    userId: userId,
    onDataChanged: walletsRepo.notifyListeners,
    onTransfersChanged: transfersRepo.notifyListeners,
  );
});

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return SqliteBudgetsRepository(userId: userId);
});

final udhaarRepositoryProvider = Provider<UdhaarRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final walletsRepo = ref.watch(walletsRepositoryProvider) as SqliteWalletsRepository;
  return SqliteUdhaarRepository(
    userId: userId,
    onDataChanged: walletsRepo.notifyListeners,
  );
});

// --- Reactive Streams & Convenience Providers ---

final walletsStreamProvider = StreamProvider<List<Wallet>>((ref) {
  ref.watch(syncTickProvider); // re-query when a pull completes
  final repo = ref.watch(walletsRepositoryProvider);
  return repo.watchWallets();
});

final walletBalanceProvider =
    FutureProvider.family<int, String>((ref, walletId) async {
  ref.watch(walletsStreamProvider);
  ref.watch(transactionsStreamProvider);
  ref.watch(transfersStreamProvider);
  ref.watch(udhaarStreamProvider);
  final repo = ref.watch(walletsRepositoryProvider);
  return repo.getWalletBalance(walletId);
});

final totalBalanceProvider = FutureProvider<int>((ref) async {
  // Re-evaluate when wallets, transactions, transfers or udhaar change
  ref.watch(walletsStreamProvider);
  ref.watch(transactionsStreamProvider);
  ref.watch(transfersStreamProvider);
  ref.watch(udhaarStreamProvider);
  final repo = ref.watch(walletsRepositoryProvider);
  return repo.getTotalBalance();
});

final transactionsStreamProvider =
    StreamProvider<List<TransactionEntry>>((ref) {
  ref.watch(syncTickProvider); // re-query when a pull completes
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.watchTransactions();
});

final recentTransactionsProvider =
    FutureProvider<List<TransactionEntry>>((ref) async {
  ref.watch(transactionsStreamProvider);
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.getRecentTransactions(limit: 5);
});

final monthExpensesProvider =
    FutureProvider.family<int, String>((ref, monthKey) async {
  ref.watch(transactionsStreamProvider);
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.getTotalExpenseForMonth(monthKey);
});

final monthIncomeProvider =
    FutureProvider.family<int, String>((ref, monthKey) async {
  ref.watch(transactionsStreamProvider);
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.getTotalIncomeForMonth(monthKey);
});

final transfersStreamProvider = StreamProvider<List<Transfer>>((ref) {
  ref.watch(syncTickProvider); // re-query when a pull completes
  final repo = ref.watch(transfersRepositoryProvider);
  return repo.watchTransfers();
});

final categoriesStreamProvider =
    StreamProvider.family<List<AppCategory>, CategoryType?>((ref, type) {
  ref.watch(syncTickProvider); // re-query when a pull completes
  final repo = ref.watch(categoriesRepositoryProvider);
  return repo.watchCategories(type: type);
});

final budgetsStreamProvider =
    StreamProvider.family<List<Budget>, String>((ref, monthKey) {
  ref.watch(syncTickProvider); // re-query when a pull completes
  final repo = ref.watch(budgetsRepositoryProvider);
  return repo.watchBudgetsForMonth(monthKey);
});

final totalBudgetProvider =
    FutureProvider.family<Budget?, String>((ref, monthKey) async {
  ref.watch(budgetsStreamProvider(monthKey));
  final repo = ref.watch(budgetsRepositoryProvider);
  return repo.getTotalBudgetForMonth(monthKey);
});

final udhaarStreamProvider = StreamProvider<List<Udhaar>>((ref) {
  ref.watch(syncTickProvider); // re-query when a pull completes
  final repo = ref.watch(udhaarRepositoryProvider);
  return repo.watchUdhaarList();
});

final upcomingUdhaarProvider = FutureProvider<List<Udhaar>>((ref) async {
  ref.watch(udhaarStreamProvider);
  final repo = ref.watch(udhaarRepositoryProvider);
  return repo.getUpcomingUdhaar(limit: 5);
});
