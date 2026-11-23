// Accessible bus stop timetable view grouped by line/direction with day selector.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m_mobilnost/core/accessibility/a11y_settings.dart';
import 'package:m_mobilnost/core/accessibility/favorites_provider.dart';
import 'package:m_mobilnost/core/accessibility/haptic_cues.dart';
import 'package:m_mobilnost/core/accessibility/read_aloud.dart';
import 'package:m_mobilnost/core/accessibility/semantics_helpers.dart';
import 'package:m_mobilnost/core/layout/responsive_builder.dart';
import 'package:m_mobilnost/core/network/connectivity_provider.dart';
import 'package:m_mobilnost/core/utils/time_format.dart';
import 'package:m_mobilnost/core/widgets/big_button.dart';
import 'package:m_mobilnost/core/widgets/offline_banner.dart';
import 'package:m_mobilnost/core/widgets/state_views.dart';
import 'package:m_mobilnost/data/models/bus_line.dart';
import 'package:m_mobilnost/data/models/bus_stop.dart';
import 'package:m_mobilnost/data/models/departure.dart';
import 'package:m_mobilnost/data/repositories/repository_providers.dart';
import 'package:m_mobilnost/data/seed/seed_timetables.dart';
import 'package:m_mobilnost/features/lines/data/transit_providers.dart';
import 'package:m_mobilnost/features/lines/presentation/widgets/line_badge.dart';
import 'package:m_mobilnost/l10n/app_localizations.dart';

