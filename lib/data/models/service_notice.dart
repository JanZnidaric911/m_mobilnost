// Defines ServiceNotice and NoticeSeverity models with 4-language localized helpers.

import 'package:flutter/foundation.dart';

/// Urgency level of a transit service notice or alert.
enum NoticeSeverity {
  /// Informational announcement or schedule reminder.
  info,

  /// Operational delay affecting one or more lines.
  delay,

  /// Major detour, stop closure, or trip cancellation.
  disruption,
}

/// Transit service alert covering affected lines, stops, and multilingual text.
@immutable
class ServiceNotice {
  /// Creates a [ServiceNotice] with localized titles, bodies, and alternative hints.
  const ServiceNotice({
    required this.id,
    required this.severity,
    required this.affectedLineIds,
    required this.affectedStopIds,
    required this.titles,
    required this.bodies,
    this.alternativeHint = const {},
    required this.publishedAt,
    required this.validUntil,
    this.isRead = false,
  });

  /// Unique notice identifier.
  final String id;

  /// Severity classification for filtering and visual priority.
  final NoticeSeverity severity;

  /// Line IDs impacted by this notice.
  final List<String> affectedLineIds;

  /// Stop IDs impacted by this notice.
  final List<String> affectedStopIds;

  /// Localized headlines keyed by `sl`, `en`, `de`, `sr_Latn`.
  final Map<String, String> titles;

  /// Localized notice details keyed by `sl`, `en`, `de`, `sr_Latn`.
  final Map<String, String> bodies;

  /// Optional localized rider guidance for alternative routes or stops.
  final Map<String, String> alternativeHint;

  /// Timestamp when the notice became active.
  final DateTime publishedAt;

  /// Expiration timestamp after which the notice is no longer active.
  final DateTime validUntil;

  /// Whether the user has marked this notice as read.
  final bool isRead;

  /// Returns true when the notice is active at [referenceTime].
  bool isActiveAt(DateTime referenceTime) =>
      !referenceTime.isBefore(publishedAt) &&
      referenceTime.isBefore(validUntil);

  /// Returns the localized notice headline for [localeCode].
  String localizedTitle(String localeCode) =>
      _pickLocalized(titles, localeCode) ?? '';

  /// Returns the localized notice body for [localeCode].
  String localizedBody(String localeCode) =>
      _pickLocalized(bodies, localeCode) ?? '';

  /// Returns the localized alternative travel hint for [localeCode], if any.
  String? localizedAlternativeHint(String localeCode) =>
      _pickLocalized(alternativeHint, localeCode);

  /// Returns a copy with [isRead] or other fields updated.
  ServiceNotice copyWith({bool? isRead}) {
    return ServiceNotice(
      id: id,
      severity: severity,
      affectedLineIds: affectedLineIds,
      affectedStopIds: affectedStopIds,
      titles: titles,
      bodies: bodies,
      alternativeHint: alternativeHint,
      publishedAt: publishedAt,
      validUntil: validUntil,
      isRead: isRead ?? this.isRead,
    );
  }

  static String? _pickLocalized(Map<String, String> map, String localeCode) {
    if (map.isEmpty) return null;
    final normalized = localeCode == 'sr' ? 'sr_Latn' : localeCode;
    return map[normalized] ?? map['sl'] ?? map['en'] ?? map.values.first;
  }
}
