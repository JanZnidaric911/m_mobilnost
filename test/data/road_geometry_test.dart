// Unit tests for polyline decoding and LineDirection road-segment geometry.

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:m_mobilnost/core/utils/polyline_codec.dart';
import 'package:m_mobilnost/data/models/bus_line.dart';
import 'package:m_mobilnost/data/seed/seed_lines.dart';
import 'package:m_mobilnost/data/seed/seed_stops.dart';

void main() {
  group('decodePolyline', () {
    test('decodes the reference Google polyline', () {
      final points = decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
      expect(points, hasLength(3));
      expect(points[0].latitude, closeTo(38.5, 1e-9));
      expect(points[0].longitude, closeTo(-120.2, 1e-9));
      expect(points[2].latitude, closeTo(43.252, 1e-9));
      expect(points[2].longitude, closeTo(-126.453, 1e-9));
      expect(decodePolyline(''), isEmpty);
    });
  });

  group('LineDirection road geometry', () {
    const a = LatLng(46.55, 15.60);
    const b = LatLng(46.56, 15.62);
    const c = LatLng(46.57, 15.63);
    const d = LatLng(46.58, 15.65);
    const direction = LineDirection(
      id: 't_out',
      name: 'A - D',
      terminalStopId: 'd',
      stopIds: ['a', 'b', 'c', 'd'],
      polyline: [a, b, c, d],
      roadSegments: [
        [a, LatLng(46.552, 15.615), b],
        [], // Missing geometry -> straight fallback.
        [c, LatLng(46.575, 15.635), LatLng(46.578, 15.645), d],
      ],
    );

    test('segments fall back to straight lines when geometry is missing', () {
      expect(direction.segmentCount, 3);
      expect(direction.segment(1), [b, c]);
      expect(direction.segment(3), isEmpty);
      const bare = LineDirection(
        id: 'bare',
        name: 'bare',
        terminalStopId: 'b',
        stopIds: ['a', 'b'],
        polyline: [a, b],
      );
      expect(bare.roadPolyline, [a, b]);
    });

    test('roadPathBetween starts and ends at stops without duplicate joints', () {
      final path = direction.roadPathBetween(0, 3);
      expect(path.first, a);
      expect(path.last, d);
      expect(path, hasLength(3 + 1 + 3));
      for (var i = 0; i < path.length - 1; i++) {
        expect(path[i], isNot(path[i + 1]));
      }
      expect(direction.roadPolyline, path);

      expect(direction.roadPathBetween(1, 2), [b, c]);
      expect(direction.roadPathBetween(2, 2), [c]);
      expect(direction.roadPathBetween(-5, 1).first, a);
      expect(direction.roadPathBetween(2, 99).last, d);
    });

    test('seeded directions expose one road segment per stop pair', () {
      for (final line in seedLines) {
        for (final dir in line.directions) {
          expect(dir.roadSegments, hasLength(dir.stopIds.length - 1));
          for (var i = 0; i < dir.segmentCount; i++) {
            final segment = dir.segment(i);
            expect(segment.length, greaterThanOrEqualTo(2));
            expect(segment.first, seedStopsById[dir.stopIds[i]]!.position);
            expect(segment.last, seedStopsById[dir.stopIds[i + 1]]!.position);
          }
          expect(dir.roadPolyline.first, dir.polyline.first);
          expect(dir.roadPolyline.last, dir.polyline.last);
        }
      }
    });
  });
}
