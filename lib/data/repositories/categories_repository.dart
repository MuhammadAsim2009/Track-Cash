import '../models/category.dart';

/// Repository interface for Category operations.
abstract class CategoriesRepository {
  /// Returns categories matching criteria.
  Future<List<AppCategory>> getCategories({
    CategoryType? type,
    bool includeHidden = false,
  });

  /// Watches categories matching criteria as a stream.
  Stream<List<AppCategory>> watchCategories({
    CategoryType? type,
    bool includeHidden = false,
  });

  /// Gets a category by ID.
  Future<AppCategory?> getCategoryById(String id);

  /// Creates a custom category.
  Future<void> createCategory(AppCategory category);

  /// Updates an existing category (e.g. rename, icon, color).
  Future<void> updateCategory(AppCategory category);

  /// Sets the hidden flag on a category.
  Future<void> hideCategory(String id, bool hide);

  /// Soft-deletes a category.
  Future<void> deleteCategory(String id);
}
