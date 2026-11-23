// Defines responsive layout breakpoints for compact, medium, and expanded screens.

/// Responsive layout width categories for adaptive shells and grids.
enum ScreenLayoutSize {
  /// Narrow phone layouts under 600dp.
  compact,

  /// Tablet or small desktop layouts from 600dp through 1024dp.
  medium,

  /// Wide desktop layouts above 1024dp.
  expanded,
}

/// Breakpoint thresholds and sizing helpers for responsive UI.
abstract final class LayoutBreakpoints {
  /// Upper bound (exclusive) for compact layouts.
  static const double compactMaxWidth = 600.0;

  /// Upper bound (inclusive) for medium layouts.
  static const double mediumMaxWidth = 1024.0;

  /// Returns the [ScreenLayoutSize] matching [width].
  static ScreenLayoutSize fromWidth(double width) {
    if (width < compactMaxWidth) return ScreenLayoutSize.compact;
    if (width <= mediumMaxWidth) return ScreenLayoutSize.medium;
    return ScreenLayoutSize.expanded;
  }

  /// Returns true when [width] falls in the compact phone tier (< 600dp).
  static bool isCompact(double width) => width < compactMaxWidth;

  /// Returns true when [width] falls in the medium tier (600–1024dp).
  static bool isMedium(double width) =>
      width >= compactMaxWidth && width <= mediumMaxWidth;

  /// Returns true when [width] falls in the expanded tier (> 1024dp).
  static bool isExpanded(double width) => width > mediumMaxWidth;

  /// Recommended maximum readable content width for [size].
  static double maxContentWidth(ScreenLayoutSize size) {
    switch (size) {
      case ScreenLayoutSize.compact:
        return double.infinity;
      case ScreenLayoutSize.medium:
        return 760.0;
      case ScreenLayoutSize.expanded:
        return 1120.0;
    }
  }
}
