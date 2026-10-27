import 'dart:async';
import '../models/transfer.dart';
import '../repositories/transfers_repository.dart';
import 'fake_seed_data.dart';

class FakeTransfersRepository implements TransfersRepository {
  FakeTransfersRepository() {
    _transfers = List<Transfer>.from(FakeSeedData.initialTransfers);
    _controller = StreamController<List<Transfer>>.broadcast();
  }

  late final List<Transfer> _transfers;
  late final StreamController<List<Transfer>> _controller;

  List<Transfer> get _sorted =>
      _transfers.where((t) => !t.isDeleted).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  void _notify() => _controller.add(List.unmodifiable(_sorted));

  @override
  Future<List<Transfer>> getTransfers() async => _sorted;

  @override
  Stream<List<Transfer>> watchTransfers() {
    return Stream.multi((controller) {
      controller.add(List.unmodifiable(_sorted));
      final sub = _controller.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<Transfer?> getTransferById(String id) async {
    return _transfers.where((t) => t.id == id && !t.isDeleted).firstOrNull;
  }

  @override
  Future<void> addTransfer(Transfer transfer) async {
    _transfers.add(transfer);
    _notify();
  }

  @override
  Future<void> deleteTransfer(String id) async {
    final index = _transfers.indexWhere((t) => t.id == id);
    if (index != -1) {
      _transfers[index] = _transfers[index].copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }
}
