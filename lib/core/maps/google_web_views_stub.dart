// Non-web (Android, iOS, and VM test) implementation of Google Maps Directions & 3D Views.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'google_map_models.dart';
import 'google_maps_config.dart';

/// True when executing inside `flutter test` on the Dart VM.
bool get isFlutterTestEnvironment =>
    Platform.environment.containsKey('FLUTTER_TEST');

/// Displays Google Maps Directions Embed (`<iframe>` on Web; interactive card on Mobile/Tests).
class GoogleDirectionsEmbedPlatformView extends StatelessWidget {
  /// Creates a [GoogleDirectionsEmbedPlatformView].
  const GoogleDirectionsEmbedPlatformView({
    super.key,
    required this.origin,
    required this.destination,
    this.mode = 'transit',
    this.avoidTolls = false,
    this.avoidHighways = false,
  });

  /// Origin place or address string.
  final String origin;

  /// Destination place or address string.
  final String destination;

  /// Google Maps travel mode (`transit`, `driving`, `walking`).
  final String mode;

  /// Whether `avoid=tolls` is enabled.
  final bool avoidTolls;

  /// Whether `avoid=highways` is enabled.
  final bool avoidHighways;

  @override
  Widget build(BuildContext context) {
    final embedUri = GoogleMapsConfig.buildDirectionsEmbedUri(
      origin: origin,
      destination: destination,
      mode: mode,
      avoidTolls: avoidTolls,
      avoidHighways: avoidHighways,
    );
    final mapsOpenUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'origin': origin,
      'destination': destination,
      'travelmode': mode,
    });
    final scheme = Theme.of(context).colorScheme;

    return Container(
      key: const Key('google_directions_embed_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_rounded, size: 42, color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            'Google Maps Directions ($mode)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '$origin → $destination',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          SelectableText(
            embedUri.toString(),
            maxLines: 2,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => launchUrl(
              mapsOpenUri,
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Google Maps'),
          ),
        ],
      ),
    );
  }
}

/// Renders Google Maps 3D SDK on Android/iOS (tilted 3D buildings) or a safe stub in tests.
class GoogleMap3DPlatformView extends StatefulWidget {
  /// Creates a [GoogleMap3DPlatformView].
  const GoogleMap3DPlatformView({
    super.key,
    required this.center,
    this.tilt = 60,
    this.heading = 18,
    this.range = 1750,
    this.mobileZoom = 15.8,
    this.polylines = const [],
    this.markers = const [],
  });

  /// Map camera target coordinate.
  final LatLng center;

  /// Camera tilt angle in degrees (`0..75`).
  final double tilt;

  /// Camera bearing/heading in degrees (`0..360`).
  final double heading;

  /// Web 3D camera distance range in meters.
  final double range;

  /// Mobile zoom level (`>= 15` activates 3D buildings).
  final double mobileZoom;

  /// Polylines drawn over Maribor streets.
  final List<GoogleMap3DPolylineData> polylines;

  /// Live bus and stop markers.
  final List<GoogleMap3DMarkerData> markers;

  @override
  State<GoogleMap3DPlatformView> createState() =>
      _GoogleMap3DPlatformViewState();
}

class _GoogleMap3DPlatformViewState extends State<GoogleMap3DPlatformView> {
  gmaps.GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant GoogleMap3DPlatformView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.center != widget.center ||
        oldWidget.tilt != widget.tilt ||
        oldWidget.heading != widget.heading ||
        oldWidget.mobileZoom != widget.mobileZoom) {
      _controller?.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(
            target: gmaps.LatLng(
              widget.center.latitude,
              widget.center.longitude,
            ),
            zoom: widget.mobileZoom,
            tilt: widget.tilt.clamp(0.0, 67.5),
            bearing: widget.heading,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    final isMobile = !isTest && (Platform.isAndroid || Platform.isIOS);
    final scheme = Theme.of(context).colorScheme;

    if (!isMobile) {
      return Container(
        key: const Key('google_map_3d_stub_preview'),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.view_in_ar_rounded, size: 44, color: scheme.primary),
            const SizedBox(height: 10),
            Text(
              'Google Maps 3D SDK (${widget.tilt.round()}° tilt)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.center.latitude.toStringAsFixed(4)}, '
              '${widget.center.longitude.toStringAsFixed(4)} • '
              '${widget.markers.length} pins • ${widget.polylines.length} routes',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final gPolylines = {
      for (final line in widget.polylines)
        gmaps.Polyline(
          polylineId: gmaps.PolylineId(line.id),
          color: line.color,
          width: line.strokeWidth.round().clamp(3, 12),
          points: [
            for (final p in line.points) gmaps.LatLng(p.latitude, p.longitude),
          ],
        ),
    };

    final gMarkers = {
      for (final m in widget.markers)
        gmaps.Marker(
          markerId: gmaps.MarkerId(m.id),
          position: gmaps.LatLng(m.position.latitude, m.position.longitude),
          infoWindow: gmaps.InfoWindow(title: m.label),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            m.isBus
                ? gmaps.BitmapDescriptor.hueRed
                : gmaps.BitmapDescriptor.hueAzure,
          ),
        ),
    };

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(widget.center.latitude, widget.center.longitude),
        zoom: widget.mobileZoom,
        tilt: widget.tilt.clamp(0.0, 67.5),
        bearing: widget.heading,
      ),
      buildingsEnabled: true,
      tiltGesturesEnabled: true,
      rotateGesturesEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      polylines: gPolylines,
      markers: gMarkers,
      onMapCreated: (controller) => _controller = controller,
    );
  }
}
