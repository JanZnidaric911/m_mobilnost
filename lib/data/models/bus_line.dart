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
    this.roadSegments = const [],
  });

  /// Unique direction ID (for example `6_out` or `6_in`).
  final String id;

  /// Display direction label (typically `Origin - Terminus`).
  final String name;

  /// Final destination stop ID for this direction.
  final String terminalStopId;

  /// Ordered sequence of stop IDs visited from origin to terminus.
  final List<String> stopIds;

  /// Stop coordinates in visiting order (one point per entry of [stopIds]).
  ///
  /// Use this for stop markers and stop lookups; draw routes with
  /// [roadPolyline] or [roadPathBetween] instead.
  final List<LatLng> polyline;

  /// Road-following geometry between consecutive stops.
  ///
  /// Segment `i` runs from stop `i` to stop `i + 1`, so a complete list has
  /// `stopIds.length - 1` entries. Missing or degenerate (fewer than two
  /// points) entries fall back to the straight line between the two stops;
  /// see [segment].
  final List<List<LatLng>> roadSegments;

  /// Number of stop-to-stop segments in this direction.
  int get segmentCount => polyline.length < 2 ? 0 : polyline.length - 1;

  /// Road geometry from stop [index] to stop `index + 1`.
  ///
  /// Returns the bundled road segment when present, otherwise the straight
  /// two-point segment between the stops. Returns an empty list when [index]
  /// is out of range.
  List<LatLng> segment(int index) {
    if (index < 0 || index >= segmentCount) return const [];
    if (index < roadSegments.length && roadSegments[index].length >= 2) {
      return roadSegments[index];
    }
    return [polyline[index], polyline[index + 1]];
  }

  /// Full road-following route geometry: all [segment]s concatenated without
  /// duplicated joint points. Cached per instance.
  List<LatLng> get roadPolyline =>
      _roadPolylineCache[this] ??= List<LatLng>.unmodifiable(
        roadPathBetween(0, polyline.length - 1),
      );

  /// Road-following path from stop [fromIdx] to stop [toIdx] (inclusive).
  ///
  /// Indices are clamped to the valid stop range. When `fromIdx >= toIdx`
  /// the result is the single stop point at [fromIdx]. The returned path
  /// starts at the from-stop's segment start and ends at the to-stop.
  List<LatLng> roadPathBetween(int fromIdx, int toIdx) {
    if (polyline.isEmpty) return const [];
    final last = polyline.length - 1;
    final from = fromIdx.clamp(0, last);
    final to = toIdx.clamp(0, last);
    if (from >= to) return [polyline[from]];

    final path = <LatLng>[];
    for (var i = from; i < to; i++) {
      final points = segment(i);
      for (var p = 0; p < points.length; p++) {
        if (p == 0 && path.isNotEmpty && path.last == points.first) continue;
        path.add(points[p]);
      }
    }
    return path;
  }
}

final Expando<List<LatLng>> _roadPolylineCache =
    Expando<List<LatLng>>('roadPolyline');

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

  /// Whether this is a high-frequency main Marprom trunk line (`G1`–`G6`).
  bool get isMainTrunk => code.startsWith('G');

  /// Looks up a [LineDirection] by [directionId], returning null if absent.
  LineDirection? directionById(String directionId) {
    for (final direction in directions) {
      if (direction.id == directionId) return direction;
    }
    return null;
  }
}
