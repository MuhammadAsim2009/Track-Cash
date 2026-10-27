import 'package:flutter/material.dart';

/// Semantic colors for TrackCash design system from docs/design.md.
class AppColors {
  AppColors._();

  // Light theme colors
  static const Color primaryLight = Color(0xFF059669);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color incomeLight = Color(0xFF16A34A);
  static const Color expenseLight = Color(0xFFDC2626);
  static const Color warningLight = Color(0xFFD97706);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Dark theme colors
  static const Color primaryDark = Color(0xFF34D399);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color incomeDark = Color(0xFF4ADE80);
  static const Color expenseDark = Color(0xFFF87171);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color borderDark = Color(0xFF334155);
}

/// Custom ThemeExtension providing custom semantic colors
/// (income, expense, warning, border) to any context.
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.income,
    required this.expense,
    required this.warning,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Color income;
  final Color expense;
  final Color warning;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  static const light = AppColorsExtension(
    income: AppColors.incomeLight,
    expense: AppColors.expenseLight,
    warning: AppColors.warningLight,
    border: AppColors.borderLight,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
  );

  static const dark = AppColorsExtension(
    income: AppColors.incomeDark,
    expense: AppColors.expenseDark,
    warning: AppColors.warningDark,
    border: AppColors.borderDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
  );

  @override
  AppColorsExtension copyWith({
    Color? income,
    Color? expense,
    Color? warning,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
  }) {
    return AppColorsExtension(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      income: Color.lerp(income, other.income, t) ?? income,
      expense: Color.lerp(expense, other.expense, t) ?? expense,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      border: Color.lerp(border, other.border, t) ?? border,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
    );
  }
}

/// Handy extension on [BuildContext] to retrieve custom app colors.
extension AppColorsX on BuildContext {
  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.light;
}
