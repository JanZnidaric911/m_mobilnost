// Clearly fictional mock Maribor bus lines with two-way directions and polylines.

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/bus_line.dart';
import 'seed_stops.dart';

/// Builds a two-direction [BusLine] whose route polylines derive from [seedStops].
BusLine _buildLine({
  required String id,
  required String code,
  required String name,
  required Color color,
  required String outboundName,
  required String inboundName,
  required List<String> outboundStopIds,
  bool isLowFloorDefault = true,
}) {
  final inboundStopIds = outboundStopIds.reversed.toList(growable: false);
  return BusLine(
    id: id,
    code: code,
    name: name,
    color: color,
    isLowFloorDefault: isLowFloorDefault,
    directions: [
      LineDirection(
        id: '${id}_out',
        name: outboundName,
        terminalStopId: outboundStopIds.last,
        stopIds: outboundStopIds,
        polyline: _polylineFromStops(outboundStopIds),
        roadPolyline: _roadPolylineFromStops(outboundStopIds),
      ),
      LineDirection(
        id: '${id}_in',
        name: inboundName,
        terminalStopId: inboundStopIds.last,
        stopIds: inboundStopIds,
        polyline: _polylineFromStops(inboundStopIds),
        roadPolyline: _roadPolylineFromStops(inboundStopIds),
      ),
    ],
  );
}

List<LatLng> _polylineFromStops(List<String> stopIds) {
  return [
    for (final stopId in stopIds) seedStopsById[stopId]!.position,
  ];
}

List<LatLng> _roadPolylineFromStops(List<String> stopIds) {
  final stops = _polylineFromStops(stopIds);
  if (stops.length < 2) return stops;
  final road = <LatLng>[];
  for (var i = 0; i < stops.length - 1; i++) {
    final from = stops[i];
    final to = stops[i + 1];
    if (i == 0) road.add(from);
    for (var step = 1; step <= 8; step++) {
      final t = step / 8;
      road.add(
        LatLng(
          from.latitude + (to.latitude - from.latitude) * t,
          from.longitude + (to.longitude - from.longitude) * t,
        ),
      );
    }
  }
  return road;
}

