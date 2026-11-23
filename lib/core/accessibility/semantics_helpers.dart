// Provides screen-reader semantics utilities and localization context helpers.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../l10n/app_localizations.dart';

/// Convenience accessor for [AppLocalizations] on [BuildContext].
extension L10nBuildContextX on BuildContext {
  /// Returns the active [AppLocalizations] instance for this widget subtree.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// Announces [message] politely to active platform screen readers when possible.
Future<void> announceForAccessibility(
  BuildContext context,
  String message,
) async {
  if (message.trim().isEmpty) return;
  try {
    final view = View.maybeOf(context);
    if (view == null) return;
    await SemanticsService.sendAnnouncement(
      view,
      message,
      Directionality.of(context),
    );
  } catch (_) {
    // Ignore unsupported announcement channels in tests or web environments.
  }
}

/// Wraps [child] in a merged semantic section with an optional [label] and [header].
class AccessibleSection extends StatelessWidget {
  /// Creates an [AccessibleSection] grouping related elements for screen readers.
  const AccessibleSection({
    super.key,
    required this.child,
    this.label,
    this.header = false,
    this.liveRegion = false,
  });

  /// Content inside this semantic region.
  final Widget child;

  /// Optional accessible label describing the section.
  final String? label;

  /// Whether this section acts as a semantic heading.
  final bool header;

  /// Whether dynamic content changes should be announced as a live region.
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      header: header,
      liveRegion: liveRegion,
      label: label,
      child: child,
    );
  }
}
