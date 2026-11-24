// Rule-based offline transit assistant answering Marprom questions in 4 languages.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/data_freshness.dart';
import '../../../core/utils/distance.dart';
import '../../../core/utils/geo.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/models/bus_line.dart';
import '../../../data/models/bus_stop.dart';
import '../../../data/models/departure.dart';
import '../../../data/models/service_notice.dart';
import '../../../data/models/ticket_type.dart';
import '../../../data/repositories/line_repository.dart';
import '../../../data/repositories/notice_repository.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/ticket_repository.dart';
import '../../../data/repositories/timetable_repository.dart';
import '../../../data/repositories/trip_repository.dart';
import '../../../data/seed/seed_tickets.dart';
import '../../../l10n/app_localizations.dart';

/// Intent categories recognized by [AskMarpromAssistant].
enum AskIntent {
  /// Upcoming departures from a stop or for a specific bus line.
  nextBus,

  /// Active service disruptions, delays, detours, or notices.
  disruptions,

  /// Nearest bus stop relative to the rider's current/manual location.
  nearestStop,

  /// Ticket pricing and cheapest or best pass recommendations.
  ticket,

  /// General line route and schedule information.
  lineInfo,

  /// Fallback when no domain intent matched clearly.
  unknown,
}

/// Structured localized answer produced by [AskMarpromAssistant].
@immutable
class AskMarpromReply {
  /// Creates an [AskMarpromReply] with localized text and optional route CTA.
  const AskMarpromReply({
    required this.text,
    required this.intent,
    this.suggestedRoute,
    this.actionLabel,
    this.freshness,
  });

  /// Localized user-facing response text.
  final String text;

  /// Classified intent for analytics/testing without storing raw queries.
  final AskIntent intent;

  /// Optional GoRouter path for quick follow-up navigation.
  final String? suggestedRoute;

  /// Optional localized label for the follow-up navigation button.
  final String? actionLabel;

  /// Freshness metadata when live/cached timetable data was consulted.
  final DataFreshness? freshness;
}

/// Riverpod provider exposing [AskMarpromAssistant] wired to app repositories.
final askMarpromProvider = Provider<AskMarpromAssistant>((ref) {
  return AskMarpromAssistant(
    lineRepository: ref.watch(lineRepositoryProvider),
    timetableRepository: ref.watch(timetableRepositoryProvider),
    noticeRepository: ref.watch(noticeRepositoryProvider),
    tripRepository: ref.watch(tripRepositoryProvider),
    ticketRepository: ref.watch(ticketRepositoryProvider),
  );
});

/// Deterministic, offline-capable rule-based assistant for Marprom bus inquiries.
class AskMarpromAssistant {
  /// Creates an [AskMarpromAssistant] backed by Marprom data repositories.
  const AskMarpromAssistant({
    required LineRepository lineRepository,
    required TimetableRepository timetableRepository,
    required NoticeRepository noticeRepository,
    required TripRepository tripRepository,
    TicketRepository? ticketRepository,
  })  : _lines = lineRepository,
        _timetables = timetableRepository,
        _notices = noticeRepository,
        _trips = tripRepository,
        _tickets = ticketRepository;

  final LineRepository _lines;
  final TimetableRepository _timetables;
  final NoticeRepository _notices;
  final TripRepository _trips;
  final TicketRepository? _tickets;

