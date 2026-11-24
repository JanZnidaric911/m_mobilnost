// Defines the BusPosition model for live or simulated vehicle tracking on routes.

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:m_mobilnost/core/widgets/status_chip.dart';

import 'occupancy.dart';

/// Snapshot of an active city bus moving along a line direction polyline.
@immutable
class BusPosition {
  /// Creates a [BusPosition] telemetry snapshot for a single active vehicle.
  const BusPosition({
    required this.vehicleId,
    required this.lineId,
    required this.lineCode,
    required this.directionId,
    required this.directionName,
    required this.position,
    required this.progress,
    required this.speedKmh,
    required this.nextStopId,
    required this.nextStopName,
    required this.remainingStopsCount,
    required this.etaToNextStopSeconds,
    required this.delaySeconds,
    required this.occupancy,
    required this.updatedAt,
    this.passengerCount = 24,
    this.vehicleCapacity = 85,
    this.loadPercent = 28,
    this.vehicleModel = "MAN Lion's City 12",
    this.isElectric = false,
  });

  /// Unique vehicle or active trip identifier.
  final String vehicleId;

  /// Bus line identifier.
  final String lineId;

  /// Short public line code.
  final String lineCode;

  /// Active direction ID along the route.
  final String directionId;

  /// Human-readable direction label.
  final String directionName;

  /// Current interpolated geographic coordinate along the route polyline.
  final LatLng position;

  /// Normalized route progress in the range `0.0` to `1.0`.
  final double progress;

  /// Current estimated speed in km/h.
  final double speedKmh;

  /// ID of the upcoming stop ahead of the vehicle.
  final String nextStopId;

  /// Name of the upcoming stop ahead of the vehicle.
  final String nextStopName;

  /// Number of stops remaining until the terminal stop (including [nextStopId]).
  final int remainingStopsCount;

  /// Estimated seconds until arriving at [nextStopId].
  final int etaToNextStopSeconds;

  /// Current delay in seconds relative to schedule.
  final int delaySeconds;

  /// Current passenger crowding level.
  final BusOccupancyLevel occupancy;

  /// Timestamp when this telemetry snapshot was produced.
  final DateTime updatedAt;

  /// Estimated number of passengers currently aboard this vehicle.
  final int passengerCount;

  /// Rated passenger capacity (seated + standing) of this vehicle.
  final int vehicleCapacity;

  /// Load percentage (`0..100`) derived from Automatic Passenger Counting telemetry.
  final int loadPercent;

  /// Fleet vehicle model operating this run (e.g. `Iveco E-Way 12m`).
  final String vehicleModel;

  /// Whether this vehicle is a zero-emission battery-electric bus.
  final bool isElectric;

  /// Semantic status derived from [delaySeconds] thresholds.
  TransitStatusType get status {
    if (delaySeconds < -60) return TransitStatusType.early;
    if (delaySeconds <= 120) return TransitStatusType.onTime;
    return TransitStatusType.late;
  }
}
