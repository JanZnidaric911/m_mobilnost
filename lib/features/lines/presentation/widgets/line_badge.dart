// Reusable accessible transit badges, stop amenity chips, and departure rows.

import 'package:flutter/material.dart';
import 'package:m_mobilnost/core/accessibility/semantics_helpers.dart';
import 'package:m_mobilnost/core/theme/colors.dart';
import 'package:m_mobilnost/core/utils/time_format.dart';
import 'package:m_mobilnost/core/widgets/occupancy_strip.dart';
import 'package:m_mobilnost/core/widgets/simulated_data_badge.dart';
import 'package:m_mobilnost/core/widgets/status_chip.dart';
import 'package:m_mobilnost/data/models/bus_stop.dart';
import 'package:m_mobilnost/data/models/departure.dart';
import 'package:m_mobilnost/l10n/app_localizations.dart';

import '../../data/transit_providers.dart';

/// Accessible line badge combining line color, bus icon, and line number text.
class LineBadge extends StatelessWidget {
  /// Creates a [LineBadge] that never relies on color alone.
  const LineBadge({
    super.key,
    required this.code,
    required this.color,
    this.showLineWord = false,
    this.compact = false,
  });

  /// Short line code (for example `1` or `6`).
  final String code;

  /// Brand color assigned to the line.
  final Color color;

  /// Whether to render `Line 6` instead of just `6`.
  final bool showLineWord;

  /// Uses slightly tighter padding inside dense lists or map overlays.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusColors =
        Theme.of(context).extension<MarpromStatusColors>() ??
            MarpromStatusColors.light;
    final isHighContrast = statusColors.highContrastBorders;
    final bgColor = isHighContrast ? MarpromColors.hcBlack : color;
    final fgColor = isHighContrast
        ? MarpromColors.hcYellow
        : ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black;
    final borderColor = isHighContrast
        ? MarpromColors.hcYellow
        : fgColor.withValues(alpha: 0.3);

    final displayText = showLineWord ? l10n.linesBadge(code) : code;

    return Semantics(
      label: l10n.a11yLineBadge(code),
      child: Container(
        constraints: BoxConstraints(
          minWidth: compact ? 44 : 52,
          minHeight: compact ? 32 : 36,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: isHighContrast ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus_rounded,
              size: compact ? 16 : 18,
              color: fgColor,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                displayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders stop accessibility and comfort amenities using icons and localized labels.
class BusStopAmenitiesWrap extends StatelessWidget {
  /// Creates a [BusStopAmenitiesWrap] for [stop].
  const BusStopAmenitiesWrap({
    super.key,
    required this.stop,
    this.compact = false,
  });

  /// Bus stop whose amenities are displayed.
  final BusStop stop;

  /// Reduces chip padding for bottom sheets and compact list rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <(IconData, String)>[
      if (stop.isStepFree)
        (Icons.accessible_rounded, l10n.stopAmenityStepFree),
      if (stop.hasTactile) (Icons.blind_rounded, l10n.stopAmenityTactile),
      if (stop.hasDigitalDisplay)
        (Icons.tv_rounded, l10n.stopAmenityDisplay),
      if (stop.hasShelter) (Icons.roofing_rounded, l10n.stopAmenityShelter),
      if (stop.hasBench) (Icons.chair_alt_rounded, l10n.stopAmenityBench),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (icon, label) in items)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Mobile-friendly departure row safe up to 200% text scaling.
class DepartureTileCard extends StatelessWidget {
  /// Creates a [DepartureTileCard] displaying live/scheduled departure details.
  const DepartureTileCard({
    super.key,
    required this.departure,
    required this.now,
    this.lineColor,
    this.showLineBadge = true,
    this.showRelativeCountdown = true,
    this.onTap,
  });

  /// Departure record to render.
  final Departure departure;

  /// Reference current timestamp for countdown labels.
  final DateTime now;

  /// Optional line brand color for [LineBadge].
  final Color? lineColor;

  /// Whether to include the line badge on the row.
  final bool showLineBadge;

  /// Whether to display `Departs in X min` / `Arriving now`.
  final bool showRelativeCountdown;

  /// Optional tap callback (for example to follow on tracker).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final estTimeStr = TimeFormatUtils.formatTime24(departure.estimatedTime);
    final schedTimeStr = TimeFormatUtils.formatTime24(departure.scheduledTime);
    final statusLabel = localizedDelayStatusLabel(
      l10n,
      departure.status,
      departure.delaySeconds,
      isCancelled: departure.isCancelled,
    );
    final hasDelayShift = departure.delaySeconds.abs() > 60;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (showLineBadge)
                      LineBadge(
                        code: departure.lineCode,
                        color: lineColor ?? scheme.primary,
                        compact: true,
                      ),
                    Text(
                      estTimeStr,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            decoration: departure.isCancelled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    if (showRelativeCountdown && !departure.isCancelled)
                      Text(
                        localizedCountdownLabel(
                          l10n,
                          departure.estimatedTime,
                          now,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.primary,
                            ),
                      ),
                    StatusChip(
                      type: departure.status,
                      label: statusLabel,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.linesDirectionTo(departure.directionName),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (hasDelayShift) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.trackerScheduledTime(schedTimeStr),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (departure.occupancy != BusOccupancyLevel.unknown) ...[
                  const SizedBox(height: 10),
                  OccupancyStrip(level: departure.occupancy, compact: true),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Transparent status header showing source badge, last updated time, and fallback note.
class TransitFreshnessHeader extends StatelessWidget {
  /// Creates a [TransitFreshnessHeader] for live/static schedule transparency.
  const TransitFreshnessHeader({
    super.key,
    required this.useSimulatedLive,
    required this.updatedAt,
    this.showSimulatedBadge = true,
  });

  /// Whether simulated live telemetry is active.
  final bool useSimulatedLive;

  /// Timestamp of the displayed snapshot.
  final DateTime updatedAt;

  /// Whether to render [SimulatedDataBadge] alongside the timestamp.
  final bool showSimulatedBadge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusColors =
        Theme.of(context).extension<MarpromStatusColors>() ??
            MarpromStatusColors.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (showSimulatedBadge) const SimulatedDataBadge(),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.commonLastUpdatedAt(formatTime24Hms(updatedAt)),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        if (!useSimulatedLive) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: statusColors.warningBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: statusColors.warningFg,
                width: statusColors.highContrastBorders ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: statusColors.warningFg,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.freshnessLiveDisabledFallback,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: statusColors.warningFg,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Returns a readable text summary for a [AppLocalizations] error or empty fallback.
String localizedFallbackTitle(AppLocalizations l10n) => l10n.commonEmpty;
