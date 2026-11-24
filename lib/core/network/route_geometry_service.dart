// Resolves road-following geometry for seeded Marprom routes from bundled data.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/seed/seed_lines.dart';

/// Road-following geometry for a seeded bus route direction.
///
/// The [key] has the form `'<lineId>|<directionId>'`. Geometry comes from the
/// bundled per-stop-pair road segments (see `LineDirection.roadPolyline`), so
/// no network access is needed and the result always passes through every
/// stop in order. Unknown keys resolve to an empty list.
final routeGeometryProvider =
    FutureProvider.family<List<LatLng>, String>((ref, key) async {
  final parts = key.split('|');
  if (parts.length != 2) return const <LatLng>[];

  final direction = seedLinesById[parts.first]?.directionById(parts.last);
  if (direction == null || direction.polyline.length < 2) {
    return const <LatLng>[];
  }
  return direction.roadPolyline;
});
