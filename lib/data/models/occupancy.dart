// Re-exports BusOccupancyLevel from core and defines per-segment occupancy data.

import 'package:flutter/foundation.dart';
import 'package:m_mobilnost/core/widgets/occupancy_strip.dart';

export 'package:m_mobilnost/core/widgets/occupancy_strip.dart'
    show BusOccupancyLevel;

/// Crowding level and estimated load percentage for one route segment.
@immutable
class SegmentOccupancy {
  /// Creates a [SegmentOccupancy] snapshot between [fromStopId] and [toStopId].
  const SegmentOccupancy({
    required this.lineId,
    required this.directionId,
    required this.fromStopId,
    required this.toStopId,
    required this.level,
    required this.loadPercent,
  });

  /// Line identifier for this segment.
  final String lineId;

  /// Direction identifier on the line.
  final String directionId;

  /// Boarding stop ID at the start of the segment.
  final String fromStopId;

  /// Alighting stop ID at the end of the segment.
  final String toStopId;

  /// Discrete semantic occupancy level reused across UI widgets.
  final BusOccupancyLevel level;

  /// Estimated vehicle load percentage from 0 to 100.
  final int loadPercent;
}