  /// Answers a natural-language [query] in any supported language using [l10n].
  Future<AskMarpromReply> ask(
    String query, {
    required AppLocalizations l10n,
    String localeCode = 'sl',
    LatLng userPosition = GeoUtils.mariborCenter,
    String? preferredStopId,
    DateTime? now,
    bool useSimulatedLive = true,
    bool isOffline = false,
  }) async {
    final normalized = _normalize(query);
    if (normalized.isEmpty) {
      return AskMarpromReply(
        text: l10n.askNoMatch,
        intent: AskIntent.unknown,
        suggestedRoute: '/plan',
        actionLabel: l10n.homePlanTripAction,
      );
    }

    final refNow = now ?? DateTime.now();
    final lines = await _lines.getLines();
    final stops = await _lines.getStops();
    final matchedLine = _matchLine(normalized, lines);
    final matchedStop = _matchStop(normalized, stops);

    if (_matchesDisruptionIntent(normalized)) {
      return _answerDisruptions(
        l10n: l10n,
        localeCode: localeCode,
        now: refNow,
        useSimulatedLive: useSimulatedLive,
        lineFilter: matchedLine,
      );
    }

    if (_matchesTicketIntent(normalized)) {
      return _answerTickets(
        l10n: l10n,
        localeCode: localeCode,
        queryNormalized: normalized,
      );
    }

    if (_matchesNearestStopIntent(normalized) &&
        matchedStop == null &&
        matchedLine == null) {
      return _answerNearestStop(
        l10n: l10n,
        userPosition: userPosition,
        now: refNow,
        useSimulatedLive: useSimulatedLive,
        isOffline: isOffline,
      );
    }

    if (matchedStop != null ||
        matchedLine != null ||
        _matchesNextBusIntent(normalized)) {
      return _answerDepartures(
        l10n: l10n,
        now: refNow,
        userPosition: userPosition,
        preferredStopId: preferredStopId,
        matchedStop: matchedStop,
        matchedLine: matchedLine,
        stops: stops,
        useSimulatedLive: useSimulatedLive,
        isOffline: isOffline,
      );
    }

    if (_matchesNearestStopIntent(normalized)) {
      return _answerNearestStop(
        l10n: l10n,
        userPosition: userPosition,
        now: refNow,
        useSimulatedLive: useSimulatedLive,
        isOffline: isOffline,
      );
    }

    return AskMarpromReply(
      text: l10n.askNoMatch,
      intent: AskIntent.unknown,
      suggestedRoute: '/plan',
      actionLabel: l10n.homePlanTripAction,
    );
  }

  Future<AskMarpromReply> _answerDisruptions({
    required AppLocalizations l10n,
    required String localeCode,
    required DateTime now,
    required bool useSimulatedLive,
    BusLine? lineFilter,
  }) async {
    final allNotices = await _notices.getNotices(
      useSimulatedLive: useSimulatedLive,
      at: now,
    );

    final filtered = lineFilter == null
        ? allNotices
        : allNotices
            .where((n) => n.affectedLineIds.contains(lineFilter.id))
            .toList(growable: false);

    final prioritized = filtered
        .where(
          (n) =>
              n.severity == NoticeSeverity.disruption ||
              n.severity == NoticeSeverity.delay,
        )
        .toList(growable: false);

    final display = prioritized.isNotEmpty ? prioritized : filtered;
    if (display.isEmpty) {
      return AskMarpromReply(
        text: l10n.noticesEmpty,
        intent: AskIntent.disruptions,
        suggestedRoute: '/notices',
        actionLabel: l10n.navNotices,
      );
    }

    final buffer = StringBuffer();
    for (final notice in display.take(3)) {
      if (buffer.isNotEmpty) buffer.writeln();
      final status = switch (notice.severity) {
        NoticeSeverity.disruption => l10n.statusDisruption,
        NoticeSeverity.delay => l10n.statusLate,
        NoticeSeverity.info => l10n.statusInfo,
      };
      buffer.write('[$status] ${notice.localizedTitle(localeCode)}');
      if (notice.affectedLineIds.isNotEmpty) {
        buffer.write(
          ' (${l10n.noticesAffectedLines(notice.affectedLineIds.join(', '))})',
        );
      }
      final hint = notice.localizedAlternativeHint(localeCode);
      if (hint != null && hint.isNotEmpty) {
        buffer.write(' — $hint');
      }
    }

    return AskMarpromReply(
      text: buffer.toString(),
      intent: AskIntent.disruptions,
      suggestedRoute: '/notices',
      actionLabel: l10n.navNotices,
    );
  }

  Future<AskMarpromReply> _answerTickets({
    required AppLocalizations l10n,
    required String localeCode,
    required String queryNormalized,
  }) async {
    final types = _tickets != null
        ? await _tickets.getTicketTypes()
        : List<TicketType>.unmodifiable(seedTicketTypes);
    if (types.isEmpty) {
      return AskMarpromReply(
        text: l10n.commonEmpty,
        intent: AskIntent.ticket,
        suggestedRoute: '/tickets/shop',
        actionLabel: l10n.homeBuyTicketAction,
      );
    }

    final sorted = List<TicketType>.from(types)
      ..sort((a, b) => a.priceEur.compareTo(b.priceEur));
    final cheapestDiscounted = sorted.first;
    final cheapestStandard = sorted.firstWhere(
      (t) => !t.isYouthOnly && !t.isSeniorOnly,
      orElse: () => cheapestDiscounted,
    );
    final dayPass = sorted.firstWhere(
      (t) => t.id == 'day_24h',
      orElse: () => cheapestStandard,
    );

    final wantsToday = queryNormalized.contains('danes') ||
        queryNormalized.contains('today') ||
        queryNormalized.contains('heute') ||
        queryNormalized.contains('danas') ||
        queryNormalized.contains('dnevn') ||
        queryNormalized.contains('day');

    final lines = <String>[
      '• ${cheapestStandard.localizedTitle(localeCode)}: '
          '${TimeFormatUtils.formatEur(cheapestStandard.priceEur, locale: localeCode)}',
      if (cheapestDiscounted.id != cheapestStandard.id)
        '• ${cheapestDiscounted.localizedTitle(localeCode)}: '
            '${TimeFormatUtils.formatEur(cheapestDiscounted.priceEur, locale: localeCode)}',
      if (wantsToday && dayPass.id != cheapestStandard.id)
        '• ${dayPass.localizedTitle(localeCode)}: '
            '${TimeFormatUtils.formatEur(dayPass.priceEur, locale: localeCode)}',
    ];

    return AskMarpromReply(
      text: '${l10n.ticketsZoneMaribor}:\n${lines.join('\n')}',
      intent: AskIntent.ticket,
      suggestedRoute: '/tickets/shop',
      actionLabel: l10n.homeBuyTicketAction,
    );
  }

