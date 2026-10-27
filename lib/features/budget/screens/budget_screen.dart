import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/icon_resolver.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repository_providers.dart';
import 'set_budget_screen.dart';

/// Provider for tracking currently selected month in Budget view.
/// Allows the main navigation FAB to open SetBudgetScreen for the viewed month.
final selectedBudgetMonthProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

/// Redesigned, modern Budget tab screen with:
/// - Month selector with quick "Today" shortcut
/// - Budget Health insight banner
/// - Hero summary ring card with percentage, spend pace & daily safe spend
/// - Category budget cards with percentage badges and progress bars
/// - Quick action buttons for editing or copying past budgets
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = ref.read(selectedBudgetMonthProvider);
  }

  void _setMonth(DateTime month) {
    setState(() {
      _currentMonth = month;
    });
    ref.read(selectedBudgetMonthProvider.notifier).state = month;
  }

  void _previousMonth() =>
      _setMonth(DateTime(_currentMonth.year, _currentMonth.month - 1));

  void _nextMonth() =>
      _setMonth(DateTime(_currentMonth.year, _currentMonth.month + 1));

  void _resetToCurrentMonth() => _setMonth(DateTime.now());

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _currentMonth.year == now.year && _currentMonth.month == now.month;
  }

  Future<void> _copyLastMonth() async {
    final fromMonth = DateFormatter.formatMonthKey(
      DateTime(_currentMonth.year, _currentMonth.month - 1),
    );
    final toMonth = DateFormatter.formatMonthKey(_currentMonth);
    final repo = ref.read(budgetsRepositoryProvider);
    final prevBudgets = await repo.getBudgetsForMonth(fromMonth);

    if (!mounted) return;
    if (prevBudgets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No budget in ${DateFormatter.formatMonthYear(DateTime(_currentMonth.year, _currentMonth.month - 1))} to copy.',
          ),
        ),
      );
      return;
    }

    await repo.copyBudgetsFromMonth(fromMonth: fromMonth, toMonth: toMonth);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied previous month's budget ✓")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthKey = DateFormatter.formatMonthKey(_currentMonth);

    final budgetsAsync = ref.watch(budgetsStreamProvider(monthKey));
    final totalSpentAsync = ref.watch(monthExpensesProvider(monthKey));
    final totalIncomeAsync = ref.watch(monthIncomeProvider(monthKey));
    final categoriesAsync = ref.watch(categoriesStreamProvider(null));

    final categoriesMap = {
      for (final c in categoriesAsync.value ?? <AppCategory>[]) c.id: c
    };

    return Scaffold(
      body: Column(
        children: [
          // ── Month Selector ──────────────────────────────────────────
          _MonthSelector(
            label: DateFormatter.formatMonthYear(_currentMonth),
            isCurrentMonth: _isCurrentMonth,
            onPrevious: _previousMonth,
            onNext: _nextMonth,
            onResetToday: _resetToCurrentMonth,
          ),

          // ── Body ────────────────────────────────────────────────────
          Expanded(
            child: budgetsAsync.when(
              data: (budgets) {
                final totalBudget =
                    budgets.where((b) => b.categoryId == null).firstOrNull;
                final categoryBudgets =
                    budgets.where((b) => b.categoryId != null).toList();

                if (budgets.isEmpty) {
                  return _EmptyBudgetState(
                    monthLabel: DateFormatter.formatMonthYear(_currentMonth),
                    onSetBudget: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SetBudgetScreen(monthKey: monthKey),
                      ),
                    ),
                    onCopyLastMonth: _copyLastMonth,
                  );
                }

                final spent = totalSpentAsync.value ?? 0;
                final income = totalIncomeAsync.value ?? 0;
                final daysLeft = _isCurrentMonth
                    ? DateFormatter.daysLeftInMonth(_currentMonth)
                    : null;

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(budgetsStreamProvider(monthKey));
                    ref.invalidate(monthExpensesProvider(monthKey));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Health / Insight Banner ──────────────────
                        if (totalBudget != null) ...[
                          _BudgetInsightBanner(
                            spent: spent,
                            budget: totalBudget.amount,
                            daysLeft: daysLeft,
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ── Hero Summary Card ────────────────────────
                        if (totalBudget != null) ...[
                          _HeroSummaryCard(
                            spent: spent,
                            income: income,
                            budget: totalBudget.amount,
                            daysLeft: daysLeft,
                          ),
                          const SizedBox(height: 18),
                        ],

                        // ── Category Budgets ─────────────────────────
                        if (categoryBudgets.isNotEmpty) ...[
                          _SectionHeader(
                            title: 'Category Breakdown',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${categoryBudgets.length} categories',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...categoryBudgets.map((b) {
                            final cat = categoriesMap[b.categoryId];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CategoryBudgetCard(
                                budget: b,
                                category: cat,
                                monthKey: monthKey,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SetBudgetScreen(monthKey: monthKey),
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 10),
                        ],

                        // ── Action Buttons ───────────────────────────
                        _ActionRow(
                          onEdit: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  SetBudgetScreen(monthKey: monthKey),
                            ),
                          ),
                          onCopyLastMonth: _copyLastMonth,
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error loading budget: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.label,
    required this.isCurrentMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onResetToday,
  });

  final String label;
  final bool isCurrentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onResetToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.filledTonal(
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            onPressed: onPrevious,
            tooltip: 'Previous month',
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              if (isCurrentMonth)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Current',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: onResetToday,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.today_rounded,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Today',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            onPressed: onNext,
            tooltip: 'Next month',
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetInsightBanner extends StatelessWidget {
  const _BudgetInsightBanner({
    required this.spent,
    required this.budget,
    this.daysLeft,
  });

  final int spent;
  final int budget;
  final int? daysLeft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final ratio = budget > 0 ? spent / budget : 0.0;
    final remaining = budget - spent;

    final Color bannerColor;
    final IconData icon;
    final String message;

    if (spent > budget) {
      bannerColor = colors.expense;
      icon = Icons.warning_amber_rounded;
      message =
          'Budget exceeded by ${CurrencyFormatter.format(spent - budget)}. Watch out on discretionary expenses!';
    } else if (ratio >= 0.8) {
      bannerColor = colors.warning;
      icon = Icons.error_outline_rounded;
      final daysText = daysLeft != null ? ' for the next $daysLeft days' : '';
      message =
          '${(ratio * 100).round()}% of budget spent. ${CurrencyFormatter.format(remaining)} left$daysText.';
    } else {
      bannerColor = colors.income;
      icon = Icons.check_circle_outline_rounded;
      final safeSpend = (daysLeft != null && daysLeft! > 0 && remaining > 0)
          ? ' • Safe pace: ~${CurrencyFormatter.format(remaining ~/ daysLeft!)}/day'
          : '';
      message =
          'You are on track! ${CurrencyFormatter.format(remaining)} available$safeSpend.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bannerColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: bannerColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: bannerColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({
    required this.spent,
    required this.income,
    required this.budget,
    this.daysLeft,
  });

  final int spent;
  final int income;
  final int budget;
  final int? daysLeft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final ratio = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final pct = (ratio * 100).round();
    final remaining = budget - spent;
    final isOver = spent > budget;

    final progressColor = isOver
        ? colors.expense
        : ratio >= 0.8
            ? colors.warning
            : colors.income;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Donut ring + stats row
            Row(
              children: [
                // Donut ring
                SizedBox(
                  width: 105,
                  height: 105,
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress: ratio,
                      progressColor: progressColor,
                      trackColor: colors.border,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$pct%',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                              fontSize: 22,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: progressColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isOver ? 'over' : 'used',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: progressColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Budget',
                        value: CurrencyFormatter.format(budget),
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(height: 8),
                      _StatRow(
                        icon: Icons.trending_down_rounded,
                        label: 'Spent',
                        value: CurrencyFormatter.format(spent),
                        color: colors.expense,
                      ),
                      const SizedBox(height: 8),
                      _StatRow(
                        icon: isOver
                            ? Icons.warning_amber_rounded
                            : Icons.savings_outlined,
                        label: isOver ? 'Over by' : 'Remaining',
                        value: CurrencyFormatter.format(remaining.abs()),
                        color: progressColor,
                        bold: true,
                      ),
                      if (income > 0) ...[
                        const SizedBox(height: 8),
                        _StatRow(
                          icon: Icons.trending_up_rounded,
                          label: 'Income',
                          value: CurrencyFormatter.format(income),
                          color: colors.income,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Linear progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isOver
                        ? 'Over limit by ${CurrencyFormatter.format(spent - budget)}'
                        : '${CurrencyFormatter.format(remaining)} remaining',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: progressColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (daysLeft != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '$daysLeft days left',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: color ?? theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
  });

  final double progress;
  final Color progressColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor;
}

class _CategoryBudgetCard extends ConsumerWidget {
  const _CategoryBudgetCard({
    required this.budget,
    required this.category,
    required this.monthKey,
    this.onTap,
  });

  final Budget budget;
  final AppCategory? category;
  final String monthKey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;

    final txsAsync = ref.watch(transactionsStreamProvider);
    final catSpent = txsAsync.value
            ?.where((tx) =>
                tx.categoryId == budget.categoryId &&
                tx.type == TransactionType.expense &&
                DateFormatter.formatMonthKey(tx.date) == monthKey)
            .fold<int>(0, (sum, tx) => sum + tx.amount) ??
        0;

    final ratio =
        budget.amount > 0 ? (catSpent / budget.amount).clamp(0.0, 1.0) : 0.0;
    final isOver = catSpent > budget.amount;
    final pct = (ratio * 100).round();
    final remaining = budget.amount - catSpent;

    final progressColor = isOver
        ? colors.expense
        : ratio >= 0.8
            ? colors.warning
            : colors.income;

    final catColor =
        category != null ? Color(category!.color) : theme.colorScheme.primary;
    final catIcon = category != null
        ? IconResolver.getIcon(category!.icon)
        : Icons.category_outlined;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category icon badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(catIcon, color: catColor, size: 22),
              ),
              const SizedBox(width: 14),

              // Name, progress bar & amounts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            category?.name ?? 'Category',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: progressColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOver ? 'Exceeded' : '$pct%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: progressColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: colors.border,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Spent ${CurrencyFormatter.format(catSpent)} of ${CurrencyFormatter.format(budget.amount)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOver
                              ? '+${CurrencyFormatter.format(catSpent - budget.amount)}'
                              : '${CurrencyFormatter.format(remaining)} left',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: progressColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBudgetState extends StatelessWidget {
  const _EmptyBudgetState({
    required this.monthLabel,
    required this.onSetBudget,
    required this.onCopyLastMonth,
  });

  final String monthLabel;
  final VoidCallback onSetBudget;
  final VoidCallback onCopyLastMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pie_chart_outline_rounded,
                size: 46,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Budget for $monthLabel',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Set a monthly limit to take control of spending and reach your financial goals with ease.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onSetBudget,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Set Monthly Budget'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onCopyLastMonth,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text("Copy Previous Month's Plan"),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onEdit,
    required this.onCopyLastMonth,
  });

  final VoidCallback onEdit;
  final VoidCallback onCopyLastMonth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: onEdit,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Edit Budget'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCopyLastMonth,
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy Previous'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
