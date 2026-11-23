// Reusable flutter_map widget and calm manual Maribor stop selector card.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:m_mobilnost/core/accessibility/a11y_settings.dart';
import 'package:m_mobilnost/core/accessibility/favorites_provider.dart';
import 'package:m_mobilnost/core/accessibility/semantics_helpers.dart';
import 'package:m_mobilnost/core/network/map_tile_provider.dart';
import 'package:m_mobilnost/core/theme/colors.dart';
import 'package:m_mobilnost/core/utils/geo.dart';
import 'package:m_mobilnost/core/widgets/big_button.dart';
import 'package:m_mobilnost/data/models/bus_stop.dart';

/// Shared `flutter_map` wrapper honoring [mapTileProviderProvider] and reduced motion.
class MariborTransitMap extends ConsumerWidget {
  /// Creates a [MariborTransitMap] centered on [initialCenter] or [initialCameraFit].
  const MariborTransitMap({
    super.key,
    this.mapController,
    this.initialCenter = GeoUtils.mariborCenter,
    this.initialZoom = 13.5,
    this.initialCameraFit,
    this.polylines = const [],
    this.markers = const [],
    this.onTap,
    this.onRecenter,
    this.recenterLabel,
    this.recenterIcon = Icons.my_location_rounded,
  });

  /// Optional controller for programmatic pan/zoom.
  final MapController? mapController;

  /// Starting center coordinate when [initialCameraFit] is omitted.
  final LatLng initialCenter;

  /// Starting zoom level.
  final double initialZoom;

  /// Optional bounds fit applied on initial map build.
  final CameraFit? initialCameraFit;

  /// Transit route polylines rendered on the map.
  final List<Polyline> polylines;

  /// Stop, bus, and user-location markers rendered above polylines.
  final List<Marker> markers;

  /// Optional tap handler on empty map coordinates.
  final TapCallback? onTap;

  /// Optional action callback for the accessible recenter button.
  final VoidCallback? onRecenter;

  /// Localized tooltip/label for [onRecenter].
  final String? recenterLabel;

  /// Leading icon for [onRecenter].
  final IconData recenterIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final customTileProvider = ref.watch(mapTileProviderProvider);
    final reducedMotion = ref.watch(
      a11ySettingsProvider.select((s) => s.reducedMotion),
    );
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label: l10n.mapTitle,
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: initialZoom,
              initialCameraFit: initialCameraFit,
              minZoom: 11,
              maxZoom: 18,
              onTap: onTap,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'si.marprom.m_mobilnost',
                tileProvider: customTileProvider,
                tileDisplay: reducedMotion
                    ? const TileDisplay.instantaneous()
                    : const TileDisplay.fadeIn(),
              ),
              if (polylines.isNotEmpty)
                PolylineLayer(polylines: polylines),
              if (markers.isNotEmpty)
                MarkerLayer(markers: markers),
            ],
          ),
          if (onRecenter != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Align(
                alignment: Alignment.bottomRight,
                child: Semantics(
                  button: true,
                  label: recenterLabel ?? l10n.mapCenterOnMe,
                  child: Material(
                    color: scheme.surface,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: scheme.outline),
                    ),
                    child: InkWell(
                      onTap: onRecenter,
                      borderRadius: BorderRadius.circular(14),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 56,
                          minHeight: 56,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(recenterIcon, color: scheme.primary),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  recenterLabel ?? l10n.mapCenterOnMe,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Calm non-blocking explanation card with manual Maribor stop selection.
class ManualLocationFallbackCard extends ConsumerWidget {
  /// Creates a [ManualLocationFallbackCard] allowing manual stop picking.
  const ManualLocationFallbackCard({
    super.key,
    required this.stops,
    this.selectedStop,
    this.onManualStopChanged,
  });

  /// Available Maribor stops to choose from.
  final List<BusStop> stops;

  /// Currently selected manual reference stop.
  final BusStop? selectedStop;

  /// Optional callback invoked after [favoritesProvider] updates the manual stop.
  final ValueChanged<BusStop>? onManualStopChanged;

  Future<void> _openStopPicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final picked = await showModalBottomSheet<BusStop>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _ManualStopPickerSheet(
        stops: stops,
        selectedStopId: selectedStop?.id,
      ),
    );
    if (picked == null) return;
    await ref.read(favoritesProvider.notifier).setManualStop(picked.id);
    onManualStopChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statusColors =
        Theme.of(context).extension<MarpromStatusColors>() ??
            MarpromStatusColors.light;

    return Card(
      color: statusColors.infoBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColors.infoFg,
          width: statusColors.highContrastBorders ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_searching_rounded,
                  color: statusColors.infoFg,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mapLocationDeniedTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: statusColors.infoFg,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.mapLocationDeniedBody,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: statusColors.infoFg,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BigButton(
              icon: Icons.edit_location_alt_outlined,
              label: selectedStop != null
                  ? '${l10n.mapSelectManualStop}: ${selectedStop!.name}'
                  : l10n.mapSelectManualStop,
              variant: BigButtonVariant.outlined,
              expanded: true,
              onPressed:
                  stops.isEmpty ? null : () => _openStopPicker(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualStopPickerSheet extends StatefulWidget {
  const _ManualStopPickerSheet({
    required this.stops,
    this.selectedStopId,
  });

  final List<BusStop> stops;
  final String? selectedStopId;

  @override
  State<_ManualStopPickerSheet> createState() => _ManualStopPickerSheetState();
}

class _ManualStopPickerSheetState extends State<_ManualStopPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trimmed = _query.trim().toLowerCase();
    final filtered = trimmed.isEmpty
        ? widget.stops
        : widget.stops
            .where((s) => s.name.toLowerCase().contains(trimmed))
            .toList(growable: false);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.mapSelectManualStop,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: l10n.a11yCloseButton,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: l10n.commonClose,
                      constraints:
                          const BoxConstraints(minWidth: 56, minHeight: 56),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: l10n.mapSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Text(l10n.mapNoNearbyStops))
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final stop = filtered[index];
                          final isSelected = stop.id == widget.selectedStopId;
                          return ListTile(
                            minTileHeight: 56,
                            leading: Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.place_outlined,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            title: Text(stop.name),
                            subtitle: stop.platform != null
                                ? Text(l10n.stopPlatform(stop.platform!))
                                : null,
                            onTap: () => Navigator.of(context).pop(stop),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