/// Displays stop facilities, grouped departures, day selector, and trip planning CTA.
class StopDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [StopDetailScreen] for [stopId].
  const StopDetailScreen({
    super.key,
    required this.stopId,
  });

  /// Identifier of the bus stop to inspect.
  final String stopId;

  @override
  ConsumerState<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends ConsumerState<StopDetailScreen> {
  late DayScheduleType _selectedDay;
  String? _filterLineId;
  bool _expandedGroups = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = scheduleTypeForDate(DateTime.now());
  }

  Future<_StopTimetablePayload> _loadDepartures({
    required BusStop stop,
    required List<BusLine> allLines,
    required DayScheduleType scheduleType,
    required bool useSimulatedLive,
    required bool isOffline,
    required DateTime at,
  }) async {
    final timetableRepo = ref.read(timetableRepositoryProvider);
    final todayType = scheduleTypeForDate(at);
    final List<Departure> departures;

    if (scheduleType == todayType) {
      departures = await timetableRepo.getDeparturesForStop(
        stop.id,
        at: at,
        limit: 80,
        useSimulatedLive: useSimulatedLive,
        isOffline: isOffline,
      );
    } else {
      final futures = <Future<List<Departure>>>[];
      for (final line in allLines) {
        for (final direction in line.directions) {
          if (!direction.stopIds.contains(stop.id)) continue;
          futures.add(
            timetableRepo.getDeparturesForLine(
              line.id,
              direction.id,
              at: at,
              scheduleType: scheduleType,
              stopId: stop.id,
              useSimulatedLive: useSimulatedLive,
              isOffline: isOffline,
            ),
          );
        }
      }
      final batches = await Future.wait(futures);
      departures = [
        for (final batch in batches) ...batch,
      ]..sort((a, b) => a.estimatedTime.compareTo(b.estimatedTime));
    }

    return _StopTimetablePayload(
      departures: departures,
      fetchedAt: at,
      isTodaySchedule: scheduleType == todayType,
    );
  }

  void _speakStopSummary(
    BuildContext context,
    BusStop stop,
    List<Departure> departures,
  ) {
    final l10n = context.l10n;
    final locale = ref.read(a11ySettingsProvider).localeCode;
    final platformText =
        stop.platform != null ? ', ${l10n.stopPlatform(stop.platform!)}' : '';
    final nextSummary = departures.isEmpty
        ? l10n.stopNoDepartures
        : departures.take(3).map((d) {
            final time = TimeFormatUtils.formatTime24(d.estimatedTime);
            final status = localizedDelayStatusLabel(
              l10n,
              d.status,
              d.delaySeconds,
              isCancelled: d.isCancelled,
            );
            return '${l10n.linesBadge(d.lineCode)} ${l10n.linesDirectionTo(d.directionName)} $time ($status)';
          }).join('. ');

    final message = '${stop.name}$platformText. $nextSummary';
    announceForAccessibility(context, message);
    ref.read(readAloudProvider).speak(
          message,
          enabled: true,
          localeCode: locale,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stopAsync = ref.watch(stopByIdProvider(widget.stopId));
    final linesAsync = ref.watch(allLinesProvider);
    final favorites = ref.watch(favoritesProvider);
    final settings = ref.watch(a11ySettingsProvider);
    final isOffline = ref.watch(isOfflineProvider);

    return stopAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.stopTitle)),
        body: const LoadingStateView(),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.stopTitle)),
        body: ErrorStateView(
          onRetry: () => ref.invalidate(stopByIdProvider(widget.stopId)),
        ),
      ),
      data: (stop) {
        if (stop == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.stopTitle)),
            body: EmptyStateView(title: l10n.commonEmpty),
          );
        }

        final allLines = linesAsync.valueOrNull ?? const <BusLine>[];
        final linesMap = {for (final l in allLines) l.id: l};
        final isFavorite = favorites.isStopFavorite(stop.id);
        final now = DateTime.now();

        return Scaffold(
          appBar: AppBar(
            title: Text(stop.name),
            actions: [
              Semantics(
                button: true,
                toggled: isFavorite,
                label: l10n.a11yFavoriteToggle,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isFavorite
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  tooltip: isFavorite
                      ? l10n.stopRemoveFromFavorites
                      : l10n.stopAddToFavorites,
                  constraints: const BoxConstraints(
                    minWidth: 56,
                    minHeight: 56,
                  ),
                  onPressed: () {
                    HapticCues.trigger(
                      HapticCueType.tap,
                      enabled: settings.hapticAlertsEnabled,
                    );
                    ref.read(favoritesProvider.notifier).toggleStop(stop.id);
                  },
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: FutureBuilder<_StopTimetablePayload>(
                  future: _loadDepartures(
                    stop: stop,
                    allLines: allLines,
                    scheduleType: _selectedDay,
                    useSimulatedLive: settings.useSimulatedLive,
                    isOffline: isOffline,
                    at: now,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const LoadingStateView();
                    }

                    final payload = snapshot.data ??
                        _StopTimetablePayload(
                          departures: const [],
                          fetchedAt: now,
                          isTodaySchedule: true,
                        );
                    final filteredDepartures = _filterLineId == null
                        ? payload.departures
                        : payload.departures
                            .where((d) => d.lineId == _filterLineId)
                            .toList(growable: false);
                    final groups = _groupByLineDirection(filteredDepartures);

                    return ListView(
                      children: [
                        ResponsiveContentContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStopHeaderCard(
                                context: context,
                                l10n: l10n,
                                stop: stop,
                                isFavorite: isFavorite,
                                hapticEnabled: settings.hapticAlertsEnabled,
                                departures: filteredDepartures,
                              ),
                              const SizedBox(height: 16),
                              _buildControlsCard(
                                context: context,
                                l10n: l10n,
                                stop: stop,
                                linesMap: linesMap,
                                fetchedAt: payload.fetchedAt,
                                useSimulatedLive: settings.useSimulatedLive,
                              ),
                              const SizedBox(height: 16),
                              if (groups.isEmpty)
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: EmptyStateView(
                                      icon: Icons.departure_board_outlined,
                                      title: l10n.stopNoDepartures,
                                    ),
                                  ),
                                )
                              else ...[
                                for (final group in groups) ...[
                                  _DepartureDirectionGroupCard(
                                    group: group,
                                    line: linesMap[group.lineId],
                                    now: now,
                                    showRelativeCountdown:
                                        payload.isTodaySchedule,
                                    expanded: _expandedGroups,
                                    onOpenLine: () => context.push(
                                      '/lines/${Uri.encodeComponent(group.lineId)}',
                                    ),
                                    onOpenTracker: () => context.push(
                                      '/tracker?lineId=${Uri.encodeComponent(group.lineId)}'
                                      '&stopId=${Uri.encodeComponent(stop.id)}',
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                if (groups.any((g) => g.departures.length > 4))
                                  BigButton(
                                    icon: _expandedGroups
                                        ? Icons.expand_less_rounded
                                        : Icons.expand_more_rounded,
                                    label: _expandedGroups
                                        ? l10n.commonShowLess
                                        : l10n.commonShowMore,
                                    variant: BigButtonVariant.outlined,
                                    expanded: true,
                                    onPressed: () => setState(
                                      () => _expandedGroups = !_expandedGroups,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildStopHeaderCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required BusStop stop,
    required bool isFavorite,
    required bool hapticEnabled,
    required List<Departure> departures,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stop.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (stop.platform != null) ...[
              const SizedBox(height: 6),
              Text(
                l10n.stopPlatform(stop.platform!),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              l10n.stopAmenitiesTitle,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            BusStopAmenitiesWrap(stop: stop),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                BigButton(
                  icon: Icons.alt_route_rounded,
                  label: l10n.stopPlanFromHere,
                  onPressed: () => context.go(
                    '/plan?fromStopId=${Uri.encodeComponent(stop.id)}',
                  ),
                ),
                BigButton(
                  icon: isFavorite
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  label: isFavorite
                      ? l10n.stopRemoveFromFavorites
                      : l10n.stopAddToFavorites,
                  variant: BigButtonVariant.secondary,
                  onPressed: () {
                    HapticCues.trigger(
                      HapticCueType.tap,
                      enabled: hapticEnabled,
                    );
                    ref.read(favoritesProvider.notifier).toggleStop(stop.id);
                  },
                ),
                BigButton(
                  icon: Icons.volume_up_rounded,
                  label: l10n.a11yReadAloudButton,
                  variant: BigButtonVariant.outlined,
                  onPressed: () =>
                      _speakStopSummary(context, stop, departures),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required BusStop stop,
    required Map<String, BusLine> linesMap,
    required DateTime fetchedAt,
    required bool useSimulatedLive,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.stopUpcomingDepartures,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TransitFreshnessHeader(
              useSimulatedLive: useSimulatedLive,
              updatedAt: fetchedAt,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.stopLiveAndScheduledNote,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.stopSelectDay,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in DayScheduleType.values)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: type == _selectedDay
                        ? FilledButton(
                            onPressed: () {},
                            child: Text(localizedDayScheduleLabel(l10n, type)),
                          )
                        : OutlinedButton(
                            onPressed: () =>
                                setState(() => _selectedDay = type),
                            child: Text(localizedDayScheduleLabel(l10n, type)),
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: _filterLineId == null
                      ? FilledButton(
                          onPressed: () {},
                          child: Text(l10n.stopAllLines),
                        )
                      : OutlinedButton(
                          onPressed: () =>
                              setState(() => _filterLineId = null),
                          child: Text(l10n.stopAllLines),
                        ),
                ),
                for (final lineId in stop.lineIds)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: _filterLineId == lineId
                        ? FilledButton(
                            onPressed: () =>
                                setState(() => _filterLineId = null),
                            child: Text(
                              l10n.linesBadge(
                                linesMap[lineId]?.code ?? lineId,
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: () =>
                                setState(() => _filterLineId = lineId),
                            child: Text(
                              l10n.linesBadge(
                                linesMap[lineId]?.code ?? lineId,
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_LineDirectionGroup> _groupByLineDirection(
    List<Departure> departures,
  ) {
    final map = <String, _LineDirectionGroup>{};
    for (final dep in departures) {
      final key = '${dep.lineId}|${dep.directionId}';
      map.putIfAbsent(
        key,
        () => _LineDirectionGroup(
          lineId: dep.lineId,
          lineCode: dep.lineCode,
          directionId: dep.directionId,
          directionName: dep.directionName,
          departures: [],
        ),
      ).departures.add(dep);
    }
    return map.values.toList(growable: false);
  }
}

class _StopTimetablePayload {
  const _StopTimetablePayload({
    required this.departures,
    required this.fetchedAt,
    required this.isTodaySchedule,
  });

  final List<Departure> departures;
  final DateTime fetchedAt;
  final bool isTodaySchedule;
}

class _LineDirectionGroup {
  _LineDirectionGroup({
    required this.lineId,
    required this.lineCode,
    required this.directionId,
    required this.directionName,
    required this.departures,
  });

  final String lineId;
  final String lineCode;
  final String directionId;
  final String directionName;
  final List<Departure> departures;
}

class _DepartureDirectionGroupCard extends StatelessWidget {
  const _DepartureDirectionGroupCard({
    required this.group,
    required this.line,
    required this.now,
    required this.showRelativeCountdown,
    required this.expanded,
    required this.onOpenLine,
    required this.onOpenTracker,
  });

  final _LineDirectionGroup group;
  final BusLine? line;
  final DateTime now;
  final bool showRelativeCountdown;
  final bool expanded;
  final VoidCallback onOpenLine;
  final VoidCallback onOpenTracker;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visible =
        expanded ? group.departures : group.departures.take(4).toList();
    final lineColor = line?.color ?? Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                LineBadge(
                  code: group.lineCode,
                  color: lineColor,
                  showLineWord: true,
                ),
                Text(
                  l10n.linesDirectionTo(group.directionName),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: OutlinedButton.icon(
                    onPressed: onOpenLine,
                    icon: const Icon(Icons.route_rounded),
                    label: Text(l10n.linesBadge(group.lineCode)),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: OutlinedButton.icon(
                    onPressed: onOpenTracker,
                    icon: const Icon(Icons.gps_fixed_rounded),
                    label: Text(l10n.linesFollowBusLive),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final dep in visible) ...[
              DepartureTileCard(
                departure: dep,
                now: now,
                lineColor: lineColor,
                showLineBadge: false,
                showRelativeCountdown: showRelativeCountdown,
                onTap: onOpenTracker,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
