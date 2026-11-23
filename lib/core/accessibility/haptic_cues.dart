// Provides distinct haptic and optional sound alert patterns for transit events.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Distinct haptic cue patterns mapped to transit events.
enum HapticCueType {
  /// Two crisp medium taps when the tracked bus is arriving.
  arriving,

  /// Heavy pulse followed by a softer follow-up for delayed buses.
  late,

  /// Three rapid medium pulses warning of an expiring ticket.
  ticketExpiring,

  /// Strong vibration + heavy impact for service disruptions.
  disruption,

  /// Single light selection click for standard UI interactions.
  tap,
}

/// Safe, web-guarded haptic feedback and optional alert-sound helper.
abstract final class HapticCues {
  /// Triggers the haptic cue for [type] when [enabled] and not running on web.
  static Future<void> trigger(
    HapticCueType type, {
    required bool enabled,
    bool soundOptional = false,
  }) async {
    if (!enabled || kIsWeb) return;

    try {
      switch (type) {
        case HapticCueType.tap:
          await HapticFeedback.selectionClick();
        case HapticCueType.arriving:
          await HapticFeedback.mediumImpact();
          if (_supportsMultiPulse) {
            await Future<void>.delayed(const Duration(milliseconds: 110));
            await HapticFeedback.mediumImpact();
          }
        case HapticCueType.late:
          await HapticFeedback.heavyImpact();
          if (_supportsMultiPulse) {
            await Future<void>.delayed(const Duration(milliseconds: 160));
            await HapticFeedback.lightImpact();
          }
        case HapticCueType.ticketExpiring:
          await HapticFeedback.mediumImpact();
          if (_supportsMultiPulse) {
            await Future<void>.delayed(const Duration(milliseconds: 80));
            await HapticFeedback.mediumImpact();
            await Future<void>.delayed(const Duration(milliseconds: 80));
            await HapticFeedback.mediumImpact();
          }
        case HapticCueType.disruption:
          await HapticFeedback.vibrate();
          if (_supportsMultiPulse) {
            await Future<void>.delayed(const Duration(milliseconds: 140));
            await HapticFeedback.heavyImpact();
          }
      }

      if (soundOptional && type != HapticCueType.tap) {
        await SystemSound.play(SystemSoundType.alert);
      }
    } catch (_) {
      // Safely ignore platform channels unavailable in tests or desktops.
    }
  }

  static bool get _supportsMultiPulse =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
