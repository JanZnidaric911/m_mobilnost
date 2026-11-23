// Mock TimetableRepository merging rule-based schedules with DelayModel and Hive cache.

import 'package:m_mobilnost/core/network/data_freshness.dart';

import '../models/departure.dart';
import '../models/occupancy.dart';
import '../repositories/timetable_repository.dart';
import '../seed/seed_lines.dart';
import '../seed/seed_timetables.dart';
import '../simulation/delay_model.dart';
import '../simulation/occupancy_model.dart';
import 'local_storage_helper.dart';

/// Mock [TimetableRepository] combining rule-based schedules with deterministic
/// simulated delays/occupancy and safe Hive offline caching.
class MockTimetableRepository implements TimetableRepository {
  /// Creates a [MockTimetableRepository] with optional live-mode callbacks.
  MockTimetableRepository({
    DelayModel? delayModel,
    OccupancyModel? occupancyModel,
    bool Function()? isSimulatedLiveEnabled,
    bool Function()? isOfflineCheck,
    String cacheBoxName = 'm_mobilnost_timetable_cache',
  })  : _delayModel = delayModel ?? const DelayModel(),
        _occupancyModel = occupancyModel ?? const OccupancyModel(),
        _isSimulatedLiveEnabled = isSimulatedLiveEnabled ?? (() => true),
        _isOfflineCheck = isOfflineCheck ?? (() => false),
        _cache = LocalKeyValueStore(cacheBoxName);

  final DelayModel _delayModel;
  final OccupancyModel _occupancyModel;
  final bool Function() _isSimulatedLiveEnabled;
  final bool Function() _isOfflineCheck;
  final LocalKeyValueStore _cache;

  @override
  Future<List<Departure>> getDeparturesForStop(
    String stopId, {
    required DateTime at,
    int limit = 20,
    bool? useSimulatedLive,
    bool isOffline = false,
  }) async {
    final effectiveLive =
        (useSimulatedLive ?? _isSimulatedLiveEnabled()) &&
            !isOffline &&
            !_isOfflineCheck();
    final cutoff = at.subtract(const Duration(minutes: 2));

    // Read cached timestamp if offline/live-disabled so freshness age stays accurate.
    DateTime? cachedAt;
    if (!effectiveLive) {
      final rawMeta = await _cache.read('meta_stop_$stopId');
      if (rawMeta is String) {
        cachedAt = DateTime.tryParse(rawMeta);
      }
    }

    final events = [
      ...generateStopScheduleForDate(stopId: stopId, date: at),
      if (at.hour >= 21)
        ...generateStopScheduleForDate(
          stopId: stopId,
          date: at.add(const Duration(days: 1)),
        ),
    ];

    final freshness = DataFreshness(
      kind: effectiveLive ? DataSourceKind.simulated : DataSourceKind.cached,
      updatedAt: effectiveLive ? at : (cachedAt ?? at),
    );

    final departures = <Departure>[];
    for (final event in events) {
      final trip = event.trip;
      final delaySec = effectiveLive
          ? _delayModel.delaySecondsForTrip(
              tripId: trip.tripId,
              lineId: trip.lineId,
              scheduledTime: trip.startTime,
              stopIndex: event.stopIndex,
              totalStops: trip.stopIds.length,
            )
          : 0;
      final estimated = event.scheduledTime.add(Duration(seconds: delaySec));
      if (estimated.isBefore(cutoff)) continue;

      final isCancelled = effectiveLive &&
          _delayModel.isTripCancelled(
            tripId: trip.tripId,
            lineId: trip.lineId,
            scheduledTime: trip.startTime,
          );

      final occupancy = effectiveLive
          ? _estimateStopOccupancy(event, at)
          : BusOccupancyLevel.unknown;

      departures.add(
        Departure(
          id: '${trip.tripId}_${stopId}_${event.stopIndex}',
          lineId: trip.lineId,
          lineCode: trip.lineCode,
          directionId: trip.directionId,
          directionName: trip.directionName,
          stopId: stopId,
          scheduledTime: event.scheduledTime,
          delaySeconds: delaySec,
          isCancelled: isCancelled,
          occupancy: occupancy,
          freshness: freshness,
        ),
      );
    }

    departures.sort((a, b) => a.estimatedTime.compareTo(b.estimatedTime));
    final result = departures.take(limit).toList(growable: false);

    if (effectiveLive) {
      await _cache.write(
        'stop_$stopId',
        result.map((d) => d.toJson()).toList(growable: false),
      );
      await _cache.write('meta_stop_$stopId', at.toIso8601String());
    } else if (cachedAt == null) {
      await _cache.write('meta_stop_$stopId', at.toIso8601String());
    }

    return result;
  }

