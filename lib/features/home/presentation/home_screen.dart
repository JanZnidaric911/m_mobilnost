// Calm personalized Home dashboard answering where am I, what is next, and what to do.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/accessibility/a11y_settings.dart';
import '../../../core/accessibility/favorites_provider.dart';
import '../../../core/accessibility/read_aloud.dart';
import '../../../core/accessibility/semantics_helpers.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_builder.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/distance.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/occupancy_strip.dart';
import '../../../core/widgets/simulated_data_badge.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/departure.dart';
import '../../../data/models/service_notice.dart';
import '../../../data/models/ticket.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/home_dashboard_provider.dart';
import 'ask_marprom_sheet.dart';

/// Primary Home screen providing calm next-bus, notice, ticket, and action cards.
class HomeScreen extends ConsumerWidget {
  /// Creates the personalized [HomeScreen] hosted inside the app shell.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(a11ySettingsProvider);
    final favorites = ref.watch(favoritesProvider);
    final dashboardAsync = ref.watch(homeDashboardProvider);
    final noticesAsync = ref.watch(serviceNoticesStreamProvider);
    final ticketsAsync = ref.watch(homeUserTicketsProvider);

    return dashboardAsync.when(
      loading: () => const LoadingStateView(),
      error: (_, _) => ErrorStateView(
        onRetry: () => ref.invalidate(homeDashboardProvider),
      ),
      data: (dashboard) {
        final favoriteNotice = _findFavoriteNotice(
          notices: noticesAsync.valueOrNull ?? const <ServiceNotice>[],
          favorites: favorites,
        );
        final activeTicket = _findActiveTicket(
          ticketsAsync.valueOrNull ?? const <Ticket>[],
        );

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeDashboardProvider);
            await ref.read(homeDashboardProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              ResponsiveContentContainer(
                child: ResponsiveBuilder(
                  builder: (context, layoutSize, _) {
                    final primaryCards = <Widget>[
                      if (favoriteNotice != null) ...[
                        _FavoriteNoticeAlertCard(
                          notice: favoriteNotice,
                          localeCode: settings.localeCode,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _GreetingAndLocationHeader(dashboard: dashboard),
                      const SizedBox(height: 12),
                      _NextBusSummaryCard(
                        dashboard: dashboard,
                        settings: settings,
                        onRefresh: () => ref.invalidate(homeDashboardProvider),
                      ),
                      if (activeTicket != null) ...[
                        const SizedBox(height: 16),
                        _ActiveTicketCard(
                          ticket: activeTicket,
                          localeCode: settings.localeCode,
                        ),
                      ],
                    ];

                    final secondaryCards = <Widget>[
                      _QuickActionsSection(l10n: l10n),
                      const SizedBox(height: 16),
                      _FavoritesSection(
                        dashboard: dashboard,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 16),
                      _AskMarpromCard(
                        dashboard: dashboard,
                        l10n: l10n,
                      ),
                    ];

                    final isExpanded = layoutSize == ScreenLayoutSize.expanded ||
                        LayoutBreakpoints.fromWidth(
                              MediaQuery.sizeOf(context).width,
                            ) ==
                            ScreenLayoutSize.expanded;
                    if (isExpanded) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: primaryCards,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: secondaryCards,
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...primaryCards,
                        const SizedBox(height: 16),
                        ...secondaryCards,
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

  ServiceNotice? _findFavoriteNotice({
    required List<ServiceNotice> notices,
    required FavoritesState favorites,
  }) {
    if (favorites.lineIds.isEmpty && favorites.stopIds.isEmpty) return null;
    final now = DateTime.now();
    for (final notice in notices) {
      if (!notice.isActiveAt(now)) continue;
      final hitsLine =
          notice.affectedLineIds.any(favorites.lineIds.contains);
      final hitsStop =
          notice.affectedStopIds.any(favorites.stopIds.contains);
      if (hitsLine || hitsStop) return notice;
    }
    return null;
  }

  Ticket? _findActiveTicket(List<Ticket> tickets) {
    final now = DateTime.now();
    for (final ticket in tickets) {
      if (ticket.statusAt(now) == TicketStatus.active) {
        return ticket;
      }
    }
    return null;
  }
}

class _FavoriteNoticeAlertCard extends StatelessWidget {
  const _FavoriteNoticeAlertCard({
    required this.notice,
    required this.localeCode,
  });

  final ServiceNotice notice;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusColors = Theme.of(context).extension<MarpromStatusColors>();
    final isDisruption = notice.severity == NoticeSeverity.disruption;
    final chipType = switch (notice.severity) {
      NoticeSeverity.disruption => TransitStatusType.disruption,
      NoticeSeverity.delay => TransitStatusType.late,
      NoticeSeverity.info => TransitStatusType.info,
    };

    return AccessibleSection(
      liveRegion: true,
      label: l10n.homeActiveDisruptionAlert,
      child: Card(
        color: isDisruption ? statusColors?.disruptionBg : statusColors?.warningBg,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/notices'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusChip(type: chipType),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.homeActiveDisruptionAlert,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notice.localizedTitle(localeCode),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GreetingAndLocationHeader extends StatelessWidget {
  const _GreetingAndLocationHeader({required this.dashboard});

  final HomeDashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stop = dashboard.primaryStop;
    final dist = DistanceUtils.formatMeters(
      dashboard.distanceToPrimaryStopMeters.toDouble(),
      l10n,
    );

    return AccessibleSection(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeGreeting,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/nearest-stop'),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      dashboard.usingManualLocation
                          ? Icons.pin_drop_outlined
                          : Icons.my_location_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${stop.name} • ${l10n.nearestStopDistance(dist)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextBusSummaryCard extends ConsumerWidget {
  const _NextBusSummaryCard({
    required this.dashboard,
    required this.settings,
    required this.onRefresh,
  });

  final HomeDashboardData dashboard;
  final A11ySettings settings;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dep = dashboard.nextDeparture;
    final hms = DateFormat('HH:mm:ss').format(dashboard.fetchedAt);

    if (dep == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.stopNoDepartures,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              BigButton(
                icon: Icons.refresh_rounded,
                label: l10n.commonRefresh,
                variant: BigButtonVariant.outlined,
                onPressed: onRefresh,
              ),
            ],
          ),
        ),
      );
    }

    final mins = dep.estimatedTime
        .difference(dashboard.fetchedAt)
        .inMinutes
        .clamp(0, 999);
    final summary = l10n.homeNextBusSummary(
      dep.directionName,
      dep.lineCode,
      mins,
      dashboard.distanceToPrimaryStopMeters,
    );

    final statusLabel = _departureStatusLabel(dep, l10n);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          '/tracker?lineId=${dep.lineId}&stopId=${dep.stopId}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusChip(type: dep.status, label: statusLabel),
                        SimulatedDataBadge(freshness: dep.freshness),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: l10n.commonRefresh,
                    constraints:
                        const BoxConstraints(minWidth: 56, minHeight: 56),
                    onPressed: onRefresh,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                '${TimeFormatUtils.formatTime24(dep.estimatedTime)} • ${dashboard.primaryStop.name}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              OccupancyStrip(level: dep.occupancy),
              const SizedBox(height: 12),
              if (!settings.useSimulatedLive) ...[
                Text(
                  l10n.freshnessLiveDisabledFallback,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
              ],
              Text(
                l10n.commonLastUpdatedAt(hms),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              BigButton(
                icon: Icons.volume_up_rounded,
                label: l10n.a11yReadAloudButton,
                variant: BigButtonVariant.outlined,
                expanded: true,
                onPressed: () {
                  ref.read(readAloudProvider).speak(
                        summary,
                        enabled: true,
                        localeCode: settings.localeCode,
                      );
                  announceForAccessibility(context, summary);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _departureStatusLabel(Departure dep, AppLocalizations l10n) {
    if (dep.isCancelled) return l10n.statusCancelled;
    if (dep.delaySeconds < -60) {
      return l10n.statusEarlyByMinutes((-dep.delaySeconds / 60).round());
    }
    if (dep.delaySeconds > 120) {
      return l10n.statusLateByMinutes((dep.delaySeconds / 60).round());
    }
    return l10n.statusOnTime;
  }
}

class _ActiveTicketCard extends StatelessWidget {
  const _ActiveTicketCard({
    required this.ticket,
    required this.localeCode,
  });

  final Ticket ticket;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final remaining = ticket.validUntil.difference(DateTime.now());
    final remainingLabel = remaining.inHours >= 1
        ? l10n.commonHoursShort(remaining.inHours)
        : l10n.commonMinutesShort(remaining.inMinutes.clamp(1, 59));

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/tickets/view/${ticket.id}'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.qr_code_2_rounded,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeActiveTicket,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ticket.localizedTitle(localeCode),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.ticketsValidUntil(TimeFormatUtils.formatTime24(ticket.validUntil))} • ${l10n.ticketsRemainingTime(remainingLabel)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AccessibleSection(
      header: true,
      label: l10n.homeQuickActions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeQuickActions,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              BigButton(
                icon: Icons.alt_route_rounded,
                label: l10n.homePlanTripAction,
                expanded: true,
                onPressed: () => context.go('/plan'),
              ),
              const SizedBox(height: 10),
              BigButton(
                icon: Icons.my_location_rounded,
                label: l10n.homeNearestStopAction,
                variant: BigButtonVariant.secondary,
                expanded: true,
                onPressed: () => context.push('/nearest-stop'),
              ),
              const SizedBox(height: 10),
              BigButton(
                icon: Icons.confirmation_number_outlined,
                label: l10n.homeBuyTicketAction,
                variant: BigButtonVariant.secondary,
                expanded: true,
                onPressed: () => context.go('/tickets/shop'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              BigButton(
                icon: Icons.map_outlined,
                label: l10n.navMap,
                variant: BigButtonVariant.outlined,
                onPressed: () => context.go('/map'),
              ),
              BigButton(
                icon: Icons.directions_bus_rounded,
                label: l10n.homeLinesAction,
                variant: BigButtonVariant.outlined,
                onPressed: () => context.push('/lines'),
              ),
              BigButton(
                icon: Icons.school_outlined,
                label: l10n.homeGuideAction,
                variant: BigButtonVariant.outlined,
                onPressed: () => context.push('/guide'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection({
    required this.dashboard,
    required this.l10n,
  });

  final HomeDashboardData dashboard;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AccessibleSection(
      header: true,
      label: l10n.homeFavoriteStops,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeFavoriteStops,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (dashboard.favoriteStops.isEmpty &&
              dashboard.favoriteLines.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeNoFavoriteStops,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        BigButton(
                          icon: Icons.directions_bus_rounded,
                          label: l10n.navLines,
                          variant: BigButtonVariant.outlined,
                          onPressed: () => context.push('/lines'),
                        ),
                        BigButton(
                          icon: Icons.map_outlined,
                          label: l10n.navMap,
                          variant: BigButtonVariant.outlined,
                          onPressed: () => context.go('/map'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (dashboard.favoriteLines.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final line in dashboard.favoriteLines)
                    BigButton(
                      icon: Icons.directions_bus_rounded,
                      label: l10n.linesBadge(line.code),
                      variant: BigButtonVariant.outlined,
                      onPressed: () => context.push('/lines/${line.id}'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            for (final preview in dashboard.favoriteStops) ...[
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/stops/${preview.stop.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                preview.stop.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (preview.departures.isEmpty)
                          Text(
                            l10n.stopNoDepartures,
                            style: Theme.of(context).textTheme.bodyMedium,
                          )
                        else
                          for (final dep in preview.departures.take(3)) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${l10n.linesBadge(dep.lineCode)} • ${dep.directionName}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        TimeFormatUtils.formatTime24(
                                          dep.estimatedTime,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  StatusChip(type: dep.status, compact: true),
                                ],
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _AskMarpromCard extends StatelessWidget {
  const _AskMarpromCard({
    required this.dashboard,
    required this.l10n,
  });

  final HomeDashboardData dashboard;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final samples = [
      l10n.askSample1,
      l10n.askSample2,
      l10n.askSample3,
      l10n.askSample4,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.askTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.askSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sample in samples)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(56, 56),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    label: Text(sample),
                    onPressed: () => showAskMarpromSheet(
                      context,
                      initialQuery: sample,
                      userPosition: dashboard.userPosition,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            BigButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: l10n.homeAskMarpromAction,
              variant: BigButtonVariant.primary,
              expanded: true,
              onPressed: () => showAskMarpromSheet(
                context,
                userPosition: dashboard.userPosition,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
