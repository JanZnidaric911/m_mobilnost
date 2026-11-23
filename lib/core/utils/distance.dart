// Formats walking/transit distances and estimates walking durations.

import '../../l10n/app_localizations.dart';

/// Utilities for human-readable distance labels and walking estimates.
abstract final class DistanceUtils {
  /// Formats [meters] using localized meters (`< 1000 m`) or kilometers.
  static String formatMeters(double meters, AppLocalizations l10n) {
    final clamped = meters < 0 ? 0.0 : meters;
    if (clamped < 1000) {
      return l10n.commonMetersShort(clamped.round());
    }
    final km = (clamped / 1000.0).toStringAsFixed(1);
    return l10n.commonKilometersShort(km);
  }

  /// Estimates walking minutes for [meters] at [metersPerMinute] (default 75 m/min).
  static int estimateWalkMinutes(
    double meters, {
    double metersPerMinute = 75.0,
  }) {
    if (meters <= 0) return 0;
    final mins = (meters / metersPerMinute).ceil();
    return mins < 1 ? 1 : mins;
  }
}
