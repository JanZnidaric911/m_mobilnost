// Monitors device network connectivity safely with an offline simulation toggle.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Optional usability-testing override to simulate offline mode locally.
final simulatedOfflineProvider = StateProvider<bool>((ref) => false);

/// Emits true when the device currently has network connectivity.
final networkOnlineStreamProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool initialOnline = true;
  try {
    final results = await connectivity.checkConnectivity();
    initialOnline = _hasConnection(results);
  } catch (_) {
    initialOnline = true;
  }
  yield initialOnline;

  try {
    await for (final results in connectivity.onConnectivityChanged) {
      yield _hasConnection(results);
    }
  } catch (_) {
    // Gracefully keep last known state when platform channel is unavailable.
  }
});

/// Returns true when offline (either via device radio or usability-test toggle).
final isOfflineProvider = Provider<bool>((ref) {
  final simulatedOffline = ref.watch(simulatedOfflineProvider);
  if (simulatedOffline) return true;

  final onlineAsync = ref.watch(networkOnlineStreamProvider);
  return !(onlineAsync.valueOrNull ?? true);
});

/// Helper methods to evaluate [ConnectivityResult] lists safely.
@visibleForTesting
bool hasActiveConnectivity(List<ConnectivityResult> results) =>
    _hasConnection(results);

bool _hasConnection(List<ConnectivityResult> results) {
  if (results.isEmpty) return false;
  return results.any((r) => r != ConnectivityResult.none);
}
