// Shared Riverpod providers and formatting helpers for lines, stops, and departures.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m_mobilnost/core/widgets/status_chip.dart';
import 'package:m_mobilnost/data/models/bus_line.dart';
import 'package:m_mobilnost/data/models/bus_stop.dart';
import 'package:m_mobilnost/data/repositories/repository_providers.dart';
import 'package:m_mobilnost/data/seed/seed_timetables.dart';
import 'package:m_mobilnost/l10n/app_localizations.dart';

/// Loads all Maribor city bus lines from [lineRepositoryProvider].
final allLinesProvider = FutureProvider<List<BusLine>>((ref) {
  return ref.watch(lineRepositoryProvider).getLines();
});

/// Loads all Maribor city bus stops from [lineRepositoryProvider].
final allStopsProvider = FutureProvider<List<BusStop>>((ref) {
  return ref.watch(lineRepositoryProvider).getStops();
});

/// Looks up a single [BusLine] by [lineId] from [lineRepositoryProvider].
final lineByIdProvider =
    FutureProvider.family<BusLine?, String>((ref, lineId) {
  return ref.watch(lineRepositoryProvider).getLineById(lineId);
});

/// Looks up a single [BusStop] by [stopId] from [lineRepositoryProvider].
final stopByIdProvider =
    FutureProvider.family<BusStop?, String>((ref, stopId) {
  return ref.watch(lineRepositoryProvider).getStopById(stopId);
});

/// Formats [dateTime] in 24-hour `HH:mm:ss` format for freshness timestamps.
String formatTime24Hms(DateTime dateTime) {
  final hh = dateTime.hour.toString().padLeft(2, '0');
  final mm = dateTime.minute.toString().padLeft(2, '0');
  final ss = dateTime.second.toString().padLeft(2, '0');
  return '$hh:$mm:$ss';
}

/// Returns the localized delay or disruption label for [status] and [delaySeconds].
String localizedDelayStatusLabel(
  AppLocalizations l10n,
  TransitStatusType status,
  int delaySeconds, {
  bool isCancelled = false,
}) {
  if (isCancelled || status == TransitStatusType.disruption) {
    return l10n.statusCancelled;
  }
  switch (status) {
    case TransitStatusType.early:
      final mins = ((-delaySeconds) / 60).ceil().clamp(1, 99);
      return l10n.statusEarlyByMinutes(mins);
    case TransitStatusType.onTime:
      return l10n.statusOnTime;
    case TransitStatusType.late:
      final mins = (delaySeconds / 60).ceil().clamp(1, 99);
      return l10n.statusLateByMinutes(mins);
    case TransitStatusType.warning:
      return l10n.statusWarning;
    case TransitStatusType.info:
      return l10n.statusInfo;
    case TransitStatusType.disruption:
      return l10n.statusDisruption;
  }
}

/// Returns the localized label for a calendar [DayScheduleType].
String localizedDayScheduleLabel(AppLocalizations l10n, DayScheduleType type) {
  switch (type) {
    case DayScheduleType.weekday:
      return l10n.linesScheduleWeekday;
    case DayScheduleType.saturday:
      return l10n.linesScheduleSaturday;
    case DayScheduleType.sundayHoliday:
      return l10n.linesScheduleSunday;
  }
}

/// Formats relative departure countdown text for [targetTime] relative to [now].
String localizedCountdownLabel(
  AppLocalizations l10n,
  DateTime targetTime,
  DateTime now,
) {
  final diffMin = targetTime.difference(now).inMinutes;
  if (diffMin <= 0) {
    return l10n.statusArrivingNow;
  }
  return l10n.statusDepartingIn(diffMin);
}
