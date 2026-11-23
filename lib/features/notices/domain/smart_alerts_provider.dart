// Persists smart local notification alert preferences via SharedPreferences.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/accessibility/a11y_settings.dart';

/// Immutable preferences for local transit smart alerts.
@immutable
class SmartAlertsState {
  /// Creates a [SmartAlertsState] snapshot.
  const SmartAlertsState({
    this.busArrivingSoon = true,
    this.favoriteLineDelayed = true,
    this.ticketExpiringSoon = true,
  });

  /// Notify before a tracked or nearby bus arrives.
  final bool busArrivingSoon;

  /// Notify when a disruption or delay affects a favorite line.
  final bool favoriteLineDelayed;

  /// Notify shortly before an active ticket expires.
  final bool ticketExpiringSoon;

  /// Returns a copy with updated alert toggles.
  SmartAlertsState copyWith({
    bool? busArrivingSoon,
    bool? favoriteLineDelayed,
    bool? ticketExpiringSoon,
  }) {
    return SmartAlertsState(
      busArrivingSoon: busArrivingSoon ?? this.busArrivingSoon,
      favoriteLineDelayed: favoriteLineDelayed ?? this.favoriteLineDelayed,
      ticketExpiringSoon: ticketExpiringSoon ?? this.ticketExpiringSoon,
    );
  }
}

/// Riverpod provider exposing [SmartAlertsNotifier] and [SmartAlertsState].
final smartAlertsProvider =
    StateNotifierProvider<SmartAlertsNotifier, SmartAlertsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SmartAlertsNotifier(prefs);
});

/// Manages and persists [SmartAlertsState] preferences locally.
class SmartAlertsNotifier extends StateNotifier<SmartAlertsState> {
  /// Creates a [SmartAlertsNotifier] backed by optional [SharedPreferences].
  SmartAlertsNotifier(this._prefs) : super(_loadInitial(_prefs));

  final SharedPreferences? _prefs;

  static const _kArriving = 'smart_alert_bus_arriving';
  static const _kLineDelayed = 'smart_alert_line_delayed';
  static const _kTicketExpiring = 'smart_alert_ticket_expiring';

  static SmartAlertsState _loadInitial(SharedPreferences? prefs) {
    if (prefs == null) return const SmartAlertsState();
    return SmartAlertsState(
      busArrivingSoon: prefs.getBool(_kArriving) ?? true,
      favoriteLineDelayed: prefs.getBool(_kLineDelayed) ?? true,
      ticketExpiringSoon: prefs.getBool(_kTicketExpiring) ?? true,
    );
  }

  /// Updates [busArrivingSoon] and persists it locally.
  Future<void> setBusArrivingSoon(bool value) async {
    state = state.copyWith(busArrivingSoon: value);
    await _prefs?.setBool(_kArriving, value);
  }

  /// Updates [favoriteLineDelayed] and persists it locally.
  Future<void> setFavoriteLineDelayed(bool value) async {
    state = state.copyWith(favoriteLineDelayed: value);
    await _prefs?.setBool(_kLineDelayed, value);
  }

  /// Updates [ticketExpiringSoon] and persists it locally.
  Future<void> setTicketExpiringSoon(bool value) async {
    state = state.copyWith(ticketExpiringSoon: value);
    await _prefs?.setBool(_kTicketExpiring, value);
  }
}
