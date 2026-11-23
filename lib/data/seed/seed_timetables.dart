// Rule-based mock Marprom timetable generator across weekday, Saturday, and holiday tiers.

import 'package:m_mobilnost/core/utils/geo.dart';

import '../models/bus_line.dart';
import 'seed_lines.dart';
import 'seed_stops.dart';

/// Operating calendar regimes used by the rule-based timetable generator.
enum DayScheduleType {
  /// Monday through Friday school/work schedule.
  weekday,

  /// Saturday reduced daytime service.
  saturday,

  /// Sunday and Slovenian public holiday service.
  sundayHoliday,
}

/// Represents one complete scheduled bus run along a [LineDirection].
class ScheduledTrip {
  /// Creates a [ScheduledTrip] with per-stop scheduled departure timestamps.
  const ScheduledTrip({
    required this.tripId,
    required this.lineId,
    required this.lineCode,
    required this.directionId,
    required this.directionName,
    required this.stopIds,
    required this.stopTimes,
  });

  /// Deterministic trip identifier (`lineId_dirId_YYYYMMDD_HHMM`).
  final String tripId;

  /// Associated line ID.
  final String lineId;

  /// Short line code.
  final String lineCode;

  /// Direction ID on the line.
  final String directionId;

  /// Human-readable direction title.
  final String directionName;

  /// Ordered stops served by this trip.
  final List<String> stopIds;

  /// Scheduled departure timestamps aligned index-for-index with [stopIds].
  final List<DateTime> stopTimes;

  /// Terminal departure time at the first stop.
  DateTime get startTime => stopTimes.first;

  /// Terminal arrival time at the final stop.
  DateTime get endTime => stopTimes.last;
}

/// Represents a single scheduled stop event extracted from a [ScheduledTrip].
class ScheduledStopEvent {
  /// Creates a [ScheduledStopEvent] for a stop index along a trip.
  const ScheduledStopEvent({
    required this.trip,
    required this.stopId,
    required this.stopIndex,
    required this.scheduledTime,
  });

  /// Parent trip run.
  final ScheduledTrip trip;

  /// Stop ID for this departure.
  final String stopId;

  /// Zero-based index of [stopId] within [ScheduledTrip.stopIds].
  final int stopIndex;

  /// Scheduled departure timestamp at [stopId].
  final DateTime scheduledTime;
}

class _LineFrequencyRule {
  const _LineFrequencyRule({
    required this.peakMinutes,
    required this.offPeakMinutes,
    required this.eveningMinutes,
    required this.weekendDayMinutes,
  });

  final int peakMinutes;
  final int offPeakMinutes;
  final int eveningMinutes;
  final int weekendDayMinutes;

  static const int firstMinuteOfDay = 5 * 60;
  static const int lastMinuteOfDay = 23 * 60 + 15;
}

const Map<String, _LineFrequencyRule> _lineRules = {
  '1': _LineFrequencyRule(peakMinutes: 10, offPeakMinutes: 30, eveningMinutes: 45, weekendDayMinutes: 30),
  '2': _LineFrequencyRule(peakMinutes: 12, offPeakMinutes: 30, eveningMinutes: 45, weekendDayMinutes: 30),
  '3': _LineFrequencyRule(peakMinutes: 12, offPeakMinutes: 30, eveningMinutes: 45, weekendDayMinutes: 35),
  '4': _LineFrequencyRule(peakMinutes: 15, offPeakMinutes: 35, eveningMinutes: 50, weekendDayMinutes: 40),
  '6': _LineFrequencyRule(peakMinutes: 10, offPeakMinutes: 30, eveningMinutes: 45, weekendDayMinutes: 30),
  '7': _LineFrequencyRule(peakMinutes: 15, offPeakMinutes: 35, eveningMinutes: 50, weekendDayMinutes: 40),
  '8': _LineFrequencyRule(peakMinutes: 20, offPeakMinutes: 45, eveningMinutes: 60, weekendDayMinutes: 45),
  '12': _LineFrequencyRule(peakMinutes: 15, offPeakMinutes: 35, eveningMinutes: 50, weekendDayMinutes: 40),
  '15': _LineFrequencyRule(peakMinutes: 15, offPeakMinutes: 40, eveningMinutes: 55, weekendDayMinutes: 45),
  '16': _LineFrequencyRule(peakMinutes: 20, offPeakMinutes: 45, eveningMinutes: 60, weekendDayMinutes: 50),
  '18': _LineFrequencyRule(peakMinutes: 20, offPeakMinutes: 50, eveningMinutes: 60, weekendDayMinutes: 60),
  '21': _LineFrequencyRule(peakMinutes: 15, offPeakMinutes: 35, eveningMinutes: 50, weekendDayMinutes: 40),
};

/// Determines the [DayScheduleType] for [date] including fixed Slovenian holidays.
DayScheduleType scheduleTypeForDate(DateTime date) {
  const fixedHolidays = {
    (1, 1), (1, 2), (2, 8), (4, 27), (5, 1), (5, 2),
    (6, 25), (8, 15), (10, 31), (11, 1), (12, 25), (12, 26),
  };
  if (fixedHolidays.contains((date.month, date.day)) ||
      date.weekday == DateTime.sunday) {
    return DayScheduleType.sundayHoliday;
  }
  if (date.weekday == DateTime.saturday) {
    return DayScheduleType.saturday;
  }
  return DayScheduleType.weekday;
}

