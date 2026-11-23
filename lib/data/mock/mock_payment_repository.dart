// Mock PaymentRepository storing 5 payment methods and only brand + last 4 card digits.

import '../models/payment_method.dart';
import '../repositories/payment_repository.dart';
import 'local_storage_helper.dart';

/// Mock [PaymentRepository] simulating checkout and tokenized card storage.
class MockPaymentRepository implements PaymentRepository {
  /// Creates a [MockPaymentRepository] backed by Hive box [boxName].
  MockPaymentRepository({
    String boxName = 'm_mobilnost_payments',
  }) : _store = LocalKeyValueStore(boxName);

  final LocalKeyValueStore _store;

  static List<PaymentMethod> _defaultMethods() => [
        PaymentMethod(
          id: 'pm_card_4242',
          type: PaymentMethodType.card,
          brand: 'Visa',
          last4Digits: '4242',
          label: 'Visa •••• 4242',
          isDefault: true,
          fakeToken: 'tok_sim_visa_4242',
        ),
        PaymentMethod(
          id: 'pm_google_pay',
          type: PaymentMethodType.googlePay,
          brand: 'Google Pay',
          label: 'Google Pay',
          fakeToken: 'tok_sim_google_pay',
        ),
        PaymentMethod(
          id: 'pm_apple_pay',
          type: PaymentMethodType.applePay,
          brand: 'Apple Pay',
          label: 'Apple Pay',
          fakeToken: 'tok_sim_apple_pay',
        ),
        PaymentMethod(
          id: 'pm_bank_sepa',
          type: PaymentMethodType.bankTransfer,
          brand: 'NLB Klik / SEPA',
          label: 'NLB Klik / e-Banking',
          fakeToken: 'tok_sim_bank_sepa',
        ),
        PaymentMethod(
          id: 'pm_mobile_valu',
          type: PaymentMethodType.mobilePay,
          brand: 'Valú / mBills',
          label: 'Valú / mBills',
          fakeToken: 'tok_sim_mobile_valu',
        ),
      ];

  Future<List<PaymentMethod>> _loadOrSeed(String userId) async {
    final seededFlag = await _store.read('seeded_$userId');
    final rawList = await _store.read('methods_$userId');
    if (seededFlag != true && rawList == null) {
      final defaults = _defaultMethods();
      await _save(userId, defaults);
      await _store.write('seeded_$userId', true);
      return defaults;
    }
    if (rawList is List) {
      return rawList
          .whereType<Map>()
          .map(PaymentMethod.fromJson)
          .toList(growable: true);
    }
    return <PaymentMethod>[];
  }

  Future<void> _save(String userId, List<PaymentMethod> methods) async {
    await _store.write(
      'methods_$userId',
      methods.map((m) => m.toJson()).toList(growable: false),
    );
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods(String userId) async =>
      List<PaymentMethod>.unmodifiable(await _loadOrSeed(userId));

  @override
  Future<PaymentMethod> addCardMethod({
    required String userId,
    required String brand,
    required String cardNumber,
    String? label,
  }) async {
    // Extract ONLY the last 4 digits; full PAN and CVV are never retained.
    final digitsOnly = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 4) {
      throw ArgumentError('Card number must include at least 4 digits.');
    }
    final last4 = digitsOnly.substring(digitsOnly.length - 4);
    final cleanBrand = brand.trim().isEmpty ? 'Card' : brand.trim();

    final methods = await _loadOrSeed(userId);
    final updated = [
      for (final m in methods) m.copyWith(isDefault: false),
      PaymentMethod(
        id: 'pm_card_${DateTime.now().microsecondsSinceEpoch}',
        type: PaymentMethodType.card,
        brand: cleanBrand,
        last4Digits: last4,
        label: label?.trim().isNotEmpty == true
            ? label!.trim()
            : '$cleanBrand •••• $last4',
        isDefault: true,
        fakeToken: 'tok_sim_${cleanBrand.toLowerCase()}_$last4',
      ),
    ];
    await _save(userId, updated);
    return updated.last;
  }

  @override
  Future<void> setDefaultPaymentMethod(String userId, String methodId) async {
    final methods = await _loadOrSeed(userId);
    final updated = [
      for (final m in methods) m.copyWith(isDefault: m.id == methodId),
    ];
    await _save(userId, updated);
  }

  @override
  Future<void> removePaymentMethod(String userId, String methodId) async {
    final methods = await _loadOrSeed(userId);
    methods.removeWhere((m) => m.id == methodId);
    if (methods.isNotEmpty && !methods.any((m) => m.isDefault)) {
      methods[0] = methods[0].copyWith(isDefault: true);
    }
    await _save(userId, methods);
  }

  @override
  Future<bool> simulateCharge({
    required String userId,
    required String methodId,
    required double amountEur,
  }) async {
    if (amountEur <= 0) return false;
    final methods = await _loadOrSeed(userId);
    return methods.any((m) => m.id == methodId);
  }

  @override
  Future<void> clearForUser(String userId) async {
    await _store.delete('methods_$userId');
    await _store.delete('seeded_$userId');
  }

  @override
  Future<void> clearAll() => _store.clear();
}