  Future<AskMarpromReply> _answerNearestStop({
    required AppLocalizations l10n,
    required LatLng userPosition,
    required DateTime now,
    required bool useSimulatedLive,
    required bool isOffline,
  }) async {
    final nearest = await _trips.findNearestStop(userPosition);
    if (nearest == null) {
      return AskMarpromReply(
        text: l10n.mapNoNearbyStops,
        intent: AskIntent.nearestStop,
        suggestedRoute: '/nearest-stop',
        actionLabel: l10n.homeNearestStopAction,
      );
    }

    final meters = GeoUtils.haversineMeters(userPosition, nearest.position);
    final walkMin = DistanceUtils.estimateWalkMinutes(meters);
    final distLabel = DistanceUtils.formatMeters(meters, l10n);

    final departures = await _timetables.getDeparturesForStop(
      nearest.id,
      at: now,
      limit: 2,
      useSimulatedLive: useSimulatedLive,
      isOffline: isOffline,
    );

    final buffer = StringBuffer(
      '${nearest.name} — ${l10n.nearestStopDistance(distLabel)}, '
      '${l10n.nearestStopWalkTime(walkMin)}.',
    );

    if (departures.isNotEmpty) {
      final first = departures.first;
      final mins = first.estimatedTime.difference(now).inMinutes;
      final timing = mins <= 0
          ? l10n.statusArrivingNow
          : l10n.statusDepartingIn(mins);
      buffer.write(
        '\n${l10n.nearestStopNextBus}: ${l10n.linesBadge(first.lineCode)} '
        '(${first.directionName}) • ${TimeFormatUtils.formatTime24(first.estimatedTime)} ($timing)',
      );
    }

    return AskMarpromReply(
      text: buffer.toString(),
      intent: AskIntent.nearestStop,
      suggestedRoute: '/nearest-stop',
      actionLabel: l10n.homeNearestStopAction,
      freshness: departures.isNotEmpty ? departures.first.freshness : null,
    );
  }

