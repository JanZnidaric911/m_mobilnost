// Defines the Departure model combining scheduled times, live delays, and freshness.

import 'package:flutter/foundation.dart';
import 'package:m_mobilnost/core/network/data_freshness.dart';
import 'package:m_mobilnost/core/widgets/status_chip.dart';

import 'occupancy.dart';

/// Represents a scheduled or live-adjusted bus departure at a specific stop.
@immutable
class Departure {
  /// Creates a [Departure] entry with schedule, delay, occupancy, and freshness.
  const Departure({
    required this.id,
    required this.lineId,
    required this.lineCode,
    required this.directionId,
    required this.directionName,
    required this.stopId,
    required this.scheduledTime,
    required this.delaySeconds,
    this.isCancelled = false,
    required this.occupancy,
    required this.freshness,
  });

  /// Unique departure identifier for a trip at a stop.
  final String id;

  /// Associated bus line ID.
  final String lineId;

  /// Short display code of the line.
  final String lineCode;

  /// Direction ID on the line.
  final String directionId;

  /// Human-readable destination or direction label.
  final String directionName;

  /// Stop ID where this departure occurs.
  final String stopId;

  /// Timetable scheduled departure timestamp.
  final DateTime scheduledTime;

  /// Signed delay in seconds (negative means early, positive means late).
  final int delaySeconds;

  /// Whether this specific departure has been cancelled.
  final bool isCancelled;

  /// Estimated crowding level for this departure.
  final BusOccupancyLevel occupancy;

  /// Freshness metadata indicating simulated, live, or cached schedule origin.
  final DataFreshness freshness;

  /// Estimated departure time applying [delaySeconds] to [scheduledTime].
  DateTime get estimatedTime =>
      scheduledTime.add(Duration(seconds: delaySeconds));

  /// Semantic status derived from cancellation or delay thresholds.
  TransitStatusType get status {
    if (isCancelled) return TransitStatusType.disruption;
    if (delaySeconds < -60) return TransitStatusType.early;
    if (delaySeconds <= 120) return TransitStatusType.onTime;
    return TransitStatusType.late;
  }

  /// Serializes this departure for local offline timetable caching.
  Map<String, dynamic> toJson() => {
        'id': id,
        'lineId': lineId,
        'lineCode': lineCode,
        'directionId': directionId,
        'directionName': directionName,
        'stopId': stopId,
        'scheduledTime': scheduledTime.toIso8601String(),
        'delaySeconds': delaySeconds,
        'isCancelled': isCancelled,
        'occupancy': occupancy.name,
        'freshnessKind': freshness.kind.name,
        'freshnessUpdatedAt': freshness.updatedAt.toIso8601String(),
      };

  /// Restores a [Departure] from cached JSON data.
  factory Departure.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    final occupancyName = json['occupancy'] as String? ?? 'unknown';
    final kindName = json['freshnessKind'] as String? ?? 'cached';
    return Departure(
      id: json['id'] as String,
      lineId: json['lineId'] as String,
      lineCode: json['lineCode'] as String,
      directionId: json['directionId'] as String,
      directionName: json['directionName'] as String,
      stopId: json['stopId'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      delaySeconds: json['delaySeconds'] as int? ?? 0,
      isCancelled: json['isCancelled'] as bool? ?? false,
      occupancy: BusOccupancyLevel.values.firstWhere(
        (v) => v.name == occupancyName,
        orElse: () => BusOccupancyLevel.unknown,
      ),
      freshness: DataFreshness(
        kind: DataSourceKind.values.firstWhere(
          (v) => v.name == kindName,
          orElse: () => DataSourceKind.cached,
        ),
        updatedAt: DateTime.parse(json['freshnessUpdatedAt'] as String),
      ),
    );
  }
}
