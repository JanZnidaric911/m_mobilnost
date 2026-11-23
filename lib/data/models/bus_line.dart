// Defines BusLine and LineDirection models for Maribor bus routes and polylines.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// One travel direction of a [BusLine] with ordered stops and route polyline.
@immutable
class LineDirection {
  /// Creates a [LineDirection] linking ordered stops to a map polyline.
  const LineDirection({
    required this.id,
    required this.name,
    required this.terminalStopId,
    required this.stopIds,
    required this.polyline,
  });

  /// Unique direction ID (for example `6_out` or `6_in`).
  final String id;

  /// Display direction label (typically `Origin - Terminus`).
  final String name;

  /// Final destination stop ID for this direction.
  final String terminalStopId;

  /// Ordered sequence of stop IDs visited from origin to terminus.
  final List<String> stopIds;

  /// Geographic polyline coordinates used for map rendering and simulation.
  final List<LatLng> polyline;
}

/// Represents a Marprom city bus line with brand color and bidirectional routes.
@immutable
class BusLine {
  /// Creates a [BusLine] with two-way [directions] and accessibility metadata.
  const BusLine({
    required this.id,
    required this.code,
    required this.name,
    required this.color,
    required this.directions,
    this.isLowFloorDefault = true,
  });

  /// Stable line identifier.
  final String id;

  /// Short public line code displayed on badges (for example `6` or `12`).
  final String code;

  /// Descriptive route name covering key terminals.
  final String name;

  /// Distinguishing line color used on badges and map polylines.
  final Color color;

  /// Available travel directions (typically outbound and inbound).
  final List<LineDirection> directions;

  /// Whether vehicles assigned to this line are normally low-floor accessible.
  final bool isLowFloorDefault;

  /// Looks up a [LineDirection] by [directionId], returning null if absent.
  LineDirection? directionById(String directionId) {
    for (final direction in directions) {
      if (direction.id == directionId) return direction;
    }
    return null;
  }
}
