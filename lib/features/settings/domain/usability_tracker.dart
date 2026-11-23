// Tracks anonymous usability-test scenario timing, taps, errors, and CSV/JSON export.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Anonymous completed usability-test scenario record containing zero personal data.
@immutable
class UsabilityScenarioResult {
  /// Creates a [UsabilityScenarioResult] with strictly non-personal metrics.
  const UsabilityScenarioResult({
    required this.scenarioId,
    required this.durationSeconds,
    required this.tapCount,
    required this.errorCount,
    required this.startedAtUtc,
    required this.completedAtUtc,
  });

  /// Machine-readable scenario identifier (for example `find_next_bus`).
  final String scenarioId;

  /// Total elapsed time in whole seconds from start to completion.
  final int durationSeconds;

  /// Number of recorded user taps during the scenario.
  final int tapCount;

  /// Number of recorded errors/missteps during the scenario.
  final int errorCount;

  /// UTC start timestamp of the scenario.
  final DateTime startedAtUtc;

  /// UTC completion timestamp of the scenario.
  final DateTime completedAtUtc;

  /// Serializes this record as a JSON-compatible map with zero personal data.
  Map<String, dynamic> toJson() => {
        'scenarioId': scenarioId,
        'durationSeconds': durationSeconds,
        'tapCount': tapCount,
        'errorCount': errorCount,
        'startedAtUtc': startedAtUtc.toIso8601String(),
        'completedAtUtc': completedAtUtc.toIso8601String(),
      };
}

/// Immutable state for active and completed usability evaluation sessions.
@immutable
class UsabilityState {
  /// Creates a [UsabilityState] snapshot.
  const UsabilityState({
    this.activeScenarioId,
    this.startedAtUtc,
    this.tapCount = 0,
    this.errorCount = 0,
    this.history = const <UsabilityScenarioResult>[],
  });

  /// Identifier of the currently running scenario, or null when idle.
  final String? activeScenarioId;

  /// UTC timestamp when the active scenario started, or null when idle.
  final DateTime? startedAtUtc;

  /// Taps counted during the current scenario (or last completed summary).
  final int tapCount;

  /// Errors logged during the current scenario (or last completed summary).
  final int errorCount;

  /// Completed anonymous scenario records in chronological order.
  final List<UsabilityScenarioResult> history;

  /// True while a timed scenario is actively running.
  bool get isRunning => activeScenarioId != null && startedAtUtc != null;

  /// Returns a copy with specified fields updated.
  UsabilityState copyWith({
    String? activeScenarioId,
    bool clearActiveScenario = false,
    DateTime? startedAtUtc,
    bool clearStartedAt = false,
    int? tapCount,
    int? errorCount,
    List<UsabilityScenarioResult>? history,
  }) {
    return UsabilityState(
      activeScenarioId: clearActiveScenario
          ? null
          : (activeScenarioId ?? this.activeScenarioId),
      startedAtUtc:
          clearStartedAt ? null : (startedAtUtc ?? this.startedAtUtc),
      tapCount: tapCount ?? this.tapCount,
      errorCount: errorCount ?? this.errorCount,
      history: history ?? this.history,
    );
  }
}

/// Riverpod provider exposing [UsabilityTracker] and current [UsabilityState].
final usabilityTrackerProvider =
    StateNotifierProvider<UsabilityTracker, UsabilityState>((ref) {
  return UsabilityTracker();
});

/// Tracks scenario timing, taps, and errors for privacy-preserving usability testing.
class UsabilityTracker extends StateNotifier<UsabilityState> {
  /// Creates a [UsabilityTracker] using an optional injectable [clock] for tests.
  UsabilityTracker({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(const UsabilityState());

  final DateTime Function() _clock;

  /// Starts a new timed scenario identified by [scenarioId].
  void startScenario(String scenarioId) {
    final cleanId = scenarioId.trim().isEmpty ? 'scenario' : scenarioId.trim();
    state = UsabilityState(
      activeScenarioId: cleanId,
      startedAtUtc: _clock().toUtc(),
      tapCount: 0,
      errorCount: 0,
      history: state.history,
    );
  }

  /// Increments the tap counter when a timed scenario is active.
  void recordTap() {
    if (!state.isRunning) return;
    state = state.copyWith(tapCount: state.tapCount + 1);
  }

  /// Increments the error counter when a timed scenario is active.
  void recordError() {
    if (!state.isRunning) return;
    state = state.copyWith(errorCount: state.errorCount + 1);
  }

  /// Returns elapsed seconds for the running scenario, or the last finished one.
  int elapsedSeconds() {
    if (state.isRunning) {
      return math.max(
        0,
        _clock().toUtc().difference(state.startedAtUtc!).inSeconds,
      );
    }
    if (state.history.isNotEmpty) {
      return state.history.last.durationSeconds;
    }
    return 0;
  }

  /// Completes the active scenario, stores its result in [UsabilityState.history],
  /// and returns the completed record (or null if no scenario was running).
  UsabilityScenarioResult? finishScenario() {
    if (!state.isRunning) return null;
    final completedAt = _clock().toUtc();
    final startedAt = state.startedAtUtc!;
    final seconds = math.max(0, completedAt.difference(startedAt).inSeconds);

    final result = UsabilityScenarioResult(
      scenarioId: state.activeScenarioId!,
      durationSeconds: seconds,
      tapCount: state.tapCount,
      errorCount: state.errorCount,
      startedAtUtc: startedAt,
      completedAtUtc: completedAt,
    );

    state = UsabilityState(
      tapCount: state.tapCount,
      errorCount: state.errorCount,
      history: List<UsabilityScenarioResult>.unmodifiable([
        ...state.history,
        result,
      ]),
    );
    return result;
  }

  /// Clears all completed records and resets counters.
  void clearHistory() {
    state = const UsabilityState();
  }

  /// Exports completed scenarios as RFC-4180 CSV containing zero personal data.
  String exportCsv() {
    final buffer = StringBuffer(
      'scenario_id,duration_seconds,tap_count,error_count,started_at_utc,completed_at_utc',
    );
    for (final item in state.history) {
      buffer.writeln();
      buffer.write(
        '${_csvEscape(item.scenarioId)},'
        '${item.durationSeconds},'
        '${item.tapCount},'
        '${item.errorCount},'
        '${item.startedAtUtc.toIso8601String()},'
        '${item.completedAtUtc.toIso8601String()}',
      );
    }
    return buffer.toString();
  }

  /// Exports completed scenarios as formatted JSON containing zero personal data.
  String exportJson() {
    final payload = <String, dynamic>{
      'schemaVersion': 1,
      'containsPersonalData': false,
      'scenarios': [
        for (final item in state.history) item.toJson(),
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }
}

/// Automatically forwards pointer taps to [usabilityTrackerProvider] when running.
class UsabilityTapObserver extends ConsumerWidget {
  /// Creates a [UsabilityTapObserver] wrapping [child].
  const UsabilityTapObserver({
    super.key,
    required this.child,
  });

  /// Subtree whose pointer-down events count toward the active scenario.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning =
        ref.watch(usabilityTrackerProvider.select((s) => s.isRunning));
    if (!isRunning) return child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) =>
          ref.read(usabilityTrackerProvider.notifier).recordTap(),
      child: child,
    );
  }
}
