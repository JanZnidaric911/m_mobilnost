// Defines structured itinerary instructions and nearest-stop search result models.

import 'package:flutter/foundation.dart';
import 'package:m_mobilnost/data/models/bus_line.dart';
import 'package:m_mobilnost/data/models/bus_stop.dart';
import 'package:m_mobilnost/data/models/departure.dart';
import 'package:m_mobilnost/data/models/trip_plan.dart';

/// Categorizes each actionable step in "What do I do next?" instructions.
enum TripStepType {
  /// Walk from origin or a transfer hub to the boarding bus stop.
  walkToStop,

  /// Board a specific bus line and direction at a stop.
  boardBus,

  /// Stay on the bus for a number of stops until the target stop.
  rideStops,

  /// Wait at a transfer stop (with optional tight-connection warning).
  transferAt,

  /// Alight from the bus at the named stop.
  getOff,

  /// Walk from the final alighting stop to the destination.
  walkToDestination,

  /// Final confirmation that the rider has reached the destination.
  arrived,
}

/// Structured, locale-agnostic instruction item rendered and read aloud by UI.
@immutable
class TripStepInstruction {
  /// Creates a [TripStepInstruction] describing one step of a [TripOption].
  const TripStepInstruction({
    required this.type,
    this.stopId,
    this.stopName,
    this.lineId,
    this.lineCode,
    this.directionName,
    this.stopCount,
    this.durationMinutes,
    this.distanceMeters,
    this.isTightTransfer = false,
    this.startTime,
    this.endTime,
    this.delaySeconds = 0,
  });

  /// Semantic step kind mapped to localized UI instructions.
  final TripStepType type;

  /// Relevant stop ID when applicable.
  final String? stopId;

  /// Relevant stop or destination name.
  final String? stopName;

  /// Bus line ID when boarding or riding.
  final String? lineId;

  /// Public bus line code when boarding or riding.
  final String? lineCode;

  /// Bus direction label when boarding.
  final String? directionName;

  /// Number of stops ridden on a bus leg.
  final int? stopCount;

  /// Step or transfer wait duration in minutes.
  final int? durationMinutes;

  /// Walking distance in meters for walk steps.
  final double? distanceMeters;

  /// True when a transfer buffer is <= 4 minutes given live/simulated delays.
  final bool isTightTransfer;

  /// Scheduled/estimated start time for the step.
  final DateTime? startTime;

  /// Scheduled/estimated end time for the step.
  final DateTime? endTime;

  /// Delay in seconds on the associated bus leg.
  final int delaySeconds;
}

/// Candidate starting stop ranked by earliest total arrival time at destination.
@immutable
class NearestStopResult {
  /// Creates a [NearestStopResult] linking a walkable stop to a full itinerary.
  const NearestStopResult({
    required this.stop,
    required this.walkMeters,
    required this.walkMinutes,
    required this.line,
    required this.direction,
    required this.nextDeparture,
    required this.destinationStop,
    required this.estimatedArrivalTime,
    required this.totalMinutes,
    required this.transferCount,
    this.transferStop,
    this.transferLine,
    required this.tripOption,
  });

  /// Candidate boarding stop near the user's origin.
  final BusStop stop;

  /// Walking distance from origin to [stop] in meters.
  final double walkMeters;

  /// Estimated walking duration from origin to [stop] in whole minutes.
  final int walkMinutes;

  /// First bus line to board at [stop].
  final BusLine line;

  /// Travel direction on [line].
  final LineDirection direction;

  /// Next viable departure at [stop] after the user finishes walking there.
  final Departure nextDeparture;

  /// Final alighting stop near the user's destination.
  final BusStop destinationStop;

  /// Total door-to-door arrival timestamp at the destination.
  final DateTime estimatedArrivalTime;

  /// Total door-to-door duration in minutes from query time.
  final int totalMinutes;

  /// Number of bus transfers (`0` for direct, `1` for one transfer).
  final int transferCount;

  /// Intermediate hub stop when [transferCount] > 0.
  final BusStop? transferStop;

  /// Connecting bus line when [transferCount] > 0.
  final BusLine? transferLine;

  /// Full [TripOption] itinerary behind this stop recommendation.
  final TripOption tripOption;
}
