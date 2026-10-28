import 'dart:async';
import '../models/udhaar.dart';
import '../repositories/udhaar_repository.dart';
import 'fake_seed_data.dart';

class FakeUdhaarRepository implements UdhaarRepository {
  FakeUdhaarRepository() {
    _udhaarList = List<Udhaar>.from(FakeSeedData.initialUdhaar);
    _controller = StreamController<List<Udhaar>>.broadcast();
  }

  late final List<Udhaar> _udhaarList;
  late final StreamController<List<Udhaar>> _controller;

  List<Udhaar> get _sorted =>
      _udhaarList.where((u) => !u.isDeleted).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  void _notify() => _controller.add(List.unmodifiable(_sorted));

  @override
  Future<List<Udhaar>> getUdhaarList({
    UdhaarDirection? direction,
    UdhaarStatus? status,
  }) async {
    return _udhaarList.where((u) {
      if (u.isDeleted) return false;
      if (direction != null && u.direction != direction) return false;
      if (status != null && u.status != status) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  @override
  Stream<List<Udhaar>> watchUdhaarList() {
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
  Future<Udhaar?> getUdhaarById(String id) async {
    return _udhaarList.where((u) => u.id == id && !u.isDeleted).firstOrNull;
  }

  @override
  Future<List<Udhaar>> getUpcomingUdhaar({int limit = 5}) async {
    final pending = _udhaarList
        .where((u) => !u.isDeleted && u.status == UdhaarStatus.pending)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return pending.take(limit).toList();
  }

  @override
  Future<void> addUdhaar(Udhaar udhaar) async {
    _udhaarList.add(udhaar);
    _notify();
  }

  @override
  Future<void> updateUdhaar(Udhaar udhaar) async {
    final index = _udhaarList.indexWhere((u) => u.id == udhaar.id);
    if (index != -1) {
      _udhaarList[index] = udhaar.copyWith(updatedAt: DateTime.now());
      _notify();
    }
  }

  @override
  Future<void> markAsSettled(String id, {String? settleWalletId}) async {
    final index = _udhaarList.indexWhere((u) => u.id == id);
    if (index != -1) {
      _udhaarList[index] = _udhaarList[index].copyWith(
        walletId: settleWalletId ?? _udhaarList[index].walletId,
        status: UdhaarStatus.settled,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> deleteUdhaar(String id) async {
    final index = _udhaarList.indexWhere((u) => u.id == id);
    if (index != -1) {
      _udhaarList[index] = _udhaarList[index].copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }
}
