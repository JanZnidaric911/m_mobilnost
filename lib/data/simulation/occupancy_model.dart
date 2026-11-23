// Deterministic per-segment bus occupancy model based on time of day, line, and hubs.

import 'dart:math' as math;

import '../models/occupancy.dart';

/// Estimates per-segment crowding levels for simulated Marprom routes.
///
/// NOTE: In production, real Automatic Passenger Counting (APC) / door sensor
/// telemetry from Marprom vehicles will feed [SegmentOccupancy] instead of this
/// deterministic heuristic model.
class OccupancyModel {
  /// Creates an [OccupancyModel] controlled by [seed].
  const OccupancyModel({this.seed = 42});

  /// Seed used for deterministic occupancy variation.
  final int seed;

  static const Set<String> _trunkLines = {'1', '2', '3', '6', '21'};
  static const Set<String> _centralHubStops = {
    'glavni_trg',
    'glavna_postaja',
    'europark',
    'ukc_maribor',
    'univerza',
    'tabor',
  };

  /// Estimates [SegmentOccupancy] between [fromStopId] and [toStopId] at [at].
  SegmentOccupancy estimateSegment({
    required String lineId,
    required String directionId,
    required String fromStopId,
    required String toStopId,
    required DateTime at,
  }) {
    final minuteOfDay = at.hour * 60 + at.minute;
    final isWeekday = at.weekday <= DateTime.friday;

    // Base demand curve reflecting school start/end and Maribor work commute peaks.
    int baseLoad;
    if (isWeekday &&
        ((minuteOfDay >= 7 * 60 + 10 && minuteOfDay <= 8 * 60 + 35) ||
            (minuteOfDay >= 13 * 60 + 30 && minuteOfDay <= 16 * 60 + 45))) {
      baseLoad = 68; // School and commuter rush hours.
    } else if (minuteOfDay >= 9 * 60 && minuteOfDay <= 19 * 60 + 30) {
      baseLoad = isWeekday ? 42 : 32; // Daytime shopping and midday errands.
    } else {
      baseLoad = 18; // Early morning or late evening quiet periods.
    }

    // Trunk routes and central transfer corridors attract higher ridership.
    final lineAdjustment = _trunkLines.contains(lineId) ? 12 : -4;
    final hubAdjustment = (_centralHubStops.contains(fromStopId) ||
            _centralHubStops.contains(toStopId))
        ? 10
        : -5;

    final hourBucket = '${at.year}-${at.month}-${at.day}-${at.hour}';
    final rng = math.Random(
      _stableHash('$seed|$lineId|$directionId|$fromStopId|$toStopId|$hourBucket'),
    );
    final jitter = rng.nextInt(21) - 8; // -8..+12%

    final loadPercent = (baseLoad + lineAdjustment + hubAdjustment + jitter)
        .clamp(5, 98);

    return SegmentOccupancy(
      lineId: lineId,
      directionId: directionId,
      fromStopId: fromStopId,
      toStopId: toStopId,
      level: levelFromLoadPercent(loadPercent),
      loadPercent: loadPercent,
    );
  }

  /// Maps numeric [loadPercent] (0..100) to a semantic [BusOccupancyLevel].
  static BusOccupancyLevel levelFromLoadPercent(int loadPercent) {
    if (loadPercent < 35) return BusOccupancyLevel.low;
    if (loadPercent < 70) return BusOccupancyLevel.medium;
    if (loadPercent < 90) return BusOccupancyLevel.high;
    return BusOccupancyLevel.full;
  }

  static int _stableHash(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