/// Twelve fictional Maribor city bus lines serving all [seedStops].
final List<BusLine> seedLines = [
  _buildLine(
    id: '1',
    code: '1',
    name: 'Tezno – Glavni trg – Kamnica',
    color: const Color(0xFF0057B8),
    outboundName: 'Tezno Ind. – Rošpoh',
    inboundName: 'Rošpoh – Tezno Ind.',
    outboundStopIds: const [
      'tezno_industrijska',
      'tezno',
      'tezno_dom',
      'ukc_maribor',
      'europark',
      'drava',
      'glavni_trg',
      'univerza',
      'ljudski_vrt',
      'gosposvetska',
      'koroska_vrata',
      'kamnica',
      'rospoh',
    ],
  ),
  _buildLine(
    id: '2',
    code: '2',
    name: 'Betnava – Nova vas – Glavna postaja',
    color: const Color(0xFF0F766E),
    outboundName: 'Betnava – Glavna postaja',
    inboundName: 'Glavna postaja – Betnava',
    outboundStopIds: const [
      'betnava',
      'nova_vas',
      'tabor',
      'dvorana_tabor',
      'magdalena',
      'ukc_maribor',
      'titova_cesta',
      'trznica',
      'glavna_postaja',
    ],
  ),
  _buildLine(
    id: '3',
    code: '3',
    name: 'Brezje – Pobrežje – Glavni trg',
    color: const Color(0xFFC2410C),
    outboundName: 'Brezje – Glavni trg',
    inboundName: 'Glavni trg – Brezje',
    outboundStopIds: const [
      'brezje',
      'pobrezje_pokopalisce',
      'pobrezje',
      'europark',
      'titova_cesta',
      'glavna_postaja',
      'trznica',
      'glavni_trg',
    ],
  ),
  _buildLine(
    id: '4',
    code: '4',
    name: 'Limbuš – Studenci – Europark',
    color: const Color(0xFF6D28D9),
    outboundName: 'Limbuš – Europark',
    inboundName: 'Europark – Limbuš',
    outboundStopIds: const [
      'limbus',
      'pekre',
      'studenci',
      'spelina',
      'lent',
      'glavni_trg',
      'drava',
      'europark',
    ],
  ),
  _buildLine(
    id: '6',
    code: '6',
    name: 'Vzpenjača – Tabor – Glavna postaja',
    color: const Color(0xFFB91C1C),
    outboundName: 'Vzpenjača – Glavna postaja',
    inboundName: 'Glavna postaja – Vzpenjača',
    outboundStopIds: const [
      'vzpenjaca',
      'radvanje',
      'nova_vas',
      'tabor',
      'dvorana_tabor',
      'spelina',
      'magdalena',
      'ukc_maribor',
      'titova_cesta',
      'glavna_postaja',
    ],
  ),
  _buildLine(
    id: '7',
    code: '7',
    name: 'Kamnica – Mestni park – Melje',
    color: const Color(0xFF0369A1),
    outboundName: 'Kamnica – Melje',
    inboundName: 'Melje – Kamnica',
    outboundStopIds: const [
      'kamnica',
      'mariborski_otok',
      'koroska_vrata',
      'feri',
      'univerza',
      'ljudski_vrt',
      'mestni_park',
      'piramida',
      'glavna_postaja',
      'melje',
    ],
  ),
  _buildLine(
    id: '8',
    code: '8',
    name: 'Košaki – Melje – Lent',
    color: const Color(0xFFB45309),
    outboundName: 'Košaki – Lent',
    inboundName: 'Lent – Košaki',
    outboundStopIds: const [
      'kosaki',
      'piramida',
      'meljski_hrib',
      'melje',
      'glavna_postaja',
      'trznica',
      'glavni_trg',
      'lent',
    ],
  ),
  _buildLine(
    id: '12',
    code: '12',
    name: 'Razvanje – UKC – Pobrežje',
    color: const Color(0xFF3730A3),
    outboundName: 'Razvanje – Pobrežje',
    inboundName: 'Pobrežje – Razvanje',
    outboundStopIds: const [
      'razvanje',
      'betnava',
      'kardeljeva',
      'tabor',
      'magdalena',
      'ukc_maribor',
      'europark',
      'pobrezje',
    ],
  ),
  _buildLine(
    id: '15',
    code: '15',
    name: 'Mariborski otok – FERI – Glavna postaja',
    color: const Color(0xFFBE185D),
    outboundName: 'Mariborski otok – Glavna postaja',
    inboundName: 'Glavna postaja – Mariborski otok',
    outboundStopIds: const [
      'mariborski_otok',
      'studenci',
      'feri',
      'gosposvetska',
      'univerza',
      'glavni_trg',
      'drava',
      'glavna_postaja',
    ],
  ),
  _buildLine(
    id: '16',
    code: '16',
    name: 'Limbuš – Radvanje – Tabor – Tezno',
    color: const Color(0xFF15803D),
    outboundName: 'Limbuš – Tezno',
    inboundName: 'Tezno – Limbuš',
    outboundStopIds: const [
      'limbus',
      'pekre',
      'radvanje',
      'dvorana_tabor',
      'tabor',
      'kardeljeva',
      'tezno_dom',
      'tezno',
    ],
  ),
  _buildLine(
    id: '18',
    code: '18',
    name: 'Pekre – Vzpenjača – Betnava – Tezno',
    color: const Color(0xFF0E7490),
    outboundName: 'Pekre – Tezno Ind.',
    inboundName: 'Tezno Ind. – Pekre',
    isLowFloorDefault: false,
    outboundStopIds: const [
      'pekre',
      'vzpenjaca',
      'radvanje',
      'betnava',
      'tezno_dom',
      'tezno',
      'tezno_industrijska',
    ],
  ),
  _buildLine(
    id: '21',
    code: '21',
    name: 'Mestni park – Glavni trg – UKC – Razvanje',
    color: const Color(0xFF4338CA),
    outboundName: 'Mestni park – Razvanje',
    inboundName: 'Razvanje – Mestni park',
    outboundStopIds: const [
      'mestni_park',
      'ljudski_vrt',
      'univerza',
      'glavni_trg',
      'lent',
      'spelina',
      'magdalena',
      'ukc_maribor',
      'kardeljeva',
      'nova_vas',
      'razvanje',
    ],
  ),
];

/// Fast ID-indexed map of [seedLines].
final Map<String, BusLine> seedLinesById = {
  for (final line in seedLines) line.id: line,
};
