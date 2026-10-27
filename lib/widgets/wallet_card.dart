import 'package:flutter/material.dart';
import '../core/utils/currency_formatter.dart';
import '../data/models/wallet.dart';

/// Card component displaying a Wallet's icon, name, and current balance.
class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.wallet,
    required this.balance,
    this.onTap,
    this.isSelected = false,
    this.onToggleDailyExpense,
  });

  final Wallet wallet;
  final int balance;
  final VoidCallback? onTap;
  final bool isSelected;
  final ValueChanged<bool>? onToggleDailyExpense;

  IconData _getWalletIcon(WalletType type) {
    return switch (type) {
      WalletType.cash => Icons.payments_outlined,
      WalletType.savings => Icons.account_balance_outlined,
      WalletType.mobileWallet => Icons.phone_android_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = _getWalletIcon(wallet.type);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.cardTheme.shape is RoundedRectangleBorder
                  ? (theme.cardTheme.shape as RoundedRectangleBorder).side.color
                  : theme.colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      iconData,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (wallet.type == WalletType.savings && onToggleDailyExpense != null)
                    GestureDetector(
                      onTap: () => onToggleDailyExpense!(!wallet.countInDailyExpense),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        height: 32, // Match icon container height (7+18+7)
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: wallet.countInDailyExpense
                                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: wallet.countInDailyExpense
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Daily',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: wallet.countInDailyExpense
                                      ? theme.colorScheme.primary
                                      : theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              const SizedBox(width: 2),
                              // Switch is visual-only; tap handled by outer GestureDetector
                              IgnorePointer(
                                child: Transform.scale(
                                  scale: 0.65,
                                  child: Switch.adaptive(
                                    value: wallet.countInDailyExpense,
                                    onChanged: (_) {},
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (isSelected)
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: theme.textTheme.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(balance),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (wallet.type == WalletType.savings) ...[
                    const SizedBox(height: 1),
                    Text(
                      wallet.countInDailyExpense ? 'In daily expense' : 'Not in daily expense',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
                        color: wallet.countInDailyExpense
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
