import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Custom floating notched bottom navigation bar.
///
/// Features:
/// - 4 tabs: Home, Transactions, Budget, Udhaar (2 left, 2 right)
/// - Center 56px round primary green "+" button sitting in a smooth cubic curved notch
/// - Smooth 200ms selection animations
/// - Light mode: soft elevation shadow on white surface
/// - Dark mode: #1E293B surface with subtle #334155 1px border
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onAddPressed,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;

  static const double barHeight = 64.0;
  static const double topProtrusion = 16.0;
  static const double totalHeight = barHeight + topProtrusion; // 80.0
  static const double buttonSize = 56.0;
  static const double cornerRadius = 28.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = colors.border;

    return SizedBox(
      height: totalHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final centerX = width / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Notched Bar Canvas (Cubic bezier curve dip + rounded corners)
              Positioned.fill(
                child: CustomPaint(
                  painter: _NotchedBarPainter(
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    isDark: isDark,
                    topOffset: topProtrusion,
                    cornerRadius: cornerRadius,
                  ),
                ),
              ),

              // 2. Tabs Row
              Positioned(
                top: topProtrusion,
                left: 0,
                right: 0,
                height: barHeight,
                child: Row(
                  children: [
                    // Tab 0: Home
                    Expanded(
                      child: _NavBarItem(
                        icon: Icons.dashboard_outlined,
                        selectedIcon: Icons.dashboard_rounded,
                        label: 'Home',
                        isSelected: selectedIndex == 0,
                        onTap: () => onTabSelected(0),
                      ),
                    ),
                    // Tab 1: Transactions
                    Expanded(
                      child: _NavBarItem(
                        icon: Icons.receipt_long_outlined,
                        selectedIcon: Icons.receipt_long_rounded,
                        label: 'Transactions',
                        isSelected: selectedIndex == 1,
                        onTap: () => onTabSelected(1),
                      ),
                    ),

                    // Center gap for notch & + button
                    const SizedBox(width: 76),

                    // Tab 2: Budget
                    Expanded(
                      child: _NavBarItem(
                        icon: Icons.pie_chart_outline_rounded,
                        selectedIcon: Icons.pie_chart_rounded,
                        label: 'Budget',
                        isSelected: selectedIndex == 2,
                        onTap: () => onTabSelected(2),
                      ),
                    ),
                    // Tab 3: Udhaar
                    Expanded(
                      child: _NavBarItem(
                        icon: Icons.handshake_outlined,
                        selectedIcon: Icons.handshake_rounded,
                        label: 'Udhaar',
                        isSelected: selectedIndex == 3,
                        onTap: () => onTabSelected(3),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Center Floating "+" Button
              Positioned(
                top: 0,
                left: centerX - (buttonSize / 2),
                width: buttonSize,
                height: buttonSize,
                child: Semantics(
                  button: true,
                  label: 'Add Transaction',
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onAddPressed,
                        customBorder: const CircleBorder(),
                        splashColor: Colors.white.withValues(alpha: 0.2),
                        highlightColor: Colors.white.withValues(alpha: 0.1),
                        child: const Center(
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotchedBarPainter extends CustomPainter {
  const _NotchedBarPainter({
    required this.surfaceColor,
    required this.borderColor,
    required this.isDark,
    required this.topOffset,
    required this.cornerRadius,
  });

  final Color surfaceColor;
  final Color borderColor;
  final bool isDark;
  final double topOffset;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final top = topOffset;
    final bottom = h;
    final centerX = w / 2;

    // Notch dip parameters:
    // Button is 56x56 from y = 0 to y = 56.
    // Dip clears button bottom with gap (6px gap -> y = 62.0).
    const notchBottom = 62.0;
    const notchHalfWidth = 46.0;
    final notchLeft = centerX - notchHalfWidth;
    final notchRight = centerX + notchHalfWidth;

    final path = Path();
    // Start at top-left corner
    path.moveTo(cornerRadius, top);

    // Left horizontal segment
    path.lineTo(notchLeft, top);

    // Left cubic curve entering the notch dip smoothly
    path.cubicTo(
      centerX - 24.0,
      top,
      centerX - 26.0,
      notchBottom,
      centerX,
      notchBottom,
    );

    // Right cubic curve leaving the notch dip smoothly
    path.cubicTo(
      centerX + 26.0,
      notchBottom,
      centerX + 24.0,
      top,
      notchRight,
      top,
    );

    // Right horizontal segment to top-right corner
    path.lineTo(w - cornerRadius, top);
    path.arcToPoint(
      Offset(w, top + cornerRadius),
      radius: Radius.circular(cornerRadius),
    );

    // Right vertical edge
    path.lineTo(w, bottom - cornerRadius);
    path.arcToPoint(
      Offset(w - cornerRadius, bottom),
      radius: Radius.circular(cornerRadius),
    );

    // Bottom horizontal edge
    path.lineTo(cornerRadius, bottom);
    path.arcToPoint(
      Offset(0, bottom - cornerRadius),
      radius: Radius.circular(cornerRadius),
    );

    // Left vertical edge
    path.lineTo(0, top + cornerRadius);
    path.arcToPoint(
      Offset(cornerRadius, top),
      radius: Radius.circular(cornerRadius),
    );

    path.close();

    // Draw shadow in light mode
    if (!isDark) {
      canvas.drawShadow(
        path,
        Colors.black.withValues(alpha: 0.08),
        8.0,
        true,
      );
    }

    // Fill surface
    final fillPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw 1px border in dark mode
    if (isDark) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(_NotchedBarPainter old) =>
      old.surfaceColor != surfaceColor ||
      old.borderColor != borderColor ||
      old.isDark != isDark ||
      old.topOffset != topOffset ||
      old.cornerRadius != cornerRadius;
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    final activeColor = theme.colorScheme.primary;
    final inactiveColor = colors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  key: ValueKey<bool>(isSelected),
                  color: isSelected ? activeColor : inactiveColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: theme.textTheme.labelSmall!.copyWith(
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                  letterSpacing: -0.2,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
