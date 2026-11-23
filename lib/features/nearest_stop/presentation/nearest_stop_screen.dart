// Nearest-Stop Search screen ranking nearby stops by earliest arrival at destination.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:m_mobilnost/core/accessibility/a11y_settings.dart';
import 'package:m_mobilnost/core/accessibility/favorites_provider.dart';
import 'package:m_mobilnost/core/accessibility/semantics_helpers.dart';
import 'package:m_mobilnost/core/layout/responsive_builder.dart';
import 'package:m_mobilnost/core/utils/distance.dart';
import 'package:m_mobilnost/core/utils/time_format.dart';
import 'package:m_mobilnost/core/widgets/big_button.dart';
import 'package:m_mobilnost/core/widgets/occupancy_strip.dart';
import 'package:m_mobilnost/core/widgets/offline_banner.dart';
import 'package:m_mobilnost/core/widgets/simulated_data_badge.dart';
import 'package:m_mobilnost/core/widgets/state_views.dart';
import 'package:m_mobilnost/core/widgets/status_chip.dart';
import 'package:m_mobilnost/data/models/place.dart';
import 'package:m_mobilnost/data/repositories/repository_providers.dart';

import '../../trip_planner/domain/route_planner.dart';
import '../../trip_planner/presentation/widgets/location_picker.dart';
import '../../trip_planner/presentation/widgets/trip_endpoint.dart';

/// Recommends nearby walkable stops sorted by earliest total arrival at destination.
class NearestStopScreen extends ConsumerStatefulWidget {
  /// Creates a [NearestStopScreen] optionally prefilled with a destination.
  const NearestStopScreen({
    super.key,
    this.initialToStopId,
    this.initialToName,
  });

  /// Optional destination stop ID passed via query parameter.
  final String? initialToStopId;

  /// Optional destination name passed via query parameter.
  final String? initialToName;

  @override
  ConsumerState<NearestStopScreen> createState() => _NearestStopScreenState();
}

class _NearestStopScreenState extends ConsumerState<NearestStopScreen> {
  TripEndpoint? _origin;
  TripEndpoint? _destination;
  bool _gpsUsed = false;
  bool _accessibleOnly = false;
  double _maxWalkMeters = 1200.0;

