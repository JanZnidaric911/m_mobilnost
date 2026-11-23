// Accessible transit status chip pairing icon, localized text, and semantic color.

import 'package:flutter/material.dart';

import '../accessibility/semantics_helpers.dart';
import '../theme/colors.dart';

/// Semantic transit status states supported by [StatusChip].
enum TransitStatusType {
  /// Vehicle running ahead of timetable.
  early,

  /// Vehicle running on schedule.
  onTime,

  /// Vehicle delayed behind schedule.
  late,

  /// General informational notice.
  info,

  /// Caution or tight-transfer warning.
  warning,

  /// Route disruption, detour, or cancellation.
  disruption,
}

/// Pill chip communicating transit status via icon, text, and WCAG-compliant color.
class StatusChip extends StatelessWidget {
  /// Creates a [StatusChip] for [type] with an optional localized [label].
  const StatusChip({
    super.key,
    required this.type,
    this.label,
    this.compact = false,
  });

  /// Semantic status category.
  final TransitStatusType type;

  /// Optional custom localized label; defaults to the standard status string.
  final String? label;

  /// Uses slightly tighter padding for dense timetable rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusColors =
        Theme.of(context).extension<MarpromStatusColors>() ??
            MarpromStatusColors.light;

    final (fg, bg, icon, defaultText) = switch (type) {
      TransitStatusType.early => (
          statusColors.earlyFg,
          statusColors.earlyBg,
          Icons.fast_forward_rounded,
          l10n.statusEarly,
        ),
      TransitStatusType.onTime => (
          statusColors.onTimeFg,
          statusColors.onTimeBg,
          Icons.check_circle_outline_rounded,
          l10n.statusOnTime,
        ),
      TransitStatusType.late => (
          statusColors.lateFg,
          statusColors.lateBg,
          Icons.schedule_rounded,
          l10n.statusLate,
        ),
      TransitStatusType.info => (
          statusColors.infoFg,
          statusColors.infoBg,
          Icons.info_outline_rounded,
          l10n.statusInfo,
        ),
      TransitStatusType.warning => (
          statusColors.warningFg,
          statusColors.warningBg,
          Icons.warning_amber_rounded,
          l10n.statusWarning,
        ),
      TransitStatusType.disruption => (
          statusColors.disruptionFg,
          statusColors.disruptionBg,
          Icons.report_problem_outlined,
          l10n.statusDisruption,
        ),
    };

    final text = label ?? defaultText;

    return Semantics(
      label: l10n.a11yStatusChip(text),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 6,
        ),
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
            Icon(icon, size: compact ? 15 : 17, color: fg),
            const SizedBox(width: 6),
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
    );
  }
}