  Future<AskMarpromReply> _answerDepartures({
    required AppLocalizations l10n,
    required DateTime now,
    required LatLng userPosition,
    required String? preferredStopId,
    required BusStop? matchedStop,
    required BusLine? matchedLine,
    required List<BusStop> stops,
    required bool useSimulatedLive,
    required bool isOffline,
  }) async {
    BusStop? candidateStop = matchedStop;
    if (candidateStop == null && preferredStopId != null) {
      for (final s in stops) {
        if (s.id == preferredStopId) {
          candidateStop = s;
          break;
        }
      }
    }
    if (candidateStop == null && matchedLine != null) {
      final firstId = matchedLine.directions.first.stopIds.first;
      for (final s in stops) {
        if (s.id == firstId) {
          candidateStop = s;
          break;
        }
      }
    }
    candidateStop ??= await _trips.findNearestStop(userPosition);
    if (candidateStop == null) {
      return AskMarpromReply(
        text: l10n.stopNoDepartures,
        intent: AskIntent.nextBus,
        suggestedRoute: '/lines',
        actionLabel: l10n.homeLinesAction,
      );
    }

    var stop = candidateStop;

    // If user asked about a line that does not serve the preferred stop, switch
    // to that line's origin stop so they still receive real departure data.
    if (matchedLine != null &&
        matchedStop == null &&
        !stop.lineIds.contains(matchedLine.id)) {
      final lineStopId = matchedLine.directions.first.stopIds.first;
      for (final s in stops) {
        if (s.id == lineStopId) {
          stop = s;
          break;
        }
      }
    }

    var departures = await _timetables.getDeparturesForStop(
      stop.id,
      at: now,
      limit: 16,
      useSimulatedLive: useSimulatedLive,
      isOffline: isOffline,
    );

    if (matchedLine != null) {
      departures = departures
          .where((d) => d.lineId == matchedLine.id)
          .toList(growable: false);
    }

    if (departures.isEmpty) {
      return AskMarpromReply(
        text: '${stop.name}: ${l10n.stopNoDepartures}',
        intent: matchedLine != null && matchedStop == null
            ? AskIntent.lineInfo
            : AskIntent.nextBus,
        suggestedRoute: matchedLine != null
            ? '/lines/${matchedLine.id}'
            : '/stops/${stop.id}',
        actionLabel: matchedLine != null
            ? l10n.homeLinesAction
            : l10n.mapStopDetailsOpen,
      );
    }

    final lines = <String>[];
    for (final dep in departures.take(3)) {
      lines.add('• ${_formatDepartureLine(dep, now, l10n)}');
    }

    final header = matchedLine != null
        ? '${l10n.linesBadge(matchedLine.code)} (${stop.name})'
        : '${stop.name} — ${l10n.homeNextDepartures}';

    return AskMarpromReply(
      text: '$header:\n${lines.join('\n')}',
      intent: matchedLine != null && matchedStop == null
          ? AskIntent.lineInfo
          : AskIntent.nextBus,
      suggestedRoute: matchedLine != null
          ? '/lines/${matchedLine.id}'
          : '/stops/${stop.id}',
      actionLabel: matchedLine != null
          ? l10n.linesFollowBusLive
          : l10n.mapStopDetailsOpen,
      freshness: departures.first.freshness,
    );
  }

  String _formatDepartureLine(
    Departure dep,
    DateTime now,
    AppLocalizations l10n,
  ) {
    final mins = dep.estimatedTime.difference(now).inMinutes;
    final etaText =
        mins <= 0 ? l10n.statusArrivingNow : l10n.statusDepartingIn(mins);
    final timeText = TimeFormatUtils.formatTime24(dep.estimatedTime);
    final statusText = _formatDelayStatus(dep, l10n);
    return '${l10n.linesBadge(dep.lineCode)} (${dep.directionName}) • '
        '$timeText ($etaText, $statusText)';
  }

  String _formatDelayStatus(Departure dep, AppLocalizations l10n) {
    if (dep.isCancelled) return l10n.statusCancelled;
    if (dep.delaySeconds < -60) {
      return l10n.statusEarlyByMinutes((-dep.delaySeconds / 60).round());
    }
    if (dep.delaySeconds > 120) {
      return l10n.statusLateByMinutes((dep.delaySeconds / 60).round());
    }
    return l10n.statusOnTime;
  }

  BusLine? _matchLine(String normalizedQuery, List<BusLine> lines) {
    final gpMatch = RegExp(r'\b([gp]\s*\d{1,2})\b').firstMatch(normalizedQuery);
    if (gpMatch != null) {
      final code = gpMatch.group(1)!.replaceAll(' ', '').toUpperCase();
      for (final line in lines) {
        if (line.code.toUpperCase() == code) return line;
      }
    }

    final explicitMatch = RegExp(
      r'(?:linij[aeuo]?|line|linie|liniju|bus|avtobus|autobus)\s*#?\s*([gp]?\d{1,2})\b',
    ).firstMatch(normalizedQuery);
    if (explicitMatch != null) {
      final raw = explicitMatch.group(1)!.toUpperCase();
      for (final line in lines) {
        if (line.code.toUpperCase() == raw ||
            line.code.toUpperCase() == 'G$raw' ||
            line.code.toUpperCase() == 'P$raw') {
          return line;
        }
      }
    }

    // Avoid matching clock times like "10:40" as line codes.
    final strippedTimes =
        normalizedQuery.replaceAll(RegExp(r'\b\d{1,2}:\d{2}\b'), ' ');
    for (final match in RegExp(r'\b(\d{1,2})\b').allMatches(strippedTimes)) {
      final raw = match.group(1)!;
      for (final line in lines) {
        if (line.code == raw ||
            line.code == 'G$raw' ||
            line.code == 'P$raw') {
          return line;
        }
      }
    }
    return null;
  }

