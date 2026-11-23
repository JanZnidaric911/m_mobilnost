// Mock NoticeRepository merging seed and dynamic notices with persistent read state.

import 'dart:async';

import '../models/service_notice.dart';
import '../repositories/notice_repository.dart';
import '../simulation/notice_generator.dart';
import 'local_storage_helper.dart';

/// Mock [NoticeRepository] combining static seed notices and simulated alerts.
class MockNoticeRepository implements NoticeRepository {
  /// Creates a [MockNoticeRepository] backed by [generator] and Hive read state.
  MockNoticeRepository({
    NoticeGenerator? generator,
    bool Function()? isSimulatedLiveEnabled,
    String boxName = 'm_mobilnost_notices',
    DateTime Function()? clock,
  })  : _generator = generator ?? const NoticeGenerator(),
        _isSimulatedLiveEnabled = isSimulatedLiveEnabled ?? (() => true),
        _store = LocalKeyValueStore(boxName),
        _clock = clock ?? DateTime.now {
    _controller = StreamController<List<ServiceNotice>>.broadcast();
  }

  NoticeGenerator _generator;
  final bool Function() _isSimulatedLiveEnabled;
  final LocalKeyValueStore _store;
  final DateTime Function() _clock;
  late final StreamController<List<ServiceNotice>> _controller;

  /// Updates the underlying [NoticeGenerator] seed dynamically.
  void updateSeed(int seed) {
    _generator = NoticeGenerator(seed: seed);
    _emit();
  }

  Future<Set<String>> _loadReadIds() async {
    final raw = await _store.read('read_notice_ids');
    if (raw is List) {
      return raw.map((e) => e.toString()).toSet();
    }
    return <String>{};
  }

  @override
  Future<List<ServiceNotice>> getNotices({
    bool? useSimulatedLive,
    DateTime? at,
  }) async {
    final readIds = await _loadReadIds();
    return _generator.generateNotices(
      at: at ?? _clock(),
      useSimulatedLive: useSimulatedLive ?? _isSimulatedLiveEnabled(),
      readNoticeIds: readIds,
    );
  }

  @override
  Stream<List<ServiceNotice>> watchNotices({bool? useSimulatedLive}) async* {
    yield await getNotices(useSimulatedLive: useSimulatedLive);
    await for (final list in _controller.stream) {
      if (useSimulatedLive == null ||
          useSimulatedLive == _isSimulatedLiveEnabled()) {
        yield list;
      } else {
        yield await getNotices(useSimulatedLive: useSimulatedLive);
      }
    }
  }

  @override
  Future<void> markAsRead(String noticeId) async {
    final readIds = await _loadReadIds();
    readIds.add(noticeId);
    await _store.write('read_notice_ids', readIds.toList(growable: false));
    await _emit();
  }

  @override
  Future<void> markAllAsRead() async {
    final current = await getNotices();
    final readIds = await _loadReadIds();
    for (final notice in current) {
      readIds.add(notice.id);
    }
    await _store.write('read_notice_ids', readIds.toList(growable: false));
    await _emit();
  }

  /// Clears stored notice read markers.
  Future<void> clearReadState() async {
    await _store.clear();
    await _emit();
  }

  Future<void> _emit() async {
    if (_controller.isClosed) return;
    final notices = await getNotices();
    if (!_controller.isClosed) {
      _controller.add(notices);
    }
  }

  @override
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
