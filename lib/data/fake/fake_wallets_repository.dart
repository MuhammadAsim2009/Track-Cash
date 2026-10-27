import 'dart:async';
import '../models/transaction_entry.dart';
import '../models/wallet.dart';
import '../repositories/transactions_repository.dart';
import '../repositories/transfers_repository.dart';
import '../repositories/wallets_repository.dart';
import 'fake_seed_data.dart';

class FakeWalletsRepository implements WalletsRepository {
  FakeWalletsRepository({
    TransactionsRepository? transactionsRepository,
    TransfersRepository? transfersRepository,
  })  : _transactionsRepository = transactionsRepository,
        _transfersRepository = transfersRepository {
    _wallets = List<Wallet>.from(FakeSeedData.initialWallets);
    _controller = StreamController<List<Wallet>>.broadcast();
  }

  late final List<Wallet> _wallets;
  late final StreamController<List<Wallet>> _controller;
  TransactionsRepository? _transactionsRepository;
  TransfersRepository? _transfersRepository;

  void attachDependencies({
    required TransactionsRepository transactionsRepository,
    required TransfersRepository transfersRepository,
  }) {
    _transactionsRepository = transactionsRepository;
    _transfersRepository = transfersRepository;
  }

  List<Wallet> get _active => _wallets.where((w) => !w.isDeleted).toList();

  void _notify() => _controller.add(List.unmodifiable(_active));

  @override
  Future<List<Wallet>> getWallets() async => _active;

  @override
  Stream<List<Wallet>> watchWallets() {
    // Emit current state immediately to every new subscriber, then follow live updates.
    return Stream.multi((controller) {
      controller.add(List.unmodifiable(_active));
      final sub = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<Wallet?> getWalletById(String id) async {
    return _wallets.where((w) => w.id == id && !w.isDeleted).firstOrNull;
  }

  @override
  Future<int> getWalletBalance(String walletId) async {
    final wallet = await getWalletById(walletId);
    if (wallet == null) return 0;

    int balance = wallet.openingBalance;

    if (_transactionsRepository != null) {
      final txs = await _transactionsRepository!.getTransactions(walletId: walletId);
      for (final tx in txs) {
        if (tx.type == TransactionType.income) {
          balance += tx.amount;
        } else {
          balance -= tx.amount;
        }
      }
    }

    if (_transfersRepository != null) {
      final transfers = await _transfersRepository!.getTransfers();
      for (final tr in transfers) {
        if (tr.toWalletId == walletId) {
          balance += tr.amount;
        } else if (tr.fromWalletId == walletId) {
          balance -= tr.amount;
        }
      }
    }

    return balance;
  }

  @override
  Future<int> getTotalBalance() async {
    final activeWallets = await getWallets();
    int total = 0;
    for (final wallet in activeWallets) {
      total += await getWalletBalance(wallet.id);
    }
    return total;
  }

  @override
  Future<void> createWallet(Wallet wallet) async {
    _wallets.add(wallet);
    _notify();
  }

  @override
  Future<void> updateWallet(Wallet wallet) async {
    final index = _wallets.indexWhere((w) => w.id == wallet.id);
    if (index != -1) {
      _wallets[index] = wallet.copyWith(updatedAt: DateTime.now());
      _notify();
    }
  }

  @override
  Future<void> deleteWallet(String id) async {
    final index = _wallets.indexWhere((w) => w.id == id);
    if (index != -1) {
      _wallets[index] = _wallets[index].copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }
}
