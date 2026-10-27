import 'package:flutter/material.dart';

/// Standard bottom padding constant and wrapper widget for tab screens
/// ensuring content and the last list item are never obscured behind the floating navigation bar.
///
/// The floating nav bar sits at: 12px bottom margin + safe area + bar height (80px).
/// We add a small extra gap (8px) so the last item isn't flush against the bar.
class TabScreenWrapper extends StatelessWidget {
  const TabScreenWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  /// The visual height occupied by the floating navigation bar + its margins.
  /// bar total height (80) + bottom margin (12) + extra breathing room (8) = 100px.
  static const double _navBarTotal = 100.0;

  /// Returns the required bottom inset in logical pixels.
  /// This is the nav bar height plus the system safe area inset (gesture bar / home indicator).
  static double bottomPadding(BuildContext context) {
    // viewPadding gives the OS-level insets even inside Scaffolds with extendBody.
    return _navBarTotal + MediaQuery.viewPaddingOf(context).bottom;
  }

  /// Returns an EdgeInsets based on [base] with the correct bottom inset applied.
  static EdgeInsets padding(BuildContext context, [EdgeInsets base = EdgeInsets.zero]) {
    return base.copyWith(
      bottom: base.bottom + bottomPadding(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pass child through without a wrapping Padding; individual screens use
    // TabScreenWrapper.padding() / TabScreenWrapper.bottomPadding() on their
    // own scroll views / list views so the insets are always correct.
    return child;
  }
}
