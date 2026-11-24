// Computes real-time Marprom fleet KPIs, passenger counts per line, and 24h ridership.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/maps/google_web_views.dart';
import '../../../core/widgets/occupancy_strip.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/bus_line.dart';
import '../../../data/models/bus_position.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/seed/seed_lines.dart';

/// Aggregated live passenger and punctuality telemetry for one Marprom bus line.
@immutable
class FleetLineStat {
  /// Creates a [FleetLineStat] snapshot for [line].
  const FleetLineStat({
    required this.line,
    required this.activeBuses,
    required this.totalPassengers,
    required this.totalCapacity,
    required this.averageLoadPercent,
    required this.averageDelaySeconds,
    required this.electricBuses,
  });

  /// Marprom bus line metadata.
  final BusLine line;

  /// Number of currently operating buses on this line.
  final int activeBuses;

  /// Total passengers currently riding across all active buses on [line].
  final int totalPassengers;

  /// Combined passenger capacity across active buses on [line].
  final int totalCapacity;

  /// Average occupancy percentage (`0..100`) on [line].
  final int averageLoadPercent;

  /// Mean schedule deviation in seconds across active buses on [line].
  final int averageDelaySeconds;

  /// Count of zero-emission electric buses currently active on [line].
  final int electricBuses;
}

/// Single hour point in Maribor's daily passenger ridership curve.
@immutable
class HourlyRidershipPoint {
  /// Creates an [HourlyRidershipPoint].
  const HourlyRidershipPoint({
    required this.hour,
    required this.riders,
  });

  /// Hour of day (`5..23`).
  final int hour;

  /// Estimated passenger count across the Marprom network during [hour].
  final int riders;
}

/// Citywide Marprom Maribor fleet and passenger statistics snapshot.
@immutable
class FleetStatistics {
  /// Creates a [FleetStatistics] aggregate.
  const FleetStatistics({
    required this.activeBusCount,
    required this.totalPassengers,
    required this.totalCapacity,
    required this.averageLoadPercent,
    required this.onTimeCount,
    required this.earlyCount,
    required this.lateCount,
    required this.onTimePercent,
    required this.electricBusCount,
    required this.electricSharePercent,
    required this.busiestLine,
    required this.lineStats,
    required this.crowdingBreakdown,
    required this.hourlyRidership,
    required this.updatedAt,
  });

  /// Number of buses currently active across all 19 Maribor lines.
  final int activeBusCount;

  /// Total passengers aboard Marprom buses right now.
  final int totalPassengers;

  /// Combined fleet capacity across active buses.
  final int totalCapacity;

  /// Fleet-wide average load percentage (`0..100`).
  final int averageLoadPercent;

  /// Active buses operating on schedule (`-60s..+120s`).
  final int onTimeCount;

  /// Active buses running ahead of schedule (`< -60s`).
  final int earlyCount;

  /// Active buses delayed (`> +120s`).
  final int lateCount;

  /// Percentage of active buses running on time or early.
  final int onTimePercent;

  /// Number of electric buses currently in service.
  final int electricBusCount;

  /// Share of active fleet that is battery-electric (`0..100`).
  final int electricSharePercent;

  /// Line carrying the highest total passenger load right now.
  final FleetLineStat? busiestLine;

  /// Per-line breakdown across all 19 Marprom lines (`G1-G6` & `P7-P19`).
  final List<FleetLineStat> lineStats;

  /// Counts of active buses grouped by [BusOccupancyLevel].
  final Map<BusOccupancyLevel, int> crowdingBreakdown;

  /// Daily 05:00–23:00 ridership demand profile anchored to current ridership.
  final List<HourlyRidershipPoint> hourlyRidership;

  /// Timestamp when this statistics snapshot was computed.
  final DateTime updatedAt;
}