  BusStop? _matchStop(String normalizedQuery, List<BusStop> stops) {
    final queryTokens = normalizedQuery
        .split(' ')
        .where((t) => t.length >= 3)
        .toList(growable: false);
    if (queryTokens.isEmpty) return null;

    BusStop? bestStop;
    var bestScore = 0.0;

    for (final stop in stops) {
      final stopNorm = _normalize(stop.name);
      final idNorm = _normalize(stop.id.replaceAll('_', ' '));

      if (normalizedQuery.contains(stopNorm) ||
          normalizedQuery.contains(idNorm)) {
        final exactScore = 100.0 + stopNorm.length;
        if (exactScore > bestScore) {
          bestScore = exactScore;
          bestStop = stop;
        }
        continue;
      }

      final stopTokens = <String>{
        ...stopNorm.split(' ').where((t) => t.length >= 3),
        ...idNorm.split(' ').where((t) => t.length >= 3),
      }.toList(growable: false);
      if (stopTokens.isEmpty) continue;

      var matchedCount = 0;
      var matchedNonGenericToken = false;
      for (final sTok in stopTokens) {
        final sStem = sTok.length >= 4 ? sTok.substring(0, 4) : sTok;
        final hasMatch = queryTokens.any((qTok) {
          if (qTok == sTok) return true;
          if (sTok.length == 3 && qTok.length <= 5 && qTok.startsWith(sTok)) {
            return true;
          }
          if (sTok.length >= 4 && qTok.length >= 4) {
            return qTok.startsWith(sStem) || sTok.startsWith(qTok.substring(0, 4));
          }
          return false;
        });
        if (hasMatch) {
          matchedCount++;
          if (sTok != 'maribor' &&
              sTok != 'cesta' &&
              sTok != 'glavni' &&
              sTok != 'glavna' &&
              sTok != 'avtobusna' &&
              sTok != 'postaja' &&
              sTok != 'cona') {
            matchedNonGenericToken = true;
          }
        }
      }

      if (matchedCount == 0) continue;
      final nameWords =
          stopNorm.split(' ').where((t) => t.length >= 3).length.clamp(1, 10);
      final ratio = matchedCount / nameWords;
      final score = matchedCount * 10.0 + ratio;

      // Require either a multi-word match or a specific non-generic stop token.
      if ((matchedCount >= 2 || matchedNonGenericToken) && score > bestScore) {
        bestScore = score;
        bestStop = stop;
      }
    }
    return bestStop;
  }

  bool _matchesDisruptionIntent(String q) {
    const keywords = [
      'motnj',
      'obvoz',
      'zamud',
      'obvestil',
      'odpoved',
      'disrupt',
      'detour',
      'delay',
      'notice',
      'cancel',
      'alert',
      'storung',
      'umleitung',
      'verspat',
      'ausfall',
      'meldung',
      'smetnj',
      'obilaz',
      'kasnj',
      'otkaz',
      'obavest',
    ];
    return keywords.any(q.contains);
  }

  bool _matchesTicketIntent(String q) {
    const keywords = [
      'vozovnic',
      'karta',
      'kart',
      'cen',
      'najugodnej',
      'najcenej',
      'cenej',
      'kup',
      'ticket',
      'cheap',
      'price',
      'fare',
      'pass',
      'fahrkart',
      'billig',
      'gunstig',
      'preis',
      'jeftin',
      'povoljn',
    ];
    return keywords.any(q.contains);
  }

  bool _matchesNearestStopIntent(String q) {
    const keywords = [
      'najbliz',
      'nearest',
      'closest',
      'nearby',
      'nachst',
      'kje je',
      'where is',
      'wo ist',
      'gde je',
    ];
    return keywords.any(q.contains);
  }

  bool _matchesNextBusIntent(String q) {
    const keywords = [
      'kdaj',
      'naslednj',
      'avtobus',
      'odhod',
      'linij',
      'pelje',
      'vozi',
      'when',
      'next',
      'bus',
      'depart',
      'line',
      'wann',
      'abfahrt',
      'linie',
      'kad',
      'sledec',
      'autobus',
      'polaz',
      'krece',
    ];
    return keywords.any(q.contains);
  }

  static String _normalize(String input) {
    final lower = input.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      switch (ch) {
        case 'č':
        case 'ć':
          buffer.write('c');
        case 'š':
          buffer.write('s');
        case 'ž':
          buffer.write('z');
        case 'đ':
          buffer.write('d');
        case 'ä':
          buffer.write('a');
        case 'ö':
          buffer.write('o');
        case 'ü':
          buffer.write('u');
        case 'ß':
          buffer.write('ss');
        default:
          if (RegExp(r'[a-z0-9:]').hasMatch(ch)) {
            buffer.write(ch);
          } else {
            buffer.write(' ');
          }
      }
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
