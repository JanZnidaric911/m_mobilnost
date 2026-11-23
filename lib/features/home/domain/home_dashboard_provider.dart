// Computes the personalized Home dashboard snapshot from location, favorites, and repos.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/accessibility/a11y_settings.dart';
import '../../../core/accessibility/favorites_provider.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/utils/geo.dart';
import '../../../data/models/bus_line.dart';
import '../../../data/models/bus_stop.dart';
import '../../../data/models/departure.dart';
import '../../../data/models/ticket.dart';
import '../../../data/repositories/repository_providers.dart';

/// Upcoming departures preview for a single favorited bus stop.
@immutable
class FavoriteStopPreview {
  /// Creates a [FavoriteStopPreview] pairing [stop] with its next [departures].
  const FavoriteStopPreview({
    required this.stop,
    required this.departures,
  });

  /// Favorited stop metadata.
  final BusStop stop;

  /// Next 2–3 upcoming departures at [stop].
  final List<Departure> departures;
}

/// Aggregated snapshot displayed on [HomeScreen].
@immutable
class HomeDashboardData {
  /// Creates a [HomeDashboardData] bundle for the home summary cards.
  const HomeDashboardData({
    required this.userPosition,
    required this.usingManualLocation,
    required this.primaryStop,
    required this.distanceToPrimaryStopMeters,
    required this.primaryDepartures,
    required this.favoriteStops,
    required this.favoriteLines,
    required this.fetchedAt,
  });

  /// Resolved user position (GPS or manual stop coordinate).
  final LatLng userPosition;

  /// True when manual Maribor stop mode or GPS fallback is active.
  final bool usingManualLocation;

  /// Nearest or manually chosen focus bus stop.
  final BusStop primaryStop;

  /// Straight-line distance in meters from [userPosition] to [primaryStop].
  final int distanceToPrimaryStopMeters;

  /// Upcoming departures from [primaryStop].
  final List<Departure> primaryDepartures;

  /// Favorited stops with their next 2–3 departures.
  final List<FavoriteStopPreview> favoriteStops;

  /// Favorited bus lines resolved from [LineRepository].
  final List<BusLine> favoriteLines;

  /// Wall-clock timestamp when this dashboard snapshot was fetched.
  final DateTime fetchedAt;

  /// First non-cancelled departure at [primaryStop], if available.
  Departure? get nextDeparture {
    for (final dep in primaryDepartures) {
      if (!dep.isCancelled) return dep;
    }
    return primaryDepartures.isEmpty ? null : primaryDepartures.first;
  }
}

/// Streams the signed-in rider's tickets for active-ticket Home card display.
final homeUserTicketsProvider =
    StreamProvider.autoDispose<List<Ticket>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.when(
    data: (u) => u,
    loading: () => authRepo.currentUser,
    error: (_, _) => authRepo.currentUser,
  );
  if (user == null) {
    return Stream.value(const <Ticket>[]);
  }
  return ref.watch(ticketRepositoryProvider).watchUserTickets(user.id);
});

/// Resolves location, next bus, and favorite stop departures for Home.
final homeDashboardProvider =
    FutureProvider.autoDispose<HomeDashboardData>((ref) async {
  final settings = ref.watch(a11ySettingsProvider);
  final favorites = ref.watch(favoritesProvider);
  final isOffline = ref.watch(isOfflineProvider);
  final lineRepo = ref.watch(lineRepositoryProvider);
  final timetableRepo = ref.watch(timetableRepositoryProvider);
  final tripRepo = ref.watch(tripRepositoryProvider);

  final now = DateTime.now();
  final stops = await lineRepo.getStops();
  final lines = await lineRepo.getLines();
  final stopsById = {for (final s in stops) s.id: s};
  final linesById = {for (final l in lines) l.id: l};

  final manualStopId =
      favorites.manualStopId ?? FavoritesState.defaultManualStopId;
  final manualStop = stopsById[manualStopId] ?? stops.first;

  var usingManual = settings.locationManualMode;
  LatLng userPosition = manualStop.position;

  if (!settings.locationManualMode) {
    final gpsPosition = await _tryReadGpsPosition();
    if (gpsPosition != null) {
      userPosition = gpsPosition;
    } else {
      usingManual = true;
    }
  }

  BusStop primaryStop = manualStop;
  if (!usingManual) {
    primaryStop = await tripRepo.findNearestStop(userPosition) ?? manualStop;
  }

  final distanceMeters =
      GeoUtils.haversineMeters(userPosition, primaryStop.position).round();

  final primaryDepartures = await timetableRepo.getDeparturesForStop(
    primaryStop.id,
    at: now,
    limit: 5,
    useSimulatedLive: settings.useSimulatedLive,
    isOffline: isOffline,
  );

  final favStopFutures = <Future<FavoriteStopPreview>>[];
  for (final favId in favorites.stopIds) {
    final stop = stopsById[favId];
    if (stop == null) continue;
    favStopFutures.add(
      timetableRepo
          .getDeparturesForStop(
            stop.id,
            at: now,
            limit: 3,
            useSimulatedLive: settings.useSimulatedLive,
            isOffline: isOffline,
          )
          .then((deps) => FavoriteStopPreview(stop: stop, departures: deps)),
    );
  }
  final favoriteStops = await Future.wait(favStopFutures);

  final favoriteLines = <BusLine>[
    for (final lineId in favorites.lineIds)
      if (linesById[lineId] != null) linesById[lineId]!,
  ];

  return HomeDashboardData(
    userPosition: userPosition,
    usingManualLocation: usingManual,
    primaryStop: primaryStop,
    distanceToPrimaryStopMeters: distanceMeters,
    primaryDepartures: primaryDepartures,
    favoriteStops: favoriteStops,
    favoriteLines: favoriteLines,
    fetchedAt: now,
  );
});

Future<LatLng?> _tryReadGpsPosition() async {
  if (kIsWeb) return null;
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 2),
      ),
    );
    return LatLng(pos.latitude, pos.longitude);
  } catch (_) {
    return null;
  }
}