  bool _initializing = true;
  bool _searching = false;
  bool _hasSearched = false;
  Object? _error;
  List<Place> _quickPlaces = const [];
  List<NearestStopResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  @override
  void didUpdateWidget(covariant NearestStopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialToStopId != widget.initialToStopId ||
        oldWidget.initialToName != widget.initialToName) {
      _refreshDestinationParam();
    }
  }

  Future<void> _initScreen() async {
    final lineRepo = ref.read(lineRepositoryProvider);
    final settings = ref.read(a11ySettingsProvider);
    final favorites = ref.read(favoritesProvider);

    final loaded = await Future.wait([
      resolveInitialOrigin(
        lineRepo: lineRepo,
        locationManualMode: settings.locationManualMode,
        manualStopId: favorites.manualStopId,
      ),
      resolveInitialDestination(
        lineRepo: lineRepo,
        stopId: widget.initialToStopId,
        placeOrStopName: widget.initialToName,
      ),
      lineRepo.getPlaces(),
    ]);

    if (!mounted) return;
    final (origin, gpsUsed) = loaded[0] as (TripEndpoint, bool);
    final dest = loaded[1] as TripEndpoint?;
    final places = loaded[2] as List<Place>;

    setState(() {
      _origin = origin;
      _gpsUsed = gpsUsed;
      _destination = dest;
      _quickPlaces = places.take(4).toList(growable: false);
      _initializing = false;
    });

    if (dest != null) {
      await _search();
    }
  }

  Future<void> _refreshDestinationParam() async {
    final lineRepo = ref.read(lineRepositoryProvider);
    final dest = await resolveInitialDestination(
      lineRepo: lineRepo,
      stopId: widget.initialToStopId,
      placeOrStopName: widget.initialToName,
    );
    if (dest != null && mounted) {
      setState(() => _destination = dest);
      await _search();
    }
  }

  Future<void> _pickManualOrigin() async {
    final l10n = context.l10n;
    final chosen = await showLocationSearchSheet(
      context: context,
      title: l10n.mapSelectManualStop,
      allowCurrentLocation: true,
    );
    if (chosen == null || !mounted) return;
    if (chosen.stop != null) {
      await ref.read(favoritesProvider.notifier).setManualStop(chosen.stop!.id);
    }
    setState(() {
      _origin = chosen;
      _gpsUsed = chosen.kind == TripEndpointKind.gps;
      _maxWalkMeters = 1200.0;
    });
    if (_destination != null) {
      await _search();
    }
  }

  Future<void> _pickDestination({String initialQuery = ''}) async {
    final l10n = context.l10n;
    final chosen = await showLocationSearchSheet(
      context: context,
      title: l10n.planSelectDestination,
      allowCurrentLocation: false,
      initialQuery: initialQuery,
    );
    if (chosen == null || !mounted) return;
    setState(() {
      _destination = chosen;
      _maxWalkMeters = 1200.0;
    });
    await _search();
  }

  Future<void> _search() async {
    if (_origin == null || _destination == null) return;
    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final planner = ref.read(routePlannerProvider);
      final results = await planner.findNearestStopsToDestination(
        origin: _origin!.position,
        destination: _destination!.position,
        originLabel: _origin!.rawName,
        destinationLabel: _destination!.rawName,
        maxWalkMeters: _maxWalkMeters,
        accessibleOnly: _accessibleOnly,
        preferredDestinationStopIds: _destination!.preferredStopIds,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
        _hasSearched = true;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err;
        _searching = false;
        _hasSearched = true;
      });
    }
  }

  Future<void> _increaseRadius() async {
    setState(() {
      _maxWalkMeters = (_maxWalkMeters + 1000).clamp(1500, 4000);
    });
    await _search();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.nearestStopTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: _initializing
                ? const LoadingStateView()
                : ListView(
                    children: [
                      ResponsiveContentContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const SimulatedDataBadge(),
                                StatusChip(
                                  type: TransitStatusType.info,
                                  label: l10n.nearestStopSortedByArrival,
                                  compact: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.nearestStopGoalHint,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LocationPickerField(
                                      label: l10n.planDestinationLabel,
                                      placeholder: l10n.planSelectDestination,
                                      leadingIcon: Icons.place_rounded,
                                      value: _destination,
                                      onTap: () => _pickDestination(),
                                      onVoiceSelected: (query) =>
                                          _pickDestination(initialQuery: query),
                                      onClear: _destination == null
                                          ? null
                                          : () => setState(() {
                                                _destination = null;
                                                _results = const [];
                                                _hasSearched = false;
                                              }),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          _gpsUsed
                                              ? Icons.my_location_rounded
                                              : Icons.location_on_outlined,
                                          color: scheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${l10n.planOriginLabel}: '
                                            '${_origin?.displayLabel(l10n) ?? l10n.planCurrentLocation}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    BigButton(
                                      icon: Icons.edit_location_alt_outlined,
                                      label: l10n.nearestStopUseManual,
                                      variant: BigButtonVariant.outlined,
                                      expanded: true,
                                      onPressed: _pickManualOrigin,
                                    ),
                                    const SizedBox(height: 4),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        l10n.planAccessibleOnly,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                      secondary: const Icon(
                                        Icons.accessible_rounded,
                                      ),
                                      value: _accessibleOnly,
                                      onChanged: (val) {
                                        setState(() => _accessibleOnly = val);
                                        if (_destination != null) {
                                          _search();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildBodyContent(context),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    final l10n = context.l10n;
    if (_searching) {
      return const LoadingStateView();
    }
    if (_error != null) {
      return ErrorStateView(onRetry: _search);
    }
    if (!_hasSearched || _destination == null) {
      if (_quickPlaces.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.planSelectDestination,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final place in _quickPlaces)
                BigButton(
                  icon: Icons.place_outlined,
                  label: place.name,
                  variant: BigButtonVariant.secondary,
                  onPressed: () {
                    setState(() => _destination = TripEndpoint.place(place));
                    _search();
                  },
                ),
            ],
          ),
        ],
      );
    }
    if (_results.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.planNoResultsTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.planNoResultsBody,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              BigButton(
                icon: Icons.directions_walk_rounded,
                label: l10n.planTryWalkFurther,
                variant: BigButtonVariant.secondary,
                onPressed: _increaseRadius,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _results.length; i++) ...[
          _NearestStopResultCard(result: _results[i]),
          if (i < _results.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _NearestStopResultCard extends StatelessWidget {
  const _NearestStopResultCard({required this.result});

  final NearestStopResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final dep = result.nextDeparture;
    final updatedHms = DateFormat('HH:mm:ss').format(dep.freshness.updatedAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    result.stop.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(width: 8),
                if (result.stop.isStepFree)
                  Icon(
                    Icons.accessible_rounded,
                    color: scheme.secondary,
                    semanticLabel: l10n.stopAmenityStepFree,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_walk_rounded, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.nearestStopDistance(
                          DistanceUtils.formatMeters(result.walkMeters, l10n),
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
                Text(
                  l10n.nearestStopWalkTime(result.walkMinutes),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                LineBadgeChip(
                  lineCode: result.line.code,
                  lineColor: result.line.color,
                ),
                Text(
                  result.direction.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (result.transferCount > 0 && result.transferLine != null)
                  LineBadgeChip(
                    lineCode: result.transferLine!.code,
                    lineColor: result.transferLine!.color,
                    compact: true,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${l10n.nearestStopNextBus}: '
                        '${TimeFormatUtils.formatTime24(dep.estimatedTime)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      DepartureDelayChip(
                        delaySeconds: dep.delaySeconds,
                        isCancelled: dep.isCancelled,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${l10n.nearestStopArrivesAt(TimeFormatUtils.formatTime24(result.estimatedArrivalTime))} '
                    '(${l10n.commonMinutesShort(result.totalMinutes)})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  OccupancyStrip(level: dep.occupancy, compact: true),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SimulatedDataBadge(freshness: dep.freshness),
                      Text(
                        l10n.commonLastUpdatedAt(updatedHms),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                BigButton(
                  icon: Icons.alt_route_rounded,
                  label: l10n.homePlanTripAction,
                  onPressed: () {
                    final from = Uri.encodeComponent(result.stop.id);
                    final to = Uri.encodeComponent(result.destinationStop.id);
                    context.go('/plan?fromStopId=$from&toStopId=$to');
                  },
                ),
                BigButton(
                  icon: Icons.schedule_rounded,
                  label: l10n.mapStopDetailsOpen,
                  variant: BigButtonVariant.outlined,
                  onPressed: () => context.push(
                    '/stops/${Uri.encodeComponent(result.stop.id)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
