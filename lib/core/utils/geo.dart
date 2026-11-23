// Provides Haversine distance, polyline interpolation, and bearing calculations.

import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Geographic utilities tailored for Maribor city bus coordinates.
abstract final class GeoUtils {
  /// Default central Maribor coordinate (Glavni trg).
  static const LatLng mariborCenter = LatLng(46.5547, 15.6459);

  static const double _earthRadiusMeters = 6371000.0;

  /// Computes great-circle Haversine distance in meters between [a] and [b].
  static double haversineMeters(LatLng a, LatLng b) {
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLon = _toRadians(b.longitude - a.longitude);

    final sinHalfLat = math.sin(dLat / 2);
    final sinHalfLon = math.sin(dLon / 2);
    final h = sinHalfLat * sinHalfLat +
        math.cos(lat1) * math.cos(lat2) * sinHalfLon * sinHalfLon;
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(math.max(0.0, 1.0 - h)));
    return _earthRadiusMeters * c;
  }

  /// Returns total length of [polyline] in meters.
  static double polylineLengthMeters(List<LatLng> polyline) {
    if (polyline.length < 2) return 0.0;
    var total = 0.0;
    for (var i = 0; i < polyline.length - 1; i++) {
      total += haversineMeters(polyline[i], polyline[i + 1]);
    }
    return total;
  }

  /// Interpolates a point along [polyline] at normalized progress [t] in [0, 1].
  static LatLng interpolatePolyline(List<LatLng> polyline, double t) {
    if (polyline.isEmpty) return mariborCenter;
    if (polyline.length == 1) return polyline.first;

    final clampedT = t.clamp(0.0, 1.0);
    if (clampedT <= 0.0) return polyline.first;
    if (clampedT >= 1.0) return polyline.last;

    final segmentLengths = <double>[];
    var totalLength = 0.0;
    for (var i = 0; i < polyline.length - 1; i++) {
      final len = haversineMeters(polyline[i], polyline[i + 1]);
      segmentLengths.add(len);
      totalLength += len;
    }

    if (totalLength <= 0.0) return polyline.first;

    final targetDistance = totalLength * clampedT;
    var walked = 0.0;
    for (var i = 0; i < segmentLengths.length; i++) {
      final segLen = segmentLengths[i];
      if (walked + segLen >= targetDistance && segLen > 0) {
        final localT = (targetDistance - walked) / segLen;
        final start = polyline[i];
        final end = polyline[i + 1];
        return LatLng(
          start.latitude + (end.latitude - start.latitude) * localT,
          start.longitude + (end.longitude - start.longitude) * localT,
        );
      }
      walked += segLen;
    }
    return polyline.last;
  }

  /// Calculates initial compass bearing in degrees [0, 360) from [from] to [to].
  static double bearingDegrees(LatLng from, LatLng to) {
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);
    final dLon = _toRadians(to.longitude - from.longitude);
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final brng = math.atan2(y, x) * 180.0 / math.pi;
    return (brng + 360.0) % 360.0;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
}
