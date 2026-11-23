// Defines the Place model for searchable Maribor points of interest and addresses.

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Searchable Maribor destination or point of interest linked to nearby stops.
@immutable
class Place {
  /// Creates a [Place] record for trip planner and destination search.
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.position,
    required this.nearestStopIds,
  });

  /// Unique place identifier.
  final String id;

  /// Public name of the landmark, institution, or address.
  final String name;

  /// Category key (for example `hospital`, `university`, `shopping`, `transit`).
  final String category;

  /// Street address in Maribor.
  final String address;

  /// Geographic coordinate of the destination.
  final LatLng position;

  /// Nearest Marprom stop IDs serving this destination.
  final List<String> nearestStopIds;
}
