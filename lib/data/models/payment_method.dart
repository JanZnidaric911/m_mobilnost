// Defines simulated PaymentMethod models storing only tokenized display metadata.

import 'package:flutter/foundation.dart';

/// Supported simulated payment channels for M Mobilnost ticket checkout.
enum PaymentMethodType {
  /// Credit or debit card (tokenized; only brand and last 4 digits stored).
  card,

  /// Google Pay wallet.
  googlePay,

  /// Apple Pay wallet.
  applePay,

  /// Online e-banking / SEPA bank transfer.
  bankTransfer,

  /// Slovenian mobile wallet (for example Valu / mBills).
  mobilePay,
}

/// Tokenized payment method summary; never stores full card numbers or CVV codes.
@immutable
class PaymentMethod {
  /// Creates a [PaymentMethod] with non-sensitive display metadata and fake token.
  const PaymentMethod({
    required this.id,
    required this.type,
    required this.brand,
    this.last4Digits,
    required this.label,
    this.isDefault = false,
    required this.fakeToken,
  }) : assert(
          last4Digits == null || last4Digits.length <= 4,
          'Only the last 4 digits may be stored; never store full card numbers.',
        );

  /// Unique payment method identifier.
  final String id;

  /// Payment method channel category.
  final PaymentMethodType type;

  /// Display brand (for example `Visa`, `Google Pay`, `NLB Klik / SEPA`).
  final String brand;

  /// Optional last 4 card digits; full PAN and CVV are strictly never persisted.
  final String? last4Digits;

  /// User-facing label shown in payment lists and checkout.
  final String label;

  /// Whether this method is selected by default at checkout.
  final bool isDefault;

  /// Opaque simulated payment processor token.
  final String fakeToken;

  /// Returns a copy with selected fields replaced.
  PaymentMethod copyWith({
    String? id,
    PaymentMethodType? type,
    String? brand,
    String? last4Digits,
    String? label,
    bool? isDefault,
    String? fakeToken,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      last4Digits: last4Digits ?? this.last4Digits,
      label: label ?? this.label,
      isDefault: isDefault ?? this.isDefault,
      fakeToken: fakeToken ?? this.fakeToken,
    );
  }

  /// Serializes tokenized metadata for local persistence without sensitive secrets.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'brand': brand,
        'last4Digits': last4Digits,
        'label': label,
        'isDefault': isDefault,
        'fakeToken': fakeToken,
      };

  /// Restores a [PaymentMethod] from stored JSON data.
  factory PaymentMethod.fromJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    final typeName = json['type'] as String? ?? 'card';
    final rawLast4 = json['last4Digits'] as String?;
    // Defensive trim guarantees no oversized digits ever enter memory from cache.
    final safeLast4 = rawLast4 == null
        ? null
        : (rawLast4.length <= 4
            ? rawLast4
            : rawLast4.substring(rawLast4.length - 4));
    return PaymentMethod(
      id: json['id'] as String,
      type: PaymentMethodType.values.firstWhere(
        (v) => v.name == typeName,
        orElse: () => PaymentMethodType.card,
      ),
      brand: json['brand'] as String,
      last4Digits: safeLast4,
      label: json['label'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      fakeToken: json['fakeToken'] as String,
    );
  }
}
