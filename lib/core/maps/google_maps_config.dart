// Central configuration for Google Maps Embed, Maps 3D JS/Mobile SDK, and Routes API v2.

/// Holds Google Maps API keys and URL builders for Web, Android, and iOS.
abstract final class GoogleMapsConfig {
  static const String _defaultApiKey =
      'AIzaSyCJZoVbBxzgU4tt8Z-t4r5wxFM5eUOLdcs';

  /// Key used by Google Maps Embed API (`<iframe>`) and Maps JS 3D (`<gmp-map-3d>`).
  static const String webApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_WEB_KEY',
    defaultValue: _defaultApiKey,
  );

  /// Key used by Google Routes API v2 (`directions/v2:computeRoutes`).
  static const String routesApiKey = String.fromEnvironment(
    'GOOGLE_ROUTES_API_KEY',
    defaultValue: _defaultApiKey,
  );

  /// Key configured for Google Maps 3D SDK on Android (`AndroidManifest.xml`).
  static const String android3dApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_ANDROID_3D_KEY',
    defaultValue: _defaultApiKey,
  );

  /// Key configured for Google Maps 3D SDK on iOS (`AppDelegate.swift`).
  static const String ios3dApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_IOS_3D_KEY',
    defaultValue: _defaultApiKey,
  );

  /// Endpoint for Google Routes API v2 `computeRoutes`.
  static final Uri computeRoutesEndpoint = Uri.parse(
    'https://routes.googleapis.com/directions/v2:computeRoutes',
  );

  /// Builds a validated Google Maps Embed v1 Directions URL for `<iframe>` embeds.
  static Uri buildDirectionsEmbedUri({
    required String origin,
    required String destination,
    String mode = 'transit',
    bool avoidTolls = false,
    bool avoidHighways = false,
  }) {
    final avoid = <String>[
      if (avoidTolls) 'tolls',
      if (avoidHighways) 'highways',
    ];
    final params = <String, String>{
      'key': webApiKey,
      'origin': origin.trim(),
      'destination': destination.trim(),
      'mode': mode,
      if (avoid.isNotEmpty) 'avoid': avoid.join('|'),
    };
    return Uri.https('www.google.com', '/maps/embed/v1/directions', params);
  }
}
