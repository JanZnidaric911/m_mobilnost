// Responsive navigation shell switching between NavigationBar and NavigationRail.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/accessibility/semantics_helpers.dart';
import '../core/layout/breakpoints.dart';
import '../core/theme/colors.dart';
import '../core/widgets/offline_banner.dart';
import '../core/widgets/simulated_data_badge.dart';
import '../features/web_portal/presentation/marprom_web_scaffold.dart';

/// Top-level adaptive scaffold hosting the 4 primary transit destinations.
class ShellScaffold extends StatelessWidget {
  /// Creates a [ShellScaffold] wrapping [navigationShell].
  const ShellScaffold({
    super.key,
    required this.navigationShell,
  });

  /// Active GoRouter stateful navigation shell.
  final StatefulNavigationShell navigationShell;

  void _onSelectBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final width = MediaQuery.sizeOf(context).width;
    final layoutSize = LayoutBreakpoints.fromWidth(width);
    final isCompact = layoutSize == ScreenLayoutSize.compact;
    final isExpanded = layoutSize == ScreenLayoutSize.expanded;

    final destinations = <(IconData, IconData, String)>[
      (Icons.home_outlined, Icons.home_rounded, l10n.navHome),
      (Icons.map_outlined, Icons.map_rounded, l10n.navMap),
      (Icons.alt_route_outlined, Icons.alt_route_rounded, l10n.navPlan),
      (
        Icons.confirmation_number_outlined,
        Icons.confirmation_number_rounded,
        l10n.navTickets,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MarpromColors.marpromRed,
        foregroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MarpromBrandEmblem(size: 30),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                l10n.appTitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Live Fleet & Stats',
            child: IconButton(
              icon: const Icon(Icons.insights_rounded),
              tooltip: 'Avtobusi v živo',
              constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
              onPressed: () => context.push('/live'),
            ),
          ),
          Semantics(
            button: true,
            label: l10n.a11yNoticesButton,
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: l10n.navNotices,
              constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
              onPressed: () => context.push('/notices'),
            ),
          ),
          Semantics(
            button: true,
            label: l10n.a11yProfileButton,
            child: IconButton(
              icon: const Icon(Icons.person_outline_rounded),
              tooltip: l10n.navAccount,
              constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
              onPressed: () => context.push('/account'),
            ),
          ),
          Semantics(
            button: true,
            label: l10n.a11ySettingsButton,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.navSettings,
              constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
              onPressed: () => context.push('/settings'),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (!isCompact)
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onSelectBranch,
              extended: isExpanded,
              labelType: isExpanded
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: [
                for (final (icon, activeIcon, label) in destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(activeIcon),
                    label: Text(label),
                  ),
              ],
            ),
          if (!isCompact) const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                const OfflineBanner(),
                const _SourceStatusBar(),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isCompact
          ? NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onSelectBranch,
              destinations: [
                for (final (icon, activeIcon, label) in destinations)
                  NavigationDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(activeIcon),
                    label: label,
                  ),
              ],
            )
          : null,
    );
  }
}

class _SourceStatusBar extends StatelessWidget {
  const _SourceStatusBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SimulatedDataBadge(),
      ),
    );
  }
}
