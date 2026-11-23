// Shared trip endpoint model, safe GPS resolver, and accessible transit badges.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:m_mobilnost/core/accessibility/favorites_provider.dart';
import 'package:m_mobilnost/core/accessibility/semantics_helpers.dart';
import 'package:m_mobilnost/core/utils/geo.dart';
import 'package:m_mobilnost/core/widgets/status_chip.dart';
import 'package:m_mobilnost/data/models/bus_stop.dart';
import 'package:m_mobilnost/data/models/place.dart';
import 'package:m_mobilnost/data/repositories/line_repository.dart';
import 'package:m_mobilnost/l10n/app_localizations.dart';

/// Identifies whether an origin/destination endpoint comes from GPS, a stop, or a place.
enum TripEndpointKind {
  /// Live GPS position resolved from device location services.
  gps,

  /// A Marprom [BusStop] chosen manually or prefilled via route arguments.
  stop,

  /// A Maribor [Place] point of interest.
  place,
}

/// Immutable origin or destination endpoint selected in Trip Planner or Nearest Stop.
@immutable
class TripEndpoint {
  /// Creates a [TripEndpoint] wrapping a coordinate and optional stop or place.
  const TripEndpoint({
    required this.kind,
    required this.position,
    this.stop,
    this.place,
  });

  /// Creates a GPS endpoint at [position].
  const TripEndpoint.gps(LatLng position)
      : this(kind: TripEndpointKind.gps, position: position);

  /// Creates an endpoint anchored to a [BusStop].
  TripEndpoint.stop(BusStop stop)
      : this(
          kind: TripEndpointKind.stop,
          position: stop.position,
          stop: stop,
        );

  /// Creates an endpoint anchored to a [Place].
  TripEndpoint.place(Place place)
      : this(
          kind: TripEndpointKind.place,
          position: place.position,
          place: place,
        );

  /// Endpoint source category.
  final TripEndpointKind kind;

  /// Geographic coordinates used by routing.
  final LatLng position;

  /// Backing [BusStop] when [kind] is [TripEndpointKind.stop].
  final BusStop? stop;

  /// Backing [Place] when [kind] is [TripEndpointKind.place].
  final Place? place;

  /// Preferred destination stop IDs if this endpoint represents a stop or place.
  List<String> get preferredStopIds {
    if (stop != null) return [stop!.id];
    if (place != null) return place!.nearestStopIds;
    return const [];
  }

  /// Localized label shown in fields and instructions.
  String displayLabel(AppLocalizations l10n) {
    if (stop != null) return stop!.name;
    if (place != null) return place!.name;
    return l10n.planCurrentLocation;
  }

  /// Raw label passed to [RoutePlanner] (empty for GPS so UI localizes dynamically).
  String get rawName => stop?.name ?? place?.name ?? '';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripEndpoint &&
        other.kind == kind &&
        other.position == position &&
        other.stop?.id == stop?.id &&
        other.place?.id == place?.id;
  }

  @override
  int get hashCode => Object.hash(kind, position, stop?.id, place?.id);
}

/// Safely attempts to fetch GPS coordinates when not on web and permission permits.
Future<LatLng?> tryFetchCurrentGps({bool requestIfDenied = false}) async {
  if (kIsWeb) return null;
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled()
        .timeout(const Duration(seconds: 2));
    if (!serviceEnabled) return null;

    var perm = await Geolocator.checkPermission()
        .timeout(const Duration(seconds: 2));
    if (perm == LocationPermission.denied && requestIfDenied) {
      perm = await Geolocator.requestPermission()
          .timeout(const Duration(seconds: 4));
    }
    if (perm != LocationPermission.whileInUse &&
        perm != LocationPermission.always) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 3),
      ),
    ).timeout(const Duration(seconds: 3));
    return LatLng(pos.latitude, pos.longitude);
  } catch (_) {
    return null;
  }
}

