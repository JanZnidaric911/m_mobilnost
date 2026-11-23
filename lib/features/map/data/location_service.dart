// Safe GPS location wrapper with manual Maribor stop fallback when denied or on web.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:m_mobilnost/core/accessibility/a11y_settings.dart';
import 'package:m_mobilnost/core/accessibility/favorites_provider.dart';
import 'package:m_mobilnost/core/utils/geo.dart';
import 'package:m_mobilnost/data/models/bus_stop.dart';
import 'package:m_mobilnost/features/lines/data/transit_providers.dart';

/// Describes how the user's current Maribor reference position was obtained.
enum LocationAccessKind {
  /// Live GPS coordinates obtained with user permission.
  gps,

  /// User explicitly enabled manual stop mode in settings.
  manualMode,

  /// GPS permission denied, disabled, or unavailable on web/platform.
  unavailableOrDenied,
}

/// Resolved location state combining GPS coordinates or manual stop fallback.
@immutable
class UserLocationState {
  /// Creates a [UserLocationState] with a non-null [effectivePosition].
  const UserLocationState({
    required this.kind,
    required this.effectivePosition,
    this.manualStop,
  });

  /// Resolution source (GPS, manual mode, or denied/unavailable fallback).
  final LocationAccessKind kind;

  /// Geographic coordinate used to sort nearby stops and center maps.
  final LatLng effectivePosition;

  /// Active manual fallback stop when not using live GPS.
  final BusStop? manualStop;

  /// Whether a live GPS fix is currently active.
  bool get isGps => kind == LocationAccessKind.gps;

  /// Whether manual stop fallback guidance should be shown.
  bool get showManualFallbackCard => kind != LocationAccessKind.gps;
}

/// Safe wrapper around `geolocator` that never throws or blocks on web/tests.
class LocationService {
  /// Creates a [LocationService] with an optional test [gpsProbe] override.
  const LocationService({
    this.gpsProbe,
  });

  /// Optional test hook overriding native GPS probing.
  final Future<LatLng?> Function()? gpsProbe;

  /// Attempts to read the device position safely, returning null if denied/unavailable.
  Future<LatLng?> tryGetCurrentPosition() async {
    if (gpsProbe != null) {
      try {
        return await gpsProbe!();
      } catch (_) {
        return null;
      }
    }
    if (kIsWeb) {
      return null;
    }
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      // Gracefully fall back on missing plugin implementations or desktop runners.
      return null;
    }
  }
}

/// Exposes [LocationService] for safe injection and test overrides.
final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

/// Resolves the active [UserLocationState] combining GPS and manual stop settings.
final userLocationProvider = FutureProvider<UserLocationState>((ref) async {
  final settings = ref.watch(a11ySettingsProvider);
  final favorites = ref.watch(favoritesProvider);
  final stops = await ref.watch(allStopsProvider.future);

  BusStop? manualStop;
  final manualId =
      favorites.manualStopId ?? FavoritesState.defaultManualStopId;
  for (final stop in stops) {
    if (stop.id == manualId) {
      manualStop = stop;
      break;
    }
  }
  manualStop ??= stops.isNotEmpty ? stops.first : null;
  final fallbackPos = manualStop?.position ?? GeoUtils.mariborCenter;

  if (settings.locationManualMode) {
    return UserLocationState(
      kind: LocationAccessKind.manualMode,
      effectivePosition: fallbackPos,
      manualStop: manualStop,
    );
  }

  final gpsPos =
      await ref.watch(locationServiceProvider).tryGetCurrentPosition();
  if (gpsPos != null) {
    return UserLocationState(
      kind: LocationAccessKind.gps,
      effectivePosition: gpsPos,
      manualStop: manualStop,
    );
  }

  return UserLocationState(
    kind: LocationAccessKind.unavailableOrDenied,
    effectivePosition: fallbackPos,
    manualStop: manualStop,
  );
});
