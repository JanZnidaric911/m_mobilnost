// Abstract repository contract for multimodal Maribor bus and walking trip planning.

import 'package:latlong2/latlong.dart';

import '../models/bus_stop.dart';
import '../models/trip_plan.dart';

// TODO(firebase): Replace mock implementation with Cloud Functions / OTP transit router.
/// Computes door-to-door transit itineraries and locates nearest accessible stops.
abstract class TripRepository {
  /// Finds ranked direct and 1-transfer [TripOption] routes from [origin] to [destination].
  Future<List<TripOption>> planTrip({
    required LatLng origin,
    required LatLng destination,
    TripTimeMode mode = TripTimeMode.leaveNow,
    DateTime? targetTime,
    bool accessibleOnly = false,
    bool fewerTransfers = false,
    bool? useSimulatedLive,
    bool isOffline = false,
  });

  /// Returns the closest bus stop to [position], optionally requiring step-free access.
  Future<BusStop?> findNearestStop(
    LatLng position, {
    bool accessibleOnly = false,
  });
}
