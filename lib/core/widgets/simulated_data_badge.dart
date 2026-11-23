// Displays a transparent indicator when simulated or cached transit data is shown.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accessibility/a11y_settings.dart';
import '../accessibility/semantics_helpers.dart';
import '../network/data_freshness.dart';
import '../theme/colors.dart';

/// Badge clarifying whether displayed live transit data is simulated or cached.
class SimulatedDataBadge extends ConsumerWidget {
  /// Creates a [SimulatedDataBadge] optionally overridden by [freshness].
  const SimulatedDataBadge({
    super.key,
    this.freshness,
    this.forceShow = false,
  });

  /// Explicit data freshness metadata to render.
  final DataFreshness? freshness;

  /// Shows the badge even when user settings hide source badges.
  final bool forceShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(a11ySettingsProvider);
    if (!forceShow && !settings.showDataSource) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final statusColors =
        Theme.of(context).extension<MarpromStatusColors>() ??
            MarpromStatusColors.light;

    final (icon, text, fg, bg, tooltip) = freshness != null
        ? switch (freshness!.kind) {
            DataSourceKind.live => (
                Icons.sensors_rounded,
                l10n.freshnessLive,
                statusColors.onTimeFg,
                statusColors.onTimeBg,
                l10n.freshnessLive,
              ),
            DataSourceKind.simulated => (
                Icons.science_outlined,
                l10n.badgeSimulatedLabel,
                statusColors.infoFg,
                statusColors.infoBg,
                l10n.badgeSimulatedTooltip,
              ),
            DataSourceKind.cached => (
                Icons.offline_pin_outlined,
                l10n.freshnessCached,
                statusColors.warningFg,
                statusColors.warningBg,
                l10n.freshnessCached,
              ),
            DataSourceKind.stale => (
                Icons.schedule_outlined,
                l10n.freshnessStale,
                statusColors.lateFg,
                statusColors.lateBg,
                l10n.freshnessStale,
              ),
          }
        : settings.useSimulatedLive
            ? (
                Icons.science_outlined,
                l10n.badgeSimulatedLabel,
                statusColors.infoFg,
                statusColors.infoBg,
                l10n.badgeSimulatedTooltip,
              )
            : (
                Icons.offline_pin_outlined,
                l10n.freshnessLiveDisabledFallback,
                statusColors.warningFg,
                statusColors.warningBg,
                l10n.freshnessLiveDisabledFallback,
              );

    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: '${l10n.a11ySimulatedBadge}: $text',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: fg.withValues(
                alpha: statusColors.highContrastBorders ? 1.0 : 0.35,
              ),
              width: statusColors.highContrastBorders ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