/// Resolves the initial origin endpoint using explicit stop, safe GPS, or manual fallback.
Future<(TripEndpoint, bool gpsUsed)> resolveInitialOrigin({
  required LineRepository lineRepo,
  required bool locationManualMode,
  required String? manualStopId,
  String? initialFromStopId,
}) async {
  if (initialFromStopId != null && initialFromStopId.isNotEmpty) {
    final stop = await lineRepo.getStopById(initialFromStopId);
    if (stop != null) {
      return (TripEndpoint.stop(stop), false);
    }
  }

  if (!locationManualMode) {
    final gpsPos = await tryFetchCurrentGps(requestIfDenied: false);
    if (gpsPos != null) {
      return (TripEndpoint.gps(gpsPos), true);
    }
  }

  final fallbackId = (manualStopId != null && manualStopId.isNotEmpty)
      ? manualStopId
      : FavoritesState.defaultManualStopId;
  final fallbackStop = await lineRepo.getStopById(fallbackId);
  if (fallbackStop != null) {
    return (TripEndpoint.stop(fallbackStop), false);
  }

  final allStops = await lineRepo.getStops();
  if (allStops.isNotEmpty) {
    return (TripEndpoint.stop(allStops.first), false);
  }
  return (const TripEndpoint.gps(GeoUtils.mariborCenter), false);
}

/// Resolves an initial destination from [stopId] or [placeOrStopName].
Future<TripEndpoint?> resolveInitialDestination({
  required LineRepository lineRepo,
  String? stopId,
  String? placeOrStopName,
}) async {
  if (stopId != null && stopId.isNotEmpty) {
    final stop = await lineRepo.getStopById(stopId);
    if (stop != null) return TripEndpoint.stop(stop);
  }
  if (placeOrStopName != null && placeOrStopName.trim().isNotEmpty) {
    final query = placeOrStopName.trim().toLowerCase();
    final places = await lineRepo.searchPlaces(query);
    if (places.isNotEmpty) {
      final exact = places.where((p) => p.name.toLowerCase() == query).firstOrNull;
      return TripEndpoint.place(exact ?? places.first);
    }
    final stops = await lineRepo.searchStops(query);
    if (stops.isNotEmpty) {
      final exact = stops.where((s) => s.name.toLowerCase() == query).firstOrNull;
      return TripEndpoint.stop(exact ?? stops.first);
    }
  }
  return null;
}

/// Accessible bus line pill combining color, bus icon, and localized text.
class LineBadgeChip extends StatelessWidget {
  /// Creates a [LineBadgeChip] for [lineCode] with optional [lineColor].
  const LineBadgeChip({
    super.key,
    required this.lineCode,
    this.lineColor,
    this.compact = false,
  });

  /// Short line code (for example `6` or `12`).
  final String lineCode;

  /// Optional brand color of the line; falls back to theme primary.
  final Color? lineColor;

  /// Uses slightly smaller horizontal padding when compact.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bg = lineColor ?? scheme.primary;
    final fg = bg.computeLuminance() > 0.45 ? Colors.black : Colors.white;

    return Semantics(
      label: l10n.a11yLineBadge(lineCode),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outline, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_bus_rounded,
              size: compact ? 16 : 18,
              color: fg,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l10n.linesBadge(lineCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Maps [delaySeconds] and [isCancelled] into a localized [StatusChip].
class DepartureDelayChip extends StatelessWidget {
  /// Creates a [DepartureDelayChip] from signed [delaySeconds].
  const DepartureDelayChip({
    super.key,
    required this.delaySeconds,
    this.isCancelled = false,
    this.compact = true,
  });

  /// Signed delay in seconds (`< -60` early, `<= 120` on-time, `> 120` late).
  final int delaySeconds;

  /// Whether the trip is cancelled.
  final bool isCancelled;

  /// Renders compact chip sizing when true.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (isCancelled) {
      return StatusChip(
        type: TransitStatusType.disruption,
        label: l10n.statusCancelled,
        compact: compact,
      );
    }
    if (delaySeconds < -60) {
      final mins = (delaySeconds.abs() / 60).round().clamp(1, 30);
      return StatusChip(
        type: TransitStatusType.early,
        label: l10n.statusEarlyByMinutes(mins),
        compact: compact,
      );
    }
    if (delaySeconds <= 120) {
      return StatusChip(
        type: TransitStatusType.onTime,
        label: l10n.statusOnTime,
        compact: compact,
      );
    }
    final mins = (delaySeconds / 60).round().clamp(1, 60);
    return StatusChip(
      type: TransitStatusType.late,
      label: l10n.statusLateByMinutes(mins),
      compact: compact,
    );
  }
}
