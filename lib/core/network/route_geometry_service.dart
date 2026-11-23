import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../data/seed/seed_lines.dart';

/// Loads accurate drivable road geometry for seeded bus routes.
/// Falls back to a compact interpolated polyline when the device is offline.
final routeGeometryProvider =
    FutureProvider.family<List<LatLng>, String>((ref, key) async {
  final parts = key.split('|');
  if (parts.length != 2) return const <LatLng>[];

  final line = seedLinesById[parts.first];
  final direction = line?.directionById(parts.last);
  if (direction == null || direction.polyline.length < 2) {
    return const <LatLng>[];
  }

  final fallback = _densify(direction.polyline);
  final coordinates = direction.polyline
      .map((point) => '${point.longitude},${point.latitude}')
      .join(';');
  final uri = Uri.parse(
    'https://router.project-osrm.org/route/v1/driving/$coordinates'
    '?overview=full&geometries=geojson&steps=false',
  );

  try {
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return fallback;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return fallback;

    final geometry =
        ((routes.first as Map<String, dynamic>)['geometry']
            as Map<String, dynamic>?)?['coordinates'] as List<dynamic>?;
    if (geometry == null || geometry.length < 2) return fallback;

    return [
      for (final coordinate in geometry)
        LatLng(
          (coordinate as List<dynamic>)[1] as double,
          coordinate[0] as double,
        ),
    ];
  } catch (_) {
    return fallback;
  }
});

List<LatLng> _densify(List<LatLng> stops) {
  if (stops.length < 2) return List<LatLng>.from(stops);
  final result = <LatLng>[];
  for (var i = 0; i < stops.length - 1; i++) {
    final from = stops[i];
    final to = stops[i + 1];
    if (i == 0) result.add(from);
    for (var step = 1; step <= 8; step++) {
      final t = step / 8;
      result.add(
        LatLng(
          from.latitude + (to.latitude - from.latitude) * t,
          from.longitude + (to.longitude - from.longitude) * t,
        ),
      );
    }
  }
  return result;
}
