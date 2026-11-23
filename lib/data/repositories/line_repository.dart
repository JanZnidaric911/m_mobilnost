// Abstract repository contract for Marprom bus lines, stops, and places.

import 'package:latlong2/latlong.dart';

import '../models/bus_line.dart';
import '../models/bus_stop.dart';
import '../models/place.dart';

// TODO(firebase): Replace mock implementation with Firestore + GTFS-static sync.
/// Provides read and search access to Maribor bus lines, stops, and places.
abstract class LineRepository {
  /// Returns all available Maribor city bus lines.
  Future<List<BusLine>> getLines();

  /// Finds a bus line by [lineId], or returns null if unknown.
  Future<BusLine?> getLineById(String lineId);

  /// Returns all Marprom bus stops.
  Future<List<BusStop>> getStops();

  /// Finds a bus stop by [stopId], or returns null if unknown.
  Future<BusStop?> getStopById(String stopId);

  /// Filters bus stops matching [query] by name or served line code.
  Future<List<BusStop>> searchStops(String query);

  /// Returns stops near [position] ordered by ascending Haversine distance.
  Future<List<BusStop>> getNearbyStops(
    LatLng position, {
    double maxDistanceMeters = 1500,
    int limit = 10,
  });

  /// Returns all searchable Maribor points of interest.
  Future<List<Place>> getPlaces();

  /// Filters places matching [query] by name, address, or category.
  Future<List<Place>> searchPlaces(String query);
}