/// Computes deterministic citywide [FleetStatistics] from [buses].
FleetStatistics computeFleetStatistics(
  List<BusPosition> buses, {
  DateTime? now,
}) {
  final timestamp = now ?? (buses.isNotEmpty ? buses.first.updatedAt : DateTime.now());
  var totalPassengers = 0;
  var totalCapacity = 0;
  var onTimeCount = 0;
  var earlyCount = 0;
  var lateCount = 0;
  var electricCount = 0;

  final crowding = <BusOccupancyLevel, int>{
    BusOccupancyLevel.low: 0,
    BusOccupancyLevel.medium: 0,
    BusOccupancyLevel.high: 0,
    BusOccupancyLevel.full: 0,
  };

  final byLine = <String, List<BusPosition>>{};
  for (final bus in buses) {
    totalPassengers += bus.passengerCount;
    totalCapacity += bus.vehicleCapacity;
    if (bus.isElectric) electricCount++;
    switch (bus.status) {
      case TransitStatusType.early:
        earlyCount++;
      case TransitStatusType.onTime:
        onTimeCount++;
      case TransitStatusType.late:
        lateCount++;
      case TransitStatusType.info:
      case TransitStatusType.warning:
      case TransitStatusType.disruption:
        break;
    }
    crowding[bus.occupancy] = (crowding[bus.occupancy] ?? 0) + 1;
    byLine.putIfAbsent(bus.lineId, () => <BusPosition>[]).add(bus);
  }

  final lineStats = <FleetLineStat>[];
  for (final line in seedLines) {
    final lineBuses = byLine[line.id] ?? const <BusPosition>[];
    if (lineBuses.isEmpty) {
      lineStats.add(
        FleetLineStat(
          line: line,
          activeBuses: 0,
          totalPassengers: 0,
          totalCapacity: 0,
          averageLoadPercent: 0,
          averageDelaySeconds: 0,
          electricBuses: 0,
        ),
      );
      continue;
    }
    var linePax = 0;
    var lineCap = 0;
    var lineDelay = 0;
    var lineElectric = 0;
    for (final bus in lineBuses) {
      linePax += bus.passengerCount;
      lineCap += bus.vehicleCapacity;
      lineDelay += bus.delaySeconds;
      if (bus.isElectric) lineElectric++;
    }
    lineStats.add(
      FleetLineStat(
        line: line,
        activeBuses: lineBuses.length,
        totalPassengers: linePax,
        totalCapacity: lineCap,
        averageLoadPercent:
            lineCap > 0 ? ((linePax / lineCap) * 100).round().clamp(0, 100) : 0,
        averageDelaySeconds: (lineDelay / lineBuses.length).round(),
        electricBuses: lineElectric,
      ),
    );
  }

  FleetLineStat? busiest;
  for (final stat in lineStats) {
    if (stat.activeBuses == 0) continue;
    if (busiest == null || stat.totalPassengers > busiest.totalPassengers) {
      busiest = stat;
    }
  }

  final avgLoad = totalCapacity > 0
      ? ((totalPassengers / totalCapacity) * 100).round().clamp(0, 100)
      : 0;
  final onTimeShare = buses.isNotEmpty
      ? (((onTimeCount + earlyCount) / buses.length) * 100).round().clamp(0, 100)
      : 100;
  final electricShare = buses.isNotEmpty
      ? ((electricCount / buses.length) * 100).round().clamp(0, 100)
      : 0;

  // Build 05:00-23:00 Maribor hourly ridership curve (reflecting school/work peaks).
  const hourlyWeights = <int, double>{
    5: 0.28,
    6: 0.56,
    7: 0.98,
    8: 0.92,
    9: 0.62,
    10: 0.54,
    11: 0.58,
    12: 0.68,
    13: 0.84,
    14: 0.95,
    15: 1.00,
    16: 0.91,
    17: 0.76,
    18: 0.60,
    19: 0.46,
    20: 0.34,
    21: 0.26,
    22: 0.19,
    23: 0.12,
  };
  final isWeekend = timestamp.weekday >= DateTime.saturday;
  final dayScale = isWeekend ? 0.58 : 1.0;
  final hourlyRidership = [
    for (final entry in hourlyWeights.entries)
      HourlyRidershipPoint(
        hour: entry.key,
        riders: (2450 * entry.value * dayScale).round(),
      ),
  ];

  return FleetStatistics(
    activeBusCount: buses.length,
    totalPassengers: totalPassengers,
    totalCapacity: totalCapacity,
    averageLoadPercent: avgLoad,
    onTimeCount: onTimeCount,
    earlyCount: earlyCount,
    lateCount: lateCount,
    onTimePercent: onTimeShare,
    electricBusCount: electricCount,
    electricSharePercent: electricShare,
    busiestLine: busiest,
    lineStats: lineStats,
    crowdingBreakdown: crowding,
    hourlyRidership: hourlyRidership,
    updatedAt: timestamp,
  );
}

/// Exposes live [FleetStatistics] derived from [liveBusesStreamProvider].
final fleetStatisticsProvider = Provider.autoDispose<FleetStatistics>((ref) {
  final simulator = ref.watch(busSimulatorProvider);
  final buses = isFlutterTestEnvironment
      ? simulator.snapshotAt(DateTime.now())
      : (ref.watch(liveBusesStreamProvider).valueOrNull ??
          simulator.snapshotAt(DateTime.now()));
  return computeFleetStatistics(buses);
});
