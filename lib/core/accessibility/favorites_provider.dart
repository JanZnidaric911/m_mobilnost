// Persists and exposes favorite stops, favorite lines, and manual stop selection.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'a11y_settings.dart';

/// Immutable user favorites and manual location selection state.
@immutable
class FavoritesState {
  /// Default Maribor central stop matching `seed_stops.dart`.
  static const String defaultManualStopId = 'glavni_trg';

  /// Creates a [FavoritesState] snapshot.
  const FavoritesState({
    this.stopIds = const <String>{},
    this.lineIds = const <String>{},
    this.manualStopId = defaultManualStopId,
  });

  /// Favorited bus stop IDs.
  final Set<String> stopIds;

  /// Favorited bus line IDs.
  final Set<String> lineIds;

  /// Manually chosen starting stop ID when GPS is disabled or denied.
  final String? manualStopId;

  /// Whether [stopId] is currently marked as a favorite stop.
  bool isStopFavorite(String stopId) => stopIds.contains(stopId);

  /// Whether [lineId] is currently marked as a favorite line.
  bool isLineFavorite(String lineId) => lineIds.contains(lineId);

  /// Returns a copy with specified fields replaced.
  FavoritesState copyWith({
    Set<String>? stopIds,
    Set<String>? lineIds,
    String? manualStopId,
    bool clearManualStop = false,
  }) {
    return FavoritesState(
      stopIds: stopIds ?? this.stopIds,
      lineIds: lineIds ?? this.lineIds,
      manualStopId:
          clearManualStop ? null : (manualStopId ?? this.manualStopId),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoritesState &&
        setEquals(other.stopIds, stopIds) &&
        setEquals(other.lineIds, lineIds) &&
        other.manualStopId == manualStopId;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(stopIds),
        Object.hashAllUnordered(lineIds),
        manualStopId,
      );
}

/// Riverpod provider exposing [FavoritesNotifier] and current [FavoritesState].
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FavoritesNotifier(prefs);
});

/// Manages and persists favorite stops, lines, and manual stop selection.
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  /// Creates a [FavoritesNotifier] backed by optional [SharedPreferences].
  FavoritesNotifier(this._prefs) : super(_loadInitial(_prefs));

  final SharedPreferences? _prefs;

  static const _kStopIds = 'fav_stop_ids';
  static const _kLineIds = 'fav_line_ids';
  static const _kManualStopId = 'fav_manual_stop_id';

  static FavoritesState _loadInitial(SharedPreferences? prefs) {
    if (prefs == null) return const FavoritesState();
    final stops = (prefs.getStringList(_kStopIds) ?? const <String>[]).toSet();
    final lines = (prefs.getStringList(_kLineIds) ?? const <String>[]).toSet();
    final manual =
        prefs.getString(_kManualStopId) ?? FavoritesState.defaultManualStopId;
    return FavoritesState(
      stopIds: stops,
      lineIds: lines,
      manualStopId: manual.isEmpty ? null : manual,
    );
  }

  /// Adds or removes [id] in [FavoritesState.stopIds] and persists it.
  Future<void> toggleStop(String id) async {
    final next = Set<String>.from(state.stopIds);
    if (!next.add(id)) {
      next.remove(id);
    }
    state = state.copyWith(stopIds: Set<String>.unmodifiable(next));
    await _prefs?.setStringList(_kStopIds, next.toList(growable: false));
  }

  /// Adds or removes [id] in [FavoritesState.lineIds] and persists it.
  Future<void> toggleLine(String id) async {
    final next = Set<String>.from(state.lineIds);
    if (!next.add(id)) {
      next.remove(id);
    }
    state = state.copyWith(lineIds: Set<String>.unmodifiable(next));
    await _prefs?.setStringList(_kLineIds, next.toList(growable: false));
  }

  /// Updates and persists the manually selected starting stop [id].
  Future<void> setManualStop(String? id) async {
    final trimmed = id?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      state = state.copyWith(clearManualStop: true);
      await _prefs?.setString(_kManualStopId, '');
      return;
    }
    state = state.copyWith(manualStopId: trimmed);
    await _prefs?.setString(_kManualStopId, trimmed);
  }

  /// Clears saved favorites and restores the default manual Maribor stop.
  Future<void> clearAll() async {
    state = const FavoritesState();
    await _prefs?.remove(_kStopIds);
    await _prefs?.remove(_kLineIds);
    await _prefs?.remove(_kManualStopId);
  }
}
