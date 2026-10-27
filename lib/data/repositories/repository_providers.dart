import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../fake/fake_budgets_repository.dart';
import '../fake/fake_categories_repository.dart';
import '../fake/fake_transactions_repository.dart';
import '../fake/fake_transfers_repository.dart';
import '../fake/fake_udhaar_repository.dart';
import '../fake/fake_wallets_repository.dart';
import '../models/models.dart';
import 'budgets_repository.dart';
import 'categories_repository.dart';
import 'transactions_repository.dart';
import 'transfers_repository.dart';
import 'udhaar_repository.dart';
import 'wallets_repository.dart';

// --- Base Repository Providers ---

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return FakeTransactionsRepository();
});

final transfersRepositoryProvider = Provider<TransfersRepository>((ref) {
  return FakeTransfersRepository();
});

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return FakeCategoriesRepository();
});

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return FakeBudgetsRepository();
});

final udhaarRepositoryProvider = Provider<UdhaarRepository>((ref) {
  return FakeUdhaarRepository();
});

final walletsRepositoryProvider = Provider<WalletsRepository>((ref) {
  final txRepo = ref.watch(transactionsRepositoryProvider);
  final trRepo = ref.watch(transfersRepositoryProvider);
  return FakeWalletsRepository(
    transactionsRepository: txRepo,
    transfersRepository: trRepo,
  );
});

// --- Reactive Streams & Convenience Providers ---

final walletsStreamProvider = StreamProvider<List<Wallet>>((ref) {
  final repo = ref.watch(walletsRepositoryProvider);
  return repo.watchWallets();
});

final walletBalanceProvider =
    FutureProvider.family<int, String>((ref, walletId) async {
  ref.watch(walletsStreamProvider);
  ref.watch(transactionsStreamProvider);
  ref.watch(transfersStreamProvider);
  final repo = ref.watch(walletsRepositoryProvider);
  return repo.getWalletBalance(walletId);
});

final totalBalanceProvider = FutureProvider<int>((ref) async {
  // Re-evaluate when wallets, transactions or transfers change
  ref.watch(walletsStreamProvider);
  ref.watch(transactionsStreamProvider);
  ref.watch(transfersStreamProvider);
  final repo = ref.watch(walletsRepositoryProvider);
  return repo.getTotalBalance();
});

final transactionsStreamProvider =
    StreamProvider<List<TransactionEntry>>((ref) {
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
  final repo = ref.watch(transfersRepositoryProvider);
  return repo.watchTransfers();
});

final categoriesStreamProvider =
    StreamProvider.family<List<AppCategory>, CategoryType?>((ref, type) {
  final repo = ref.watch(categoriesRepositoryProvider);
  return repo.watchCategories(type: type);
});

final budgetsStreamProvider =
    StreamProvider.family<List<Budget>, String>((ref, monthKey) {
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
  final repo = ref.watch(udhaarRepositoryProvider);
  return repo.watchUdhaarList();
});

final upcomingUdhaarProvider = FutureProvider<List<Udhaar>>((ref) async {
  ref.watch(udhaarStreamProvider);
  final repo = ref.watch(udhaarRepositoryProvider);
  return repo.getUpcomingUdhaar(limit: 5);
});
