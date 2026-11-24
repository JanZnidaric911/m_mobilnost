// Deterministic seeded bus delay model with rush-hour bias and status mapping.

import 'dart:math' as math;

import 'package:m_mobilnost/core/widgets/status_chip.dart';

/// Produces deterministic simulated delays for Marprom bus trips and stops.
class DelayModel {
  /// Creates a [DelayModel] driven by a deterministic [seed].
  const DelayModel({this.seed = 42});

  /// Seed controlling deterministic delay generation across runs.
  final int seed;

  /// Maps signed [delaySeconds] to semantic [TransitStatusType] thresholds:
  /// `< -60s` -> `early`, `-60..+120s` -> `onTime`, `> +120s` -> `late`.
  static TransitStatusType statusForDelay(int delaySeconds) {
    if (delaySeconds < -60) return TransitStatusType.early;
    if (delaySeconds <= 120) return TransitStatusType.onTime;
    return TransitStatusType.late;
  }

  /// Computes deterministic delay in seconds for a trip at [scheduledTime].
  int delaySecondsForTrip({
    required String tripId,
    required String lineId,
    required DateTime scheduledTime,
    int stopIndex = 0,
    int totalStops = 1,
  }) {
    final tripHash = _stableHash('$seed|$lineId|$tripId');
    final rng = math.Random(tripHash);

    final minuteOfDay = scheduledTime.hour * 60 + scheduledTime.minute;
    final isWeekday = scheduledTime.weekday <= DateTime.friday;
    final isRushHour = isWeekday &&
        ((minuteOfDay >= 7 * 60 && minuteOfDay <= 9 * 60) ||
            (minuteOfDay >= 14 * 60 && minuteOfDay <= 17 * 60 + 30));

    // Roll determines regime: occasional early (-1..-3 min), normal drift, or late (+4..+8 min).
    final roll = rng.nextDouble();
    final earlyCutoff = isRushHour ? 0.05 : 0.12;
    final lateCutoff = isRushHour ? 0.24 : 0.12;

    int baseDelay;
    if (roll < earlyCutoff) {
      // Occasional early bus: -61s to -180s (-1 to -3 min).
      baseDelay = -(65 + rng.nextInt(116));
    } else if (roll < earlyCutoff + lateCutoff) {
      // Occasional late bus: +240s to +480s (+4 to +8 min).
      baseDelay = 240 + rng.nextInt(241);
    } else {
      // Normal drift plus positive rush-hour congestion bias.
      final rushBias = isRushHour ? 55 + rng.nextInt(45) : 0;
      final drift = rng.nextInt(121) - 35; // -35s..+85s
      baseDelay = (drift + rushBias).clamp(-55, 118);
    }

    // Add minor progressive per-stop drift while preserving early/onTime/late band.
    if (totalStops > 1 && stopIndex > 0) {
      final stopRng = math.Random(_stableHash('$seed|$tripId|$stopIndex'));
      final routeRatio = stopIndex / (totalStops - 1);
      final microDrift = ((stopRng.nextInt(25) - 8) * routeRatio).round();
      baseDelay += microDrift;
    }

    return baseDelay;
  }

  /// Determines whether a specific trip is simulated as cancelled.
  bool isTripCancelled({
    required String tripId,
    required String lineId,
    required DateTime scheduledTime,
  }) {
    // Align with seed notice for Line P18 morning off-peak cancellation.
    if ((lineId == 'P18' || lineId == '18') &&
        scheduledTime.hour == 10 &&
        scheduledTime.minute >= 25 &&
        scheduledTime.minute <= 55) {
      return true;
    }
    return false;
  }

  /// Cross-platform 32-bit FNV-1a hash so seeds never depend on VM hash codes.
  static int _stableHash(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
