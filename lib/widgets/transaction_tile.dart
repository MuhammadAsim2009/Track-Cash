import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/icon_resolver.dart';
import '../data/models/category.dart';
import '../data/models/transaction_entry.dart';
import '../data/models/wallet.dart';

/// Tile component for an income or expense transaction item.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    this.wallet,
    this.onTap,
    this.onLongPress,
  });

  final TransactionEntry transaction;
  final AppCategory? category;
  final Wallet? wallet;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome ? colors.income : colors.expense;

    final catIcon = category != null
        ? IconResolver.getIcon(category!.icon)
        : (isIncome ? Icons.arrow_downward : Icons.arrow_upward);

    final catColor = category != null ? Color(category!.color) : amountColor;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            // Category Icon Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                catIcon,
                color: catColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Category name, note, wallet
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? (isIncome ? 'Income' : 'Expense'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (wallet != null) ...[
                        Flexible(
                          child: Text(
                            wallet!.name,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text(' • '),
                      ],
                      Flexible(
                        child: Text(
                          DateFormatter.formatDateShort(transaction.date),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (transaction.note != null &&
                      transaction.note!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Amount formatted with +/- sign
            Text(
              CurrencyFormatter.formatSigned(
                transaction.amount,
                isIncome: isIncome,
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
