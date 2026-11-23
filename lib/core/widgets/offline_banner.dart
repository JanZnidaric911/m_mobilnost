// Displays an accessible banner when the app is offline or in offline test mode.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accessibility/semantics_helpers.dart';
import '../network/connectivity_provider.dart';
import '../theme/colors.dart';
import '../utils/time_format.dart';

/// Live-region banner informing passengers that cached offline data is active.
class OfflineBanner extends ConsumerWidget {
  /// Creates an [OfflineBanner]; optionally overrides connectivity via [forceOffline].
  const OfflineBanner({
    super.key,
    this.forceOffline,
    this.lastSync,
  });

  /// Explicit offline override for previews or isolated tests.
  final bool? forceOffline;

  /// Optional timestamp of the last successful data refresh.
  final DateTime? lastSync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isOffline = forceOffline ?? ref.watch(isOfflineProvider);
    if (!isOffline) return const SizedBox.shrink();

    final l10n = context.l10n;
    final statusColors =
        Theme.of(context).extension<MarpromStatusColors>() ??
            MarpromStatusColors.light;

    return Semantics(
      liveRegion: true,
      label: '${l10n.a11yOfflineBanner}: ${l10n.badgeOfflineTitle}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: statusColors.warningBg,
          border: Border(
            bottom: BorderSide(
              color: statusColors.warningFg,
              width: statusColors.highContrastBorders ? 2 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: statusColors.warningFg,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.badgeOfflineTitle,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: statusColors.warningFg,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    lastSync == null
                        ? l10n.badgeOfflineBody
                        : '${l10n.badgeOfflineBody} '
                            '${l10n.badgeOfflineLastSync(TimeFormatUtils.formatTime24(lastSync!))}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: statusColors.warningFg,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
