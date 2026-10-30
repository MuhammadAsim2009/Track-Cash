import 'package:flutter/material.dart';

enum ToastType {
  info,
  success,
  error,
  warning,
}

/// Modern floating toast helper for Track Cash.
class AppToast {
  AppToast._();

  /// Shows a modern, floating, rounded toast pill with an icon.
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(milliseconds: 2500),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final (Color bg, Color fg, Color border, IconData icon) = switch (type) {
      ToastType.success => isDark
          ? (
              const Color(0xFF064E3B),
              const Color(0xFF6EE7B7),
              const Color(0xFF059669).withValues(alpha: 0.4),
              Icons.check_circle_rounded,
            )
          : (
              const Color(0xFFECFDF5),
              const Color(0xFF065F46),
              const Color(0xFF34D399).withValues(alpha: 0.5),
              Icons.check_circle_rounded,
            ),
      ToastType.error => isDark
          ? (
              const Color(0xFF450A0A),
              const Color(0xFFFCA5A5),
              const Color(0xFFDC2626).withValues(alpha: 0.4),
              Icons.error_outline_rounded,
            )
          : (
              const Color(0xFFFEF2F2),
              const Color(0xFF991B1B),
              const Color(0xFFF87171).withValues(alpha: 0.5),
              Icons.error_outline_rounded,
            ),
      ToastType.warning => isDark
          ? (
              const Color(0xFF451A03),
              const Color(0xFFFCD34D),
              const Color(0xFFD97706).withValues(alpha: 0.4),
              Icons.warning_amber_rounded,
            )
          : (
              const Color(0xFFFFFBEB),
              const Color(0xFF92400E),
              const Color(0xFFFBBF24).withValues(alpha: 0.5),
              Icons.warning_amber_rounded,
            ),
      ToastType.info => isDark
          ? (
              const Color(0xFF1E293B),
              const Color(0xFFF1F5F9),
              const Color(0xFF334155),
              Icons.info_outline_rounded,
            )
          : (
              const Color(0xFF0F172A),
              Colors.white,
              Colors.transparent,
              Icons.info_outline_rounded,
            ),
    };

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        duration: duration,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: fg, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    action.onPressed();
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: fg,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    action.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message, type: ToastType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message, type: ToastType.error);
  }

  static void warning(BuildContext context, String message) {
    show(context, message, type: ToastType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message, type: ToastType.info);
  }
}

