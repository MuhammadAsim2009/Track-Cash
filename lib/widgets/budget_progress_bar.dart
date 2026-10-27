import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';

/// Budget progress indicator supporting <80% green, 80-100% amber warning, and >100% red exceeded status.
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.spent,
    required this.budget,
    this.title,
    this.daysLeft,
    this.showDetails = true,
  });

  final int spent;
  final int budget;
  final String? title;
  final int? daysLeft;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    final ratio = budget > 0 ? (spent / budget) : 0.0;
    final clampedRatio = ratio.clamp(0.0, 1.0);
    final percentage = (ratio * 100).round();
    final remaining = budget - spent;

    // Color logic from docs/design.md:
    // Green -> amber at 80% -> red when exceeded (>100%)
    final Color progressColor;
    final String statusLabel;

    if (ratio > 1.0) {
      progressColor = colors.expense;
      statusLabel = 'Exceeded by ${CurrencyFormatter.format(spent - budget)}';
    } else if (ratio >= 0.8) {
      progressColor = colors.warning;
      statusLabel = '${100 - percentage}% remaining';
    } else {
      progressColor = colors.income;
      statusLabel = '${CurrencyFormatter.format(remaining)} left';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$percentage%',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Visual progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clampedRatio,
            minHeight: 10,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),

        if (showDetails) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Spent ${CurrencyFormatter.format(spent)} of ${CurrencyFormatter.format(budget)}',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  daysLeft != null ? '$statusLabel • $daysLeft d left' : statusLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