/// Computes cumulative travel durations in seconds from the first stop of [direction].
List<int> computeStopOffsetsSeconds(LineDirection direction) {
  final offsets = <int>[0];
  var cumulative = 0;
  // Assume ~24 km/h average urban bus speed (6.67 m/s) plus 25s stop dwell.
  const metersPerSecond = 6.67;
  const dwellSeconds = 25;
  for (var i = 0; i < direction.stopIds.length - 1; i++) {
    final fromPos = seedStopsById[direction.stopIds[i]]?.position;
    final toPos = seedStopsById[direction.stopIds[i + 1]]?.position;
    final meters = (fromPos != null && toPos != null)
        ? GeoUtils.haversineMeters(fromPos, toPos)
        : 550.0;
    final segmentSeconds = (meters / metersPerSecond).round() + dwellSeconds;
    cumulative += segmentSeconds < 60 ? 60 : segmentSeconds;
    offsets.add(cumulative);
  }
  return offsets;
}

/// Generates all scheduled trips for [line] and [direction] on [date].
List<ScheduledTrip> generateTripsForDirection({
  required BusLine line,
  required LineDirection direction,
  required DateTime date,
  DayScheduleType? scheduleType,
}) {
  final type = scheduleType ?? scheduleTypeForDate(date);
  final rule = _lineRules[line.id] ??
      const _LineFrequencyRule(
        peakMinutes: 15,
        offPeakMinutes: 35,
        eveningMinutes: 55,
        weekendDayMinutes: 45,
      );
  final offsets = computeStopOffsetsSeconds(direction);
  final dayStart = DateTime(date.year, date.month, date.day);

  // Offset inbound starts slightly so outbound/inbound buses stagger naturally.
  final dirStagger = direction.id.endsWith('_in') ? 5 : 0;
  var cursorMinute = _LineFrequencyRule.firstMinuteOfDay +
      (type == DayScheduleType.sundayHoliday ? 60 : 0) +
      dirStagger;
  final endMinute = type == DayScheduleType.sundayHoliday
      ? _LineFrequencyRule.lastMinuteOfDay - 30
      : _LineFrequencyRule.lastMinuteOfDay;

  final trips = <ScheduledTrip>[];
  final dateTag =
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  while (cursorMinute <= endMinute) {
    final departure = dayStart.add(Duration(minutes: cursorMinute));
    final hhmm =
        '${departure.hour.toString().padLeft(2, '0')}${departure.minute.toString().padLeft(2, '0')}';
    trips.add(
      ScheduledTrip(
        tripId: '${direction.id}_${dateTag}_$hhmm',
        lineId: line.id,
        lineCode: line.code,
        directionId: direction.id,
        directionName: direction.name,
        stopIds: direction.stopIds,
        stopTimes: [
          for (final offset in offsets)
            departure.add(Duration(seconds: offset)),
        ],
      ),
    );
    cursorMinute += _headwayMinutes(cursorMinute, type, rule);
  }
  return trips;
}

int _headwayMinutes(
  int minuteOfDay,
  DayScheduleType type,
  _LineFrequencyRule rule,
) {
  final isEvening = minuteOfDay >= 20 * 60;
  if (isEvening) {
    return type == DayScheduleType.sundayHoliday
        ? (rule.eveningMinutes + 10).clamp(45, 60)
        : rule.eveningMinutes;
  }
  if (type == DayScheduleType.saturday) {
    return rule.weekendDayMinutes;
  }
  if (type == DayScheduleType.sundayHoliday) {
    return (rule.weekendDayMinutes + 15).clamp(35, 60);
  }
  final isMorningPeak = minuteOfDay >= 6 * 60 + 30 && minuteOfDay <= 9 * 60;
  final isAfternoonPeak = minuteOfDay >= 13 * 60 + 30 && minuteOfDay <= 17 * 60;
  if (isMorningPeak || isAfternoonPeak) {
    return rule.peakMinutes;
  }
  return rule.offPeakMinutes;
}

/// Returns all scheduled departures at [stopId] on [date], sorted chronologically.
List<ScheduledStopEvent> generateStopScheduleForDate({
  required String stopId,
  required DateTime date,
  DayScheduleType? scheduleType,
}) {
  final type = scheduleType ?? scheduleTypeForDate(date);
  final events = <ScheduledStopEvent>[];
  for (final line in seedLines) {
    for (final direction in line.directions) {
      final stopIdx = direction.stopIds.indexOf(stopId);
      if (stopIdx == -1) continue;
      final trips = generateTripsForDirection(
        line: line,
        direction: direction,
        date: date,
        scheduleType: type,
      );
      for (final trip in trips) {
        events.add(
          ScheduledStopEvent(
            trip: trip,
            stopId: stopId,
            stopIndex: stopIdx,
            scheduledTime: trip.stopTimes[stopIdx],
          ),
        );
      }
    }
  }
  events.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  return events;
}
