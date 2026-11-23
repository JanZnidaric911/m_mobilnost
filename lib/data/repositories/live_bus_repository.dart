// Abstract repository contract for real-time bus telemetry and segment occupancy.

import '../models/bus_position.dart';
import '../models/occupancy.dart';

// TODO(firebase): Replace mock implementation with Firebase RTDB / GTFS-RT vehicle stream.
/// Provides live or simulated bus positions and segment crowding telemetry.
abstract class LiveBusRepository {
  /// Streams active [BusPosition] snapshots, optionally filtered by [lineId].
  Stream<List<BusPosition>> watchLiveBuses({String? lineId});

  /// Returns a point-in-time snapshot of active buses at [at] (defaults to now).
  Future<List<BusPosition>> getCurrentBuses({String? lineId, DateTime? at});

  /// Returns estimated occupancy for a single route segment between two stops.
  Future<SegmentOccupancy> getSegmentOccupancy({
    required String lineId,
    required String directionId,
    required String fromStopId,
    required String toStopId,
    DateTime? at,
  });

  /// Releases underlying timers or stream subscriptions.
  void dispose();
}
