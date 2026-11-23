// Abstract repository contract for service disruptions, delays, and read state.

import '../models/service_notice.dart';

// TODO(firebase): Replace mock implementation with Firestore real-time service notices.
/// Provides active transit service notices and persistent read/unread tracking.
abstract class NoticeRepository {
  /// Returns active service notices at [at] (defaults to current time).
  Future<List<ServiceNotice>> getNotices({
    bool? useSimulatedLive,
    DateTime? at,
  });

  /// Streams active service notices whenever read status or live alerts change.
  Stream<List<ServiceNotice>> watchNotices({bool? useSimulatedLive});

  /// Marks a single notice as read.
  Future<void> markAsRead(String noticeId);

  /// Marks all currently active notices as read.
  Future<void> markAllAsRead();

  /// Releases stream controllers.
  void dispose();
}
