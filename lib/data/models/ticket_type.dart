// Defines the TicketType catalog model with 4-language localized metadata and EUR pricing.

import 'package:flutter/foundation.dart';

/// Represents a purchasable Marprom bus ticket product.
@immutable
class TicketType {
  /// Creates a [TicketType] with localized names, duration, price, and rules.
  const TicketType({
    required this.id,
    required this.code,
    required this.titles,
    required this.descriptions,
    required this.durationMinutes,
    required this.priceEur,
    this.isYouthOnly = false,
    this.isSeniorOnly = false,
    this.zone = 'Maribor',
  });

  /// Unique product identifier.
  final String id;

  /// Short product code used in QR payloads and URLs.
  final String code;

  /// Localized product titles keyed by `sl`, `en`, `de`, `sr_Latn`.
  final Map<String, String> titles;

  /// Localized product descriptions keyed by `sl`, `en`, `de`, `sr_Latn`.
  final Map<String, String> descriptions;

  /// Validity duration in minutes from activation.
  final int durationMinutes;

  /// Ticket price in Euros (EUR).
  final double priceEur;

  /// Whether the ticket is restricted to eligible youth/student riders.
  final bool isYouthOnly;

  /// Whether the ticket is restricted to senior riders (65+).
  final bool isSeniorOnly;

  /// Geographic fare zone (e.g. `Maribor`).
  final String zone;

  /// Returns the localized title for [localeCode] with `sl`/`en` fallbacks.
  String localizedTitle(String localeCode) => _pickLocalized(titles, localeCode);

  /// Returns the localized description for [localeCode] with `sl`/`en` fallbacks.
  String localizedDescription(String localeCode) =>
      _pickLocalized(descriptions, localeCode);

  static String _pickLocalized(Map<String, String> map, String localeCode) {
    final normalized = localeCode == 'sr' ? 'sr_Latn' : localeCode;
    return map[normalized] ??
        map['sl'] ??
        map['en'] ??
        (map.values.isEmpty ? '' : map.values.first);
  }
}
