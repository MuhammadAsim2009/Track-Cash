import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/udhaar.dart';

/// Tile component for an Udhaar item with due date chip, direction, and settlement status.
class UdhaarTile extends StatelessWidget {
  const UdhaarTile({
    super.key,
    required this.udhaar,
    this.walletName,
    this.onTap,
    this.onSettle,
    this.onDelete,
  });

  final Udhaar udhaar;
  final String? walletName;
  final VoidCallback? onTap;
  final VoidCallback? onSettle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    final isSettled = udhaar.status == UdhaarStatus.settled;
    final isGive = udhaar.direction == UdhaarDirection.give;
    final isOverdue = !isSettled && DateFormatter.isOverdue(udhaar.dueDate);
    final daysLeft = DateFormatter.daysRemaining(udhaar.dueDate);

    // Direction color: Give (we owe) = red/expense; Take (owed to us) = green/income
    final directionColor = isGive ? colors.expense : colors.income;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOverdue ? colors.expense.withValues(alpha: 0.6) : colors.border,
          width: isOverdue ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Person Name & Direction Badge
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: directionColor.withValues(alpha: 0.12),
                        child: Text(
                          udhaar.personName.isNotEmpty
                              ? udhaar.personName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: directionColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            udhaar.personName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                udhaar.direction.displayName,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: directionColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (walletName != null) ...[
                                Text(
                                  ' • $walletName',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Amount
                  Text(
                    CurrencyFormatter.format(udhaar.amount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSettled ? theme.textTheme.bodySmall?.color : null,
                      decoration: isSettled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
              if (udhaar.note != null && udhaar.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  udhaar.note!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Due Date Chip & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Due date chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSettled
                          ? colors.border.withValues(alpha: 0.4)
                          : isOverdue
                              ? colors.expense.withValues(alpha: 0.12)
                              : theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSettled
                              ? Icons.check_circle_outline
                              : isOverdue
                                  ? Icons.warning_amber_rounded
                                  : Icons.calendar_today_outlined,
                          size: 14,
                          color: isSettled
                              ? theme.textTheme.bodySmall?.color
                              : isOverdue
                                  ? colors.expense
                                  : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSettled
                              ? 'Settled'
                              : isOverdue
                                  ? 'Overdue (${DateFormatter.formatDateShort(udhaar.dueDate)})'
                                  : daysLeft == 0
                                      ? 'Due Today'
                                      : daysLeft == 1
                                          ? 'Due Tomorrow'
                                          : 'Due in $daysLeft days',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSettled
                                ? theme.textTheme.bodySmall?.color
                                : isOverdue
                                    ? colors.expense
                                    : theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isSettled && onSettle != null)
                        TextButton.icon(
                          onPressed: onSettle,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Settle'),
                        ),
                      if (onDelete != null)
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Delete',
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
