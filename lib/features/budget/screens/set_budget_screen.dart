import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/icon_resolver.dart';
import '../../../data/fake/fake_seed_data.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../widgets/money_input_field.dart';

/// Screen for configuring Monthly Budget (total, per-category, or both).
class SetBudgetScreen extends ConsumerStatefulWidget {
  const SetBudgetScreen({
    super.key,
    required this.monthKey,
  });

  final String monthKey;

  @override
  ConsumerState<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends ConsumerState<SetBudgetScreen> {
  final _totalController = TextEditingController();
  final Map<String, TextEditingController> _categoryControllers = {};
  List<AppCategory> _expenseCategories = [];
  static const _uuid = Uuid();

  BudgetMode _mode = BudgetMode.both;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _totalController.addListener(_onAmountChanged);
    _loadExistingBudgets();
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadExistingBudgets() async {
    final budgetsRepo = ref.read(budgetsRepositoryProvider);
    final existing = await budgetsRepo.getBudgetsForMonth(widget.monthKey);

    final totalBudget = existing.where((b) => b.categoryId == null).firstOrNull;
    if (totalBudget != null) {
      _totalController.text = totalBudget.amount.toString();
      _mode = totalBudget.mode;
    }

    final catRepo = ref.read(categoriesRepositoryProvider);
    final expenseCategories =
        await catRepo.getCategories(type: CategoryType.expense);
    _expenseCategories = expenseCategories;

    for (final cat in expenseCategories) {
      final b = existing.where((b) => b.categoryId == cat.id).firstOrNull;
      final controller =
          TextEditingController(text: b != null ? b.amount.toString() : '');
      controller.addListener(_onAmountChanged);
      _categoryControllers[cat.id] = controller;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _totalController.removeListener(_onAmountChanged);
    _totalController.dispose();
    for (final c in _categoryControllers.values) {
      c.removeListener(_onAmountChanged);
      c.dispose();
    }
    super.dispose();
  }

  int get _calculatedCategoriesTotal {
    int sum = 0;
    for (final c in _categoryControllers.values) {
      sum += CurrencyFormatter.parse(c.text);
    }
    return sum;
  }

  int get _parsedTotalBudget =>
      CurrencyFormatter.parse(_totalController.text);

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final now = DateTime.now();
    final repo = ref.read(budgetsRepositoryProvider);

    // Save Total Budget if mode includes total
    if (_mode == BudgetMode.total || _mode == BudgetMode.both) {
      final totalAmount = _parsedTotalBudget;
      if (totalAmount > 0) {
        final totalBudget = Budget(
          id: _uuid.v4(),
          userId: kDemoUserId,
          month: widget.monthKey,
          mode: _mode,
          categoryId: null,
          amount: totalAmount,
          createdAt: now,
          updatedAt: now,
        );
        await repo.setBudget(totalBudget);
      }
    }

    // Save Category Budgets if mode includes category
    if (_mode == BudgetMode.category || _mode == BudgetMode.both) {
      for (final entry in _categoryControllers.entries) {
        final catId = entry.key;
        final amount = CurrencyFormatter.parse(entry.value.text);
        if (amount > 0) {
          final catBudget = Budget(
            id: _uuid.v4(),
            userId: kDemoUserId,
            month: widget.monthKey,
            mode: _mode,
            categoryId: catId,
            amount: amount,
            createdAt: now,
            updatedAt: now,
          );
          await repo.setBudget(catBudget);
        }
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget saved successfully ✓')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final monthDate = DateFormatter.parseMonthKey(widget.monthKey);
    final catTotal = _calculatedCategoriesTotal;
    final overallTotal = _parsedTotalBudget;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set Budget',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              DateFormatter.formatMonthYear(monthDate),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mode Selector Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.tune_rounded,
                                  size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Budgeting Strategy',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SegmentedButton<BudgetMode>(
                            showSelectedIcon: false,
                            style: SegmentedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            segments: const [
                              ButtonSegment(
                                value: BudgetMode.total,
                                icon: Icon(Icons.account_balance_wallet_outlined, size: 15),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Overall', maxLines: 1),
                                ),
                              ),
                              ButtonSegment(
                                value: BudgetMode.category,
                                icon: Icon(Icons.category_outlined, size: 15),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Category', maxLines: 1),
                                ),
                              ),
                              ButtonSegment(
                                value: BudgetMode.both,
                                icon: Icon(Icons.pie_chart_outline_rounded, size: 15),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Both', maxLines: 1),
                                ),
                              ),
                            ],
                            selected: {_mode},
                            onSelectionChanged: (set) {
                              setState(() => _mode = set.first);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Total Budget input (if Total or Both)
                    if (_mode == BudgetMode.total || _mode == BudgetMode.both) ...[
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Overall Monthly Limit',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Cap on your total spending for ${DateFormatter.formatMonthYear(monthDate)}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              MoneyInputField(
                                controller: _totalController,
                                labelText: 'Total Budget (PKR)',
                                hintText: 'e.g. 50,000',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Category Budgets input (if Category or Both)
                    if (_mode == BudgetMode.category || _mode == BudgetMode.both) ...[
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.category_rounded,
                                          color: theme.colorScheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Per-Category Budgets',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_expenseCategories.length} items',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_mode == BudgetMode.both && overallTotal > 0) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (catTotal > overallTotal)
                                        ? colors.expense.withValues(alpha: 0.1)
                                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: (catTotal > overallTotal)
                                          ? colors.expense.withValues(alpha: 0.3)
                                          : colors.border,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          (catTotal > overallTotal)
                                              ? 'Categories exceed overall budget by ${CurrencyFormatter.format(catTotal - overallTotal)}'
                                              : 'Allocated ${CurrencyFormatter.format(catTotal)} of ${CurrencyFormatter.format(overallTotal)} (${CurrencyFormatter.format(overallTotal - catTotal)} unallocated)',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: (catTotal > overallTotal)
                                                ? colors.expense
                                                : colors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _expenseCategories.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final cat = _expenseCategories[index];
                                  final controller = _categoryControllers[cat.id];
                                  if (controller == null) return const SizedBox();

                                  final catColor = Color(cat.color);
                                  final catIcon = IconResolver.getIcon(cat.icon);

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: catColor.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(catIcon, color: catColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: MoneyInputField(
                                          controller: controller,
                                          labelText: '${cat.name} Budget',
                                          hintText: '0',
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Save Budget',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
