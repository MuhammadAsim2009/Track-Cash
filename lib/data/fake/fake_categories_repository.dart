import 'dart:async';
import '../models/category.dart';
import '../repositories/categories_repository.dart';
import 'fake_seed_data.dart';

class FakeCategoriesRepository implements CategoriesRepository {
  FakeCategoriesRepository() {
    _categories = List<AppCategory>.from(FakeSeedData.initialCategories);
    _controller = StreamController<List<AppCategory>>.broadcast();
  }

  late final List<AppCategory> _categories;
  late final StreamController<List<AppCategory>> _controller;

  List<AppCategory> get _active =>
      _categories.where((c) => !c.isDeleted).toList();

  void _notify() => _controller.add(List.unmodifiable(_active));

  @override
  Future<List<AppCategory>> getCategories({
    CategoryType? type,
    bool includeHidden = false,
  }) async {
    return _categories.where((c) {
      if (c.isDeleted) return false;
      if (!includeHidden && c.isHidden) return false;
      if (type != null && c.type != type) return false;
      return true;
    }).toList();
  }

  @override
  Stream<List<AppCategory>> watchCategories({
    CategoryType? type,
    bool includeHidden = false,
  }) {
    return Stream.multi((controller) {
      // Emit current filtered state immediately.
      controller.add(_filtered(type: type, includeHidden: includeHidden));
      final sub = _controller.stream.map((list) {
        return list.where((c) {
          if (!includeHidden && c.isHidden) return false;
          if (type != null && c.type != type) return false;
          return true;
        }).toList();
      }).listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  List<AppCategory> _filtered({CategoryType? type, bool includeHidden = false}) {
    return _active.where((c) {
      if (!includeHidden && c.isHidden) return false;
      if (type != null && c.type != type) return false;
      return true;
    }).toList();
  }

  @override
  Future<AppCategory?> getCategoryById(String id) async {
    return _categories.where((c) => c.id == id && !c.isDeleted).firstOrNull;
  }

  @override
  Future<void> createCategory(AppCategory category) async {
    _categories.add(category);
    _notify();
  }

  @override
  Future<void> updateCategory(AppCategory category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category.copyWith(updatedAt: DateTime.now());
      _notify();
    }
  }

  @override
  Future<void> hideCategory(String id, bool hide) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index] = _categories[index].copyWith(
        isHidden: hide,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index] = _categories[index].copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }
}
