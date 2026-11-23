// Combines static seed notices with simulated dynamic delay alerts in 4 languages.

import '../models/service_notice.dart';
import '../seed/seed_lines.dart';
import '../seed/seed_notices.dart';
import 'delay_model.dart';

/// Produces active [ServiceNotice] records merging static and simulated alerts.
class NoticeGenerator {
  /// Creates a [NoticeGenerator] driven by [seed].
  const NoticeGenerator({this.seed = 42});

  /// Seed matching the active fleet simulator.
  final int seed;

  /// Generates active notices for [at], including dynamic delay notices when
  /// [useSimulatedLive] is enabled.
  List<ServiceNotice> generateNotices({
    required DateTime at,
    bool useSimulatedLive = true,
    Set<String> readNoticeIds = const {},
  }) {
    final base = buildSeedNotices(at)
        .where((n) => n.isActiveAt(at))
        .map((n) => n.copyWith(isRead: readNoticeIds.contains(n.id)))
        .toList();

    if (useSimulatedLive) {
      final delayModel = DelayModel(seed: seed);
      final hourBucket = DateTime(at.year, at.month, at.day, at.hour);
      var dynamicCount = 0;

      for (final line in seedLines) {
        if (dynamicCount >= 2) break;
        final tripId = '${line.id}_sim_${hourBucket.hour}';
        final delaySec = delayModel.delaySecondsForTrip(
          tripId: tripId,
          lineId: line.id,
          scheduledTime: hourBucket,
        );
        if (delaySec >= 240) {
          final delayMin = (delaySec / 60).round();
          final noticeId = 'sim_delay_${line.id}_${at.year}${at.month}${at.day}_${at.hour}';
          final firstStop = line.directions.first.stopIds.first;
          final lastStop = line.directions.first.stopIds.last;
          base.add(
            ServiceNotice(
              id: noticeId,
              severity: NoticeSeverity.delay,
              affectedLineIds: [line.id],
              affectedStopIds: [firstStop, lastStop],
              publishedAt: hourBucket,
              validUntil: hourBucket.add(const Duration(hours: 2)),
              isRead: readNoticeIds.contains(noticeId),
              titles: {
                'sl': 'Zamuda na liniji ${line.code} (~$delayMin min)',
                'en': 'Line ${line.code} running ~$delayMin min late',
                'de': 'Linie ${line.code} ca. $delayMin Min. verspätet',
                'sr_Latn': 'Kašnjenje na liniji ${line.code} (~$delayMin min)',
              },
              bodies: {
                'sl': 'Trenutne prometne razmere povzročajo približno $delayMin-minutno zamudo na liniji ${line.code} (${line.name}).',
                'en': 'Simulated traffic conditions are causing around $delayMin min delay on Line ${line.code} (${line.name}).',
                'de': 'Aktueller Verkehr verursacht ca. $delayMin Minuten Verspätung auf Linie ${line.code} (${line.name}).',
                'sr_Latn': 'Trenutni saobraćaj izaziva kašnjenje od oko $delayMin min na liniji ${line.code} (${line.name}).',
              },
              alternativeHint: {
                'sl': 'Preverite alternativne povezave na vozlišču Glavni trg ali UKC.',
                'en': 'Check alternative connections at Glavni trg or UKC hubs.',
                'de': 'Prüfen Sie Alternativen an den Knoten Glavni trg oder UKC.',
                'sr_Latn': 'Proverite alternativne veze na stajalištu Glavni trg ili UKC.',
              },
            ),
          );
          dynamicCount++;
        }
      }
    }

    base.sort((a, b) {
      final sevCompare = b.severity.index.compareTo(a.severity.index);
      if (sevCompare != 0) return sevCompare;
      return b.publishedAt.compareTo(a.publishedAt);
    });
    return base;
  }
}
