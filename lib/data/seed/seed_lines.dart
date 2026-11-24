// Official Marprom Maribor urban bus lines (G1-G6 main & P7-P19 suburban/connector).

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/polyline_codec.dart';
import '../models/bus_line.dart';
import 'seed_road_geometry.dart';
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
        roadSegments: _roadSegmentsFromStops(outboundStopIds),
      ),
      LineDirection(
        id: '${id}_in',
        name: inboundName,
        terminalStopId: inboundStopIds.last,
        stopIds: inboundStopIds,
        polyline: _polylineFromStops(inboundStopIds),
        roadSegments: _roadSegmentsFromStops(inboundStopIds),
      ),
    ],
  );
}

List<LatLng> _polylineFromStops(List<String> stopIds) {
  return [
    for (final stopId in stopIds) seedStopsById[stopId]!.position,
  ];
}

/// Decoded road segments keyed like [seedRoadSegmentsEncoded], filled lazily
/// so every stop pair is decoded at most once.
final Map<String, List<LatLng>> _decodedSegmentCache = {};

/// Returns the bundled road geometry from [fromId] to [toId], or the straight
/// two-point segment between the stops when no geometry is bundled.
List<LatLng> _roadSegment(String fromId, String toId) {
  final from = seedStopsById[fromId]!.position;
  final to = seedStopsById[toId]!.position;
  final key = '$fromId>$toId';
  final encoded = seedRoadSegmentsEncoded[key];
  if (encoded == null || encoded.isEmpty) return [from, to];
  return _decodedSegmentCache[key] ??= () {
    final decoded = decodePolyline(encoded);
    if (decoded.length < 2) return [from, to];
    // Pin the ends to the exact stop coordinates: the 1e5 encoding rounds
    // them, and adjacent segments must join without gaps.
    decoded
      ..[0] = from
      ..[decoded.length - 1] = to;
    return List<LatLng>.unmodifiable(decoded);
  }();
}

List<List<LatLng>> _roadSegmentsFromStops(List<String> stopIds) {
  return [
    for (var i = 0; i < stopIds.length - 1; i++)
      _roadSegment(stopIds[i], stopIds[i + 1]),
  ];
}

