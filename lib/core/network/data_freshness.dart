// Tracks transit data origin (live, simulated, cached, stale) and freshness formatting.

import 'package:flutter/foundation.dart';

import '../../l10n/app_localizations.dart';

/// Indicates how current and trustworthy a piece of transit data is.
enum DataSourceKind {
  /// Real-time external transit feed.
  live,

  /// Deterministic local Marprom fleet simulator.
  simulated,

  /// Locally cached offline schedule or snapshot.
  cached,

  /// Cached data whose age exceeds the freshness threshold.
  stale,
}

/// Describes when and from where a transit dataset was obtained.
@immutable
class DataFreshness {
  /// Creates a [DataFreshness] metadata record.
  const DataFreshness({
    required this.kind,
    required this.updatedAt,
  });

  /// Data origin category.
  final DataSourceKind kind;

  /// Timestamp of the last refresh or simulation tick.
  final DateTime updatedAt;

  /// Returns a localized user-facing label describing [kind].
  String localizedLabel(AppLocalizations l10n) {
    switch (kind) {
      case DataSourceKind.live:
        return l10n.freshnessLive;
      case DataSourceKind.simulated:
        return l10n.freshnessSimulated;
      case DataSourceKind.cached:
        return l10n.freshnessCached;
      case DataSourceKind.stale:
        return l10n.freshnessStale;
    }
  }

  /// Formats how long ago [updatedAt] occurred relative to [now].
  String formattedAge(AppLocalizations l10n, DateTime now) {
    final diff = now.difference(updatedAt);
    if (diff.inSeconds < 45) {
      return l10n.commonJustNow;
    }
    if (diff.inMinutes < 60) {
      return l10n.commonUpdatedAgo(l10n.commonMinutesShort(diff.inMinutes));
    }
    final hours = diff.inHours;
    return l10n.commonUpdatedAgo(l10n.commonHoursShort(hours));
  }
}
