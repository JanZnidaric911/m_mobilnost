// Abstract repository contract for tokenized payment methods and simulated charges.

import '../models/payment_method.dart';

// TODO(firebase): Replace mock implementation with Stripe / PSP tokenized vault calls.
/// Manages non-sensitive payment method tokens without storing raw card numbers or CVVs.
abstract class PaymentRepository {
  /// Lists saved payment methods for [userId].
  Future<List<PaymentMethod>> getPaymentMethods(String userId);

  /// Tokenizes and stores ONLY card brand and last 4 digits (never full PAN or CVV).
  Future<PaymentMethod> addCardMethod({
    required String userId,
    required String brand,
    required String cardNumber,
    String? label,
  });

  /// Marks [methodId] as the default checkout payment option for [userId].
  Future<void> setDefaultPaymentMethod(String userId, String methodId);

  /// Deletes [methodId] from [userId]'s saved payment methods.
  Future<void> removePaymentMethod(String userId, String methodId);

  /// Simulates charging [amountEur] via [methodId], returning true on approval.
  Future<bool> simulateCharge({
    required String userId,
    required String methodId,
    required double amountEur,
  });

  /// Clears locally cached payment methods for [userId].
  Future<void> clearForUser(String userId);

  /// Clears all locally cached payment methods across all users.
  Future<void> clearAll();
}