  @override
  Future<List<Departure>> getDeparturesForLine(
    String lineId,
    String directionId, {
    required DateTime at,
    DayScheduleType? scheduleType,
    String? stopId,
    bool? useSimulatedLive,
    bool isOffline = false,
  }) async {
    final line = seedLinesById[lineId];
    final direction = line?.directionById(directionId);
    if (line == null || direction == null || direction.stopIds.isEmpty) {
      return const [];
    }

    final targetStopId = stopId ?? direction.stopIds.first;
    final stopIdx = direction.stopIds.indexOf(targetStopId);
    if (stopIdx == -1) return const [];

    final effectiveLive =
        (useSimulatedLive ?? _isSimulatedLiveEnabled()) &&
            !isOffline &&
            !_isOfflineCheck();
    final trips = generateTripsForDirection(
      line: line,
      direction: direction,
      date: at,
      scheduleType: scheduleType,
    );

    final freshness = DataFreshness(
      kind: effectiveLive ? DataSourceKind.simulated : DataSourceKind.cached,
      updatedAt: at,
    );

    return [
      for (final trip in trips)
        Departure(
          id: '${trip.tripId}_${targetStopId}_$stopIdx',
          lineId: line.id,
          lineCode: line.code,
          directionId: direction.id,
          directionName: direction.name,
          stopId: targetStopId,
          scheduledTime: trip.stopTimes[stopIdx],
          delaySeconds: effectiveLive
              ? _delayModel.delaySecondsForTrip(
                  tripId: trip.tripId,
                  lineId: line.id,
                  scheduledTime: trip.startTime,
                  stopIndex: stopIdx,
                  totalStops: trip.stopIds.length,
                )
              : 0,
          isCancelled: effectiveLive &&
              _delayModel.isTripCancelled(
                tripId: trip.tripId,
                lineId: line.id,
                scheduledTime: trip.startTime,
              ),
          occupancy: effectiveLive
              ? _occupancyModel
                  .estimateSegment(
                    lineId: line.id,
                    directionId: direction.id,
                    fromStopId: targetStopId,
                    toStopId: stopIdx + 1 < direction.stopIds.length
                        ? direction.stopIds[stopIdx + 1]
                        : targetStopId,
                    at: trip.stopTimes[stopIdx],
                  )
                  .level
              : BusOccupancyLevel.unknown,
          freshness: freshness,
        ),
    ];
  }

  BusOccupancyLevel _estimateStopOccupancy(
    ScheduledStopEvent event,
    DateTime at,
  ) {
    final stops = event.trip.stopIds;
    final nextIdx =
        event.stopIndex + 1 < stops.length ? event.stopIndex + 1 : event.stopIndex;
    final prevIdx = event.stopIndex > 0 ? event.stopIndex - 1 : 0;
    final fromStop = nextIdx != event.stopIndex ? event.stopId : stops[prevIdx];
    final toStop = stops[nextIdx];
    return _occupancyModel
        .estimateSegment(
          lineId: event.trip.lineId,
          directionId: event.trip.directionId,
          fromStopId: fromStop,
          toStopId: toStop,
          at: at,
        )
        .level;
  }

  @override
  Future<void> clearCache() => _cache.clear();
}
