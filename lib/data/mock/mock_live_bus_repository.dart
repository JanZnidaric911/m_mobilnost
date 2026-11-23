// Mock LiveBusRepository exposing BusSimulator streams and segment occupancy.

import '../models/bus_position.dart';
import '../models/occupancy.dart';
import '../repositories/live_bus_repository.dart';
import '../simulation/bus_simulator.dart';
import '../simulation/occupancy_model.dart';

/// Mock [LiveBusRepository] driven by [BusSimulator] and [OccupancyModel].
class MockLiveBusRepository implements LiveBusRepository {
  /// Creates a [MockLiveBusRepository] backed by [simulator] and [occupancyModel].
  MockLiveBusRepository({
    required BusSimulator simulator,
    OccupancyModel? occupancyModel,
    this._ownsSimulator = false,
  })  : _simulator = simulator,
        _occupancyModel =
            occupancyModel ?? OccupancyModel(seed: simulator.seed);

  final BusSimulator _simulator;
  final OccupancyModel _occupancyModel;
  final bool _ownsSimulator;

  @override
  Stream<List<BusPosition>> watchLiveBuses({String? lineId}) {
    if (lineId == null) return _simulator.positionsStream;
    return _simulator.positionsStream.map(
      (buses) => buses.where((b) => b.lineId == lineId).toList(growable: false),
    );
  }

  @override
  Future<List<BusPosition>> getCurrentBuses({
    String? lineId,
    DateTime? at,
  }) async {
    final snapshot = _simulator.snapshotAt(at ?? DateTime.now());
    if (lineId == null) return snapshot;
    return snapshot.where((b) => b.lineId == lineId).toList(growable: false);
  }

  @override
  Future<SegmentOccupancy> getSegmentOccupancy({
    required String lineId,
    required String directionId,
    required String fromStopId,
    required String toStopId,
    DateTime? at,
  }) async {
    if (!_simulator.useSimulatedLive) {
      return SegmentOccupancy(
        lineId: lineId,
        directionId: directionId,
        fromStopId: fromStopId,
        toStopId: toStopId,
        level: BusOccupancyLevel.unknown,
        loadPercent: 0,
      );
    }
    return _occupancyModel.estimateSegment(
      lineId: lineId,
      directionId: directionId,
      fromStopId: fromStopId,
      toStopId: toStopId,
      at: at ?? DateTime.now(),
    );
  }

  @override
  void dispose() {
    if (_ownsSimulator) {
      _simulator.dispose();
    }
  }
}
