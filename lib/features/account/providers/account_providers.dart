// Riverpod providers and pure validation helpers for account, minor rules, and payments.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/payment_method.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/repository_providers.dart';

/// Synchronously resolves the active [UserProfile] (or null in guest mode)
/// while staying reactive to [currentUserProvider] stream updates.
final activeUserProvider = Provider<UserProfile?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user,
    loading: () => authRepo.currentUser,
    error: (_, _) => authRepo.currentUser,
  );
});

/// Validates that [input] contains strictly 4 numeric digits and nothing more.
bool isValidCardLast4(String input) {
  return RegExp(r'^\d{4}$').hasMatch(input.trim());
}

/// Computes completed years of age for [dateOfBirth] on [referenceDate].
int? calculateAgeYears(DateTime? dateOfBirth, {DateTime? referenceDate}) {
  if (dateOfBirth == null) return null;
  final now = referenceDate ?? DateTime.now();
  var age = now.year - dateOfBirth.year;
  final hadBirthdayThisYear = now.month > dateOfBirth.month ||
      (now.month == dateOfBirth.month && now.day >= dateOfBirth.day);
  if (!hadBirthdayThisYear) {
    age -= 1;
  }
  return age < 0 ? 0 : age;
}

/// Returns true when [dateOfBirth] requires guardian confirmation for signup (<16)
/// or ticket purchase (<18).
bool requiresGuardianConsent(
  DateTime? dateOfBirth, {
  required bool forPurchase,
  DateTime? referenceDate,
}) {
  final age = calculateAgeYears(dateOfBirth, referenceDate: referenceDate);
  if (age == null) return false;
  return forPurchase ? age < 18 : age < 16;
}

/// Loads saved mock payment methods for the currently signed-in user.
final userPaymentMethodsProvider =
    FutureProvider<List<PaymentMethod>>((ref) async {
  final user = ref.watch(activeUserProvider);
  if (user == null) {
    return const <PaymentMethod>[];
  }
  return ref.watch(paymentRepositoryProvider).getPaymentMethods(user.id);
});
