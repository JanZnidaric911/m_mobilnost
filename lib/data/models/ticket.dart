// Defines the Ticket and TicketStatus models with JSON serialization for Hive caching.

import 'package:flutter/foundation.dart';

/// Lifecycle state of a user's bus ticket relative to current time.
enum TicketStatus {
  /// Currently valid for boarding and inspection.
  active,

  /// Scheduled to become valid at a future [Ticket.validFrom] time.
  upcoming,

  /// Past its [Ticket.validUntil] expiration time.
  expired,
}

/// Represents a purchased digital bus ticket persisted locally for offline use.
@immutable
class Ticket {
  /// Creates a [Ticket] instance with explicit validity bounds and QR payload.
  const Ticket({
    required this.id,
    required this.ticketTypeId,
    required this.ticketCode,
    required this.titles,
    required this.priceEur,
    required this.zone,
    required this.purchasedAt,
    required this.validFrom,
    required this.validUntil,
    required this.qrPayload,
    required this.driverFallbackCode,
    required this.userId,
    this.validatedAt,
  });

  /// Creates a [Ticket] whose validity starts immediately by default unless [validFrom] is supplied.
  factory Ticket.issue({
    required String id,
    required String ticketTypeId,
    required String ticketCode,
    required Map<String, String> titles,
    required double priceEur,
    required String zone,
    required int durationMinutes,
    required String qrPayload,
    required String driverFallbackCode,
    required String userId,
    DateTime? purchasedAt,
    DateTime? validFrom,
  }) {
    final now = purchasedAt ?? DateTime.now();
    final start = validFrom ?? now;
    return Ticket(
      id: id,
      ticketTypeId: ticketTypeId,
      ticketCode: ticketCode,
      titles: titles,
      priceEur: priceEur,
      zone: zone,
      purchasedAt: now,
      validFrom: start,
      validUntil: start.add(Duration(minutes: durationMinutes)),
      qrPayload: qrPayload,
      driverFallbackCode: driverFallbackCode,
      userId: userId,
    );
  }

  /// Unique ticket identifier.
  final String id;

  /// Referenced [TicketType] ID.
  final String ticketTypeId;

  /// Short ticket type code.
  final String ticketCode;

  /// Localized ticket titles for offline display without network lookup.
  final Map<String, String> titles;

  /// Paid price in Euros.
  final double priceEur;

  /// Fare zone label.
  final String zone;

  /// Timestamp when the ticket was purchased.
  final DateTime purchasedAt;

  /// Start timestamp of ticket validity (defaults to immediate on issue).
  final DateTime validFrom;

  /// Expiration timestamp of ticket validity.
  final DateTime validUntil;

  /// Encoded payload rendered in the validator QR code.
  final String qrPayload;

  /// Short human-readable code the driver can inspect if QR scanning fails.
  final String driverFallbackCode;

  /// Identifier of the owning user (or guest account ID).
  final String userId;

  /// Optional timestamp of simulated NFC/QR boarding validation.
  final DateTime? validatedAt;

  /// Evaluates ticket lifecycle status at the current wall-clock time.
  TicketStatus get status => statusAt(DateTime.now());

  /// Evaluates ticket lifecycle status deterministically at [referenceTime].
  TicketStatus statusAt(DateTime referenceTime) {
    if (referenceTime.isBefore(validFrom)) {
      return TicketStatus.upcoming;
    }
    if (!referenceTime.isBefore(validUntil)) {
      return TicketStatus.expired;
    }
    return TicketStatus.active;
  }

  /// Returns a localized ticket title for [localeCode].
  String localizedTitle(String localeCode) {
    final normalized = localeCode == 'sr' ? 'sr_Latn' : localeCode;
    return titles[normalized] ??
        titles['sl'] ??
        titles['en'] ??
        (titles.values.isEmpty ? ticketCode : titles.values.first);
  }

  /// Returns a copy with [validatedAt] or other fields updated.
  Ticket copyWith({DateTime? validatedAt}) {
    return Ticket(
      id: id,
      ticketTypeId: ticketTypeId,
      ticketCode: ticketCode,
      titles: titles,
      priceEur: priceEur,
      zone: zone,
      purchasedAt: purchasedAt,
      validFrom: validFrom,
      validUntil: validUntil,
      qrPayload: qrPayload,
      driverFallbackCode: driverFallbackCode,
      userId: userId,
      validatedAt: validatedAt ?? this.validatedAt,
    );
  }

  /// Serializes this ticket into a JSON-compatible map for Hive persistence.
  Map<String, dynamic> toJson() => {
        'id': id,
        'ticketTypeId': ticketTypeId,
        'ticketCode': ticketCode,
        'titles': titles,
        'priceEur': priceEur,
        'zone': zone,
        'purchasedAt': purchasedAt.toIso8601String(),
        'validFrom': validFrom.toIso8601String(),
        'validUntil': validUntil.toIso8601String(),
        'qrPayload': qrPayload,
        'driverFallbackCode': driverFallbackCode,
        'userId': userId,
        'validatedAt': validatedAt?.toIso8601String(),
      };

  /// Restores a [Ticket] from Hive or JSON storage.
  factory Ticket.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    final rawTitles = json['titles'] as Map? ?? const {};
    return Ticket(
      id: json['id'] as String,
      ticketTypeId: json['ticketTypeId'] as String,
      ticketCode: json['ticketCode'] as String,
      titles: Map<String, String>.from(rawTitles),
      priceEur: (json['priceEur'] as num).toDouble(),
      zone: json['zone'] as String? ?? 'Maribor',
      purchasedAt: DateTime.parse(json['purchasedAt'] as String),
      validFrom: DateTime.parse(json['validFrom'] as String),
      validUntil: DateTime.parse(json['validUntil'] as String),
      qrPayload: json['qrPayload'] as String,
      driverFallbackCode: json['driverFallbackCode'] as String,
      userId: json['userId'] as String,
      validatedAt: json['validatedAt'] == null
          ? null
          : DateTime.parse(json['validatedAt'] as String),
    );
  }
}
