// Abstract repository contract for static and live-adjusted Marprom timetables.

import '../models/departure.dart';
import '../seed/seed_timetables.dart';

// TODO(firebase): Replace mock implementation with Cloud Functions / GTFS-RT departures feed.
/// Provides upcoming stop and line departures with offline caching support.
abstract class TimetableRepository {
  /// Returns upcoming departures at [stopId] around [at].
  Future<List<Departure>> getDeparturesForStop(
    String stopId, {
    required DateTime at,
    int limit = 20,
    bool? useSimulatedLive,
    bool isOffline = false,
  });

  /// Returns departures for a specific [lineId] and [directionId] on [at]'s date.
  Future<List<Departure>> getDeparturesForLine(
    String lineId,
    String directionId, {
    required DateTime at,
    DayScheduleType? scheduleType,
    String? stopId,
    bool? useSimulatedLive,
    bool isOffline = false,
  });

  /// Clears any locally cached timetable snapshots.
  Future<void> clearCache();
}