/// All 19 Marprom Maribor bus lines: main trunk lines G1-G6 and connector lines P7-P19.
final List<BusLine> seedLines = [
  _buildLine(
    id: 'G1',
    code: 'G1',
    name: 'Tezno – UKC – AP Maribor',
    color: const Color(0xFFC8102E),
    outboundName: 'Tezno Ind. – AP Maribor',
    inboundName: 'AP Maribor – Tezno Ind.',
    outboundStopIds: const [
      'tezno_industrijska',
      'tezno',
      'tezno_dom',
      'supernova_tezno',
      'ukc_maribor',
      'titova_cesta',
      'city_center',
      'glavna_postaja',
    ],
  ),
  _buildLine(
    id: 'G2',
    code: 'G2',
    name: 'Nova vas – UKC – AP Maribor',
    color: const Color(0xFF0B6E4F),
    outboundName: 'Betnava / Nova vas – AP Maribor',
    inboundName: 'AP Maribor – Nova vas / Betnava',
    outboundStopIds: const [
      'betnava',
      'nova_vas',
      'kardeljeva',
      'tabor',
      'magdalena',
      'ukc_maribor',
      'glavni_trg',
      'trznica',
      'glavna_postaja',
    ],
  ),
  _buildLine(
    id: 'G3',
    code: 'G3',
    name: 'Mestna krožna linija (Pobrežje – Tabor – Studenci)',
    color: const Color(0xFF0057B8),
    outboundName: 'AP Maribor – Pobrežje – Tabor – Studenci – Mestni park',
    inboundName: 'Mestni park – Studenci – Tabor – Pobrežje – AP Maribor',
    outboundStopIds: const [
      'glavna_postaja',
      'melje',
      'pobrezje',
      'europark',
      'tezno_dom',
      'tabor',
      'spelina',
      'studenci',
      'koroska_vrata',
      'univerza',
      'ljudski_vrt',
      'mestni_park',
    ],
  ),
  _buildLine(
    id: 'G4',
    code: 'G4',
    name: 'Studenci – Glavni trg – Pobrežje',
    color: const Color(0xFFD97706),
    outboundName: 'Mariborski otok / Studenci – Pobrežje',
    inboundName: 'Pobrežje – Studenci / Mariborski otok',
    outboundStopIds: const [
      'mariborski_otok',
      'studenci',
      'spelina',
      'magdalena',
      'glavni_trg',
      'drava',
      'europark',
      'pobrezje',
    ],
  ),
  _buildLine(
    id: 'G5',
    code: 'G5',
    name: 'Rotovž – Koroška vrata – UKC (Električna)',
    color: const Color(0xFF6D28D9),
    outboundName: 'Koroška vrata – Rotovž – UKC – AP Maribor',
    inboundName: 'AP Maribor – UKC – Rotovž – Koroška vrata',
    outboundStopIds: const [
      'koroska_vrata',
      'gosposvetska',
      'univerza',
      'rotovz',
      'glavni_trg',
      'lent',
      'ukc_maribor',
      'europark',
      'glavna_postaja',
    ],
  ),
  _buildLine(
    id: 'G6',
    code: 'G6',
    name: 'Pohorska vzpenjača – Tabor – Melje',
    color: const Color(0xFF15803D),
    outboundName: 'Vzpenjača – AP Maribor – Melje',
    inboundName: 'Melje – AP Maribor – Vzpenjača',
    outboundStopIds: const [
      'vzpenjaca',
      'radvanje',
      'tabor',
      'dvorana_tabor',
      'ukc_maribor',
      'titova_cesta',
      'glavni_trg',
      'glavna_postaja',
      'melje',
    ],
  ),
  _buildLine(
    id: 'P7',
    code: 'P7',
    name: 'AP Maribor – Kamnica – Rošpoh',
    color: const Color(0xFF0369A1),
    outboundName: 'AP Maribor – Kamnica – Rošpoh',
    inboundName: 'Rošpoh – Kamnica – AP Maribor',
    outboundStopIds: const [
      'glavna_postaja',
      'mestni_park',
      'ljudski_vrt',
      'univerza',
      'koroska_vrata',
      'kamnica',
      'rospoh',
    ],
  ),
  _buildLine(
    id: 'P8',
    code: 'P8',
    name: 'AP Maribor – Pekre – Limbuš',
    color: const Color(0xFF0E7490),
    outboundName: 'AP Maribor – Pekre – Limbuš',
    inboundName: 'Limbuš – Pekre – AP Maribor',
    outboundStopIds: const [
      'glavna_postaja',
      'city_center',
      'glavni_trg',
      'spelina',
      'studenci',
      'pekre',
      'limbus',
    ],
  ),
  _buildLine(
    id: 'P9',
    code: 'P9',
    name: 'AP Maribor – Zrkovci – Dogoše',
    color: const Color(0xFFB45309),
    outboundName: 'AP Maribor – Zrkovci – Dogoše',
    inboundName: 'Dogoše – Zrkovci – AP Maribor',
    outboundStopIds: const [
      'glavna_postaja',
      'trznica',
      'glavni_trg',
      'drava',
      'europark',
      'pobrezje',
      'zrkovci',
      'dogose',
    ],
  ),
  _buildLine(
    id: 'P10',
    code: 'P10',
    name: 'AP Maribor – Malečnik – Trčova',
    color: const Color(0xFF7C2D12),
    outboundName: 'AP Maribor – Malečnik – Trčova',
    inboundName: 'Trčova – Malečnik – AP Maribor',
    outboundStopIds: const [
      'glavna_postaja',
      'trznica',
      'mestni_park',
      'melje',
      'meljski_hrib',
      'malecnik',
      'trcova',
    ],
  ),
  _buildLine(
    id: 'P11',
    code: 'P11',
    name: 'AP Maribor – Betnava – Razvanje',
    color: const Color(0xFF4338CA),
    outboundName: 'AP Maribor – Betnava – Razvanje',
    inboundName: 'Razvanje – Betnava – AP Maribor',
    outboundStopIds: const [
      'glavna_postaja',
      'titova_cesta',
      'ukc_maribor',
      'kardeljeva',
      'betnava',
      'radvanje',
      'razvanje',
    ],
  ),
  _buildLine(
    id: 'P12',
    code: 'P12',
    name: 'AP Maribor – Dobrava – Supernova',
    color: const Color(0xFFBE185D),
    outboundName: 'AP Maribor – Dobrava – Supernova',
    inboundName: 'Supernova – Dobrava – AP Maribor',
    outboundStopIds: const [
      'glavna_postaja',
      'city_center',
      'ukc_maribor',
      'europark',
      'pobrezje',
      'pobrezje_pokopalisce',
      'dobrava',
      'supernova_tezno',
    ],
  ),
  _buildLine(
    id: 'P13',
    code: 'P13',
    name: 'AP Maribor – Stražun – Cona Tezno',
    color: const Color(0xFF1D4ED8),
    outboundName: 'AP Maribor – Stražun – Cona Tezno',
    inboundName: 'Cona Tezno – Stražun – AP Maribor',
    outboundStopIds: const [
      'glavna_postaja',
      'city_center',
      'glavni_trg',
      'ukc_maribor',
      'europark',
      'strazun',
      'tezno',
      'cona_tezno',
    ],
  ),
  _buildLine(
    id: 'P14',
    code: 'P14',
    name: 'E.Leclerc – Tabor – Limbuš',
    color: const Color(0xFF9333EA),
    outboundName: 'E.Leclerc – Tabor – Limbuš',
    inboundName: 'Limbuš – Tabor – E.Leclerc',
    outboundStopIds: const [
      'eleclerc',
      'betnava',
      'nova_vas',
      'tabor',
      'dvorana_tabor',
      'radvanje',
      'pekre',
      'limbus',
    ],
  ),
  _buildLine(
    id: 'P15',
    code: 'P15',
    name: 'Košaški dol – ŽP Maribor – Bresternica',
    color: const Color(0xFF0F766E),
    outboundName: 'Košaki – ŽP Maribor – Bresternica',
    inboundName: 'Bresternica – ŽP Maribor – Košaki',
    outboundStopIds: const [
      'kosaki',
      'piramida',
      'glavna_postaja',
      'univerza',
      'feri',
      'koroska_vrata',
      'mariborski_otok',
      'bresternica',
    ],
  ),
  _buildLine(
    id: 'P16',
    code: 'P16',
    name: 'AP Maribor – Brezje – Dogoše – Duplek',
    color: const Color(0xFFC2410C),
    outboundName: 'AP Maribor – Brezje – Duplek',
    inboundName: 'Duplek – Brezje – AP Maribor',
    outboundStopIds: const [
      'glavna_postaja',
      'europark',
      'pobrezje',
      'pobrezje_pokopalisce',
      'brezje',
      'dogose',
      'duplek',
    ],
  ),
  _buildLine(
    id: 'P17',
    code: 'P17',
    name: 'E.Leclerc – Glavni trg – Košaki',
    color: const Color(0xFFA21CAF),
    outboundName: 'E.Leclerc – Glavni trg – Košaki',
    inboundName: 'Košaki – Glavni trg – E.Leclerc',
    outboundStopIds: const [
      'eleclerc',
      'supernova_tezno',
      'tezno_dom',
      'ukc_maribor',
      'glavni_trg',
      'mestni_park',
      'piramida',
      'kosaki',
    ],
  ),
  _buildLine(
    id: 'P18',
    code: 'P18',
    name: 'UKC Maribor – Nova vas – Pekre',
    color: const Color(0xFF047857),
    outboundName: 'UKC Maribor – Nova vas – Pekre',
    inboundName: 'Pekre – Nova vas – UKC Maribor',
    isLowFloorDefault: false,
    outboundStopIds: const [
      'ukc_maribor',
      'magdalena',
      'tabor',
      'dvorana_tabor',
      'kardeljeva',
      'nova_vas',
      'radvanje',
      'pekre',
    ],
  ),
  _buildLine(
    id: 'P19',
    code: 'P19',
    name: 'Dom pod gorco – Center – Supernova',
    color: const Color(0xFF3730A3),
    outboundName: 'Dom pod gorco – Center – Supernova',
    inboundName: 'Supernova – Center – Dom pod gorco',
    outboundStopIds: const [
      'dom_pod_gorco',
      'studenci',
      'koroska_vrata',
      'gosposvetska',
      'univerza',
      'glavna_postaja',
      'titova_cesta',
      'supernova_tezno',
    ],
  ),
];

/// Fast ID-indexed map of [seedLines] including backwards-compatible numeric aliases.
final Map<String, BusLine> seedLinesById = {
  for (final line in seedLines) line.id: line,
  // Legacy numeric aliases so deep links and older saved favorites resolve seamlessly.
  '1': seedLines[0],
  '2': seedLines[1],
  '3': seedLines[2],
  '4': seedLines[3],
  '5': seedLines[4],
  '6': seedLines[5],
  '7': seedLines[6],
  '8': seedLines[7],
  '9': seedLines[8],
  '10': seedLines[9],
  '11': seedLines[10],
  '12': seedLines[11],
  '13': seedLines[12],
  '14': seedLines[13],
  '15': seedLines[14],
  '16': seedLines[15],
  '17': seedLines[16],
  '18': seedLines[17],
  '19': seedLines[18],
  '21': seedLines[10],
};
