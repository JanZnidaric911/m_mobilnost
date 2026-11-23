// Renders bus occupancy using color, localized text, and distinct fill patterns.

import 'package:flutter/material.dart';

import '../accessibility/semantics_helpers.dart';
import '../theme/colors.dart';

/// Bus crowding levels communicated via color, pattern, and label.
enum BusOccupancyLevel {
  /// Many free seats available.
  low,

  /// Moderate passenger load.
  medium,

  /// Standing room only / crowded.
  high,

  /// Vehicle at full capacity.
  full,

  /// Occupancy telemetry unavailable.
  unknown,
}

/// Multi-modal occupancy indicator combining color, pattern, and text label.
class OccupancyStrip extends StatelessWidget {
  /// Creates an [OccupancyStrip] for [level].
  const OccupancyStrip({
    super.key,
    required this.level,
    this.compact = false,
  });

  /// Crowding level to visualize.
  final BusOccupancyLevel level;

  /// Uses a tighter inline layout when true.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusColors =
        Theme.of(context).extension<MarpromStatusColors>() ??
            MarpromStatusColors.light;
    final scheme = Theme.of(context).colorScheme;

    final (label, color, segments, icon) = switch (level) {
      BusOccupancyLevel.low => (
          l10n.occupancyLow,
          statusColors.occupancyLow,
          1,
          Icons.airline_seat_recline_normal_rounded,
        ),
      BusOccupancyLevel.medium => (
          l10n.occupancyMedium,
          statusColors.occupancyMedium,
          2,
          Icons.groups_2_outlined,
        ),
      BusOccupancyLevel.high => (
          l10n.occupancyHigh,
          statusColors.occupancyHigh,
          3,
          Icons.groups_rounded,
        ),
      BusOccupancyLevel.full => (
          l10n.occupancyFull,
          statusColors.occupancyFull,
          4,
          Icons.no_accounts_outlined,
        ),
      BusOccupancyLevel.unknown => (
          l10n.occupancyUnknown,
          scheme.onSurfaceVariant,
          0,
          Icons.help_outline_rounded,
        ),
    };

    return Semantics(
      label: l10n.a11yOccupancyBar(label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 16 : 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: compact ? 8 : 10,
            child: Row(
              children: List.generate(4, (index) {
                final active = index < segments;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index < 3 ? 4 : 0),
                    child: CustomPaint(
                      painter: _PatternSegmentPainter(
                        active: active,
                        level: level,
                        color: color,
                        inactiveColor: scheme.outlineVariant,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternSegmentPainter extends CustomPainter {
  const _PatternSegmentPainter({
    required this.active,
    required this.level,
    required this.color,
    required this.inactiveColor,
  });

  final bool active;
  final BusOccupancyLevel level;
  final Color color;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = active ? color : inactiveColor;

    if (!active) {
      final bgPaint = Paint()..color = inactiveColor.withValues(alpha: 0.25);
      canvas.drawRRect(rrect, bgPaint);
      canvas.drawRRect(rrect, borderPaint);
      return;
    }

    canvas.save();
    canvas.clipRRect(rrect);

    final fillPaint = Paint()..color = color.withValues(alpha: 0.22);
    canvas.drawRect(rect, fillPaint);

    final patternPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    switch (level) {
      case BusOccupancyLevel.low:
        // Solid low-density fill with clean outline.
        canvas.drawRect(rect, Paint()..color = color);
      case BusOccupancyLevel.medium:
        // Diagonal stripes for color-blind distinction.
        for (double x = -size.height; x < size.width + size.height; x += 6) {
          canvas.drawLine(
            Offset(x, size.height),
            Offset(x + size.height, 0),
            patternPaint,
          );
        }
      case BusOccupancyLevel.high:
        // Cross-hatched stripes for crowded state.
        for (double x = -size.height; x < size.width + size.height; x += 5) {
          canvas.drawLine(
            Offset(x, size.height),
            Offset(x + size.height, 0),
            patternPaint,
          );
          canvas.drawLine(
            Offset(x, 0),
            Offset(x + size.height, size.height),
            patternPaint,
          );
        }
      case BusOccupancyLevel.full:
        // Dense vertical bars + full fill border.
        canvas.drawRect(rect, Paint()..color = color);
      case BusOccupancyLevel.unknown:
        break;
    }
    canvas.restore();
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _PatternSegmentPainter oldDelegate) {
    return oldDelegate.active != active ||
        oldDelegate.level != level ||
        oldDelegate.color != color;
  }
}
