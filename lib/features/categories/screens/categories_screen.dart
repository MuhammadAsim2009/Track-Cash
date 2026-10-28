import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/icon_resolver.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/empty_state_view.dart';

/// Categories management screen with tabs for Expense and Income.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditCategoryDialog([AppCategory? categoryToEdit]) {
    final isEditing = categoryToEdit != null;
    final nameController =
        TextEditingController(text: categoryToEdit?.name ?? '');
    var selectedType = categoryToEdit?.type ??
        (_tabController.index == 0
            ? CategoryType.expense
            : CategoryType.income);
    var selectedIcon = categoryToEdit?.icon ?? 'fastfood';
    var selectedColor = categoryToEdit?.color ?? 0xFF059669;

    final availableColors = [
      0xFF059669, // Emerald
      0xFF10B981, // Teal
      0xFF06B6D4, // Cyan
      0xFF3B82F6, // Blue
      0xFF6366F1, // Indigo
      0xFF8B5CF6, // Purple
      0xFFEC4899, // Pink
      0xFFEF4444, // Red
      0xFFF97316, // Orange
      0xFFEAB308, // Yellow
      0xFF64748B, // Slate
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final activeColor = Color(selectedColor);
          final iconData = IconResolver.getIcon(selectedIcon);

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: activeColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Category' : 'New Category',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Customize name, icon and color',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.88,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Preview Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: activeColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: activeColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData, color: activeColor, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              nameController.text.trim().isEmpty
                                  ? 'Category Preview'
                                  : nameController.text.trim(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: nameController.text.trim().isEmpty
                                    ? Colors.grey
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: selectedType == CategoryType.expense
                                  ? Colors.red.withValues(alpha: 0.12)
                                  : Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              selectedType == CategoryType.expense
                                  ? 'Expense'
                                  : 'Income',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selectedType == CategoryType.expense
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Name
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Category Name',
                        hintText: 'e.g. Groceries, Utilities, Salary',
                        prefixIcon: const Icon(Icons.label_outline_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),

                    if (!isEditing) ...[
                      SegmentedButton<CategoryType>(
                        segments: const [
                          ButtonSegment(
                            value: CategoryType.expense,
                            icon: Icon(Icons.trending_down_rounded, size: 16),
                            label: Text('Expense'),
                          ),
                          ButtonSegment(
                            value: CategoryType.income,
                            icon: Icon(Icons.trending_up_rounded, size: 16),
                            label: Text('Income'),
                          ),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (set) {
                          setDialogState(() => selectedType = set.first);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Icon Picker Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Choose Icon',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${IconResolver.availableKeys.length} available',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 130,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: IconResolver.availableKeys.length,
                        itemBuilder: (context, idx) {
                          final key = IconResolver.availableKeys[idx];
                          final isSelected = selectedIcon == key;
                          return InkWell(
                            onTap: () =>
                                setDialogState(() => selectedIcon = key),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? activeColor.withValues(alpha: 0.18)
                                    : theme.colorScheme.surface,
                                border: Border.all(
                                  color: isSelected
                                      ? activeColor
                                      : Colors.grey.withValues(alpha: 0.2),
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                IconResolver.getIcon(key),
                                size: 20,
                                color: isSelected ? activeColor : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Color Picker Section
                    Text(
                      'Choose Color Palette',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: availableColors.map((colVal) {
                        final isSelected = selectedColor == colVal;
                        final swatchColor = Color(colVal);
                        return InkWell(
                          onTap: () =>
                              setDialogState(() => selectedColor = colVal),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: swatchColor,
                              shape: BoxShape.circle,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color:
                                            swatchColor.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded,
                                    size: 18, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  final now = DateTime.now();
                  final repo = ref.read(categoriesRepositoryProvider);

                  if (isEditing) {
                    final updated = categoryToEdit.copyWith(
                      name: name,
                      icon: selectedIcon,
                      color: selectedColor,
                      updatedAt: now,
                    );
                    await repo.updateCategory(updated);
                  } else {
                    final currentUserId = ref.read(currentUserIdProvider);
                    final newCat = AppCategory(
                      id: _uuid.v4(),
                      userId: currentUserId,
                      name: name,
                      type: selectedType,
                      icon: selectedIcon,
                      color: selectedColor,
                      isDefault: false,
                      isHidden: false,
                      createdAt: now,
                      updatedAt: now,
                    );
                    await repo.createCategory(newCat);
                  }

                  if (context.mounted) {
                    Navigator.of(ctx).pop();
                  }
                },
                icon: Icon(
                    isEditing ? Icons.save_rounded : Icons.add_rounded,
                    size: 18),
                label: Text(isEditing ? 'Save Changes' : 'Create Category'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseCatsAsync =
        ref.watch(categoriesStreamProvider(CategoryType.expense));
    final incomeCatsAsync =
        ref.watch(categoriesStreamProvider(CategoryType.income));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(expenseCatsAsync, CategoryType.expense),
          _buildCategoryList(incomeCatsAsync, CategoryType.income),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'categories_fab',
        onPressed: () => _showAddEditCategoryDialog(),
        tooltip: 'Add Category',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(
    AsyncValue<List<AppCategory>> asyncCategories,
    CategoryType type,
  ) {
    return asyncCategories.when(
      data: (categories) {
        if (categories.isEmpty) {
          return EmptyStateView(
            icon: Icons.category_outlined,
            title: 'No Categories',
            description: 'Create a new category for your transactions.',
            actionLabel: 'Add Category',
            onActionPressed: () => _showAddEditCategoryDialog(),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final catColor = Color(cat.color);
            final icon = IconResolver.getIcon(cat.icon);

            return Card(
              elevation: 0,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: catColor.withValues(alpha: 0.15),
                  child: Icon(icon, color: catColor, size: 22),
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cat.isHidden ? Colors.grey : null,
                          decoration: cat.isHidden
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (cat.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                    if (cat.isHidden) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Hidden',
                          style: TextStyle(fontSize: 10, color: Colors.orange),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        cat.isHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      tooltip: cat.isHidden ? 'Unhide category' : 'Hide category',
                      onPressed: () {
                        ref
                            .read(categoriesRepositoryProvider)
                            .hideCategory(cat.id, !cat.isHidden);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Edit category',
                      onPressed: () => _showAddEditCategoryDialog(cat),
                    ),
                    if (!cat.isDefault)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: 'Delete custom category',
                        onPressed: () async {
                          final confirmed = await showConfirmDialog(
                            context: context,
                            title: 'Delete Category',
                            message:
                                'Are you sure you want to delete "${cat.name}"?',
                          );
                          if (confirmed) {
                            await ref
                                .read(categoriesRepositoryProvider)
                                .deleteCategory(cat.id);
                          }
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
