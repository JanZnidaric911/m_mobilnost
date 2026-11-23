// Simulated payment methods screen storing only card brand and last 4 digits.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/accessibility/a11y_settings.dart';
import '../../../core/accessibility/haptic_cues.dart';
import '../../../core/accessibility/semantics_helpers.dart';
import '../../../core/layout/responsive_builder.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/payment_method.dart';
import '../../../data/repositories/repository_providers.dart';
import '../providers/account_providers.dart';
import 'account_screen.dart';
import 'widgets/payment_method_helpers.dart';

/// Displays and manages simulated payment channels and tokenized demo cards.
class PaymentMethodsScreen extends ConsumerStatefulWidget {
  /// Creates a [PaymentMethodsScreen].
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  final _addCardFormKey = GlobalKey<FormState>();
  final _brandController = TextEditingController(text: 'Visa');
  final _last4Controller = TextEditingController();

  bool _showAddForm = false;
  bool _saving = false;

  @override
  void dispose() {
    _brandController.dispose();
    _last4Controller.dispose();
    super.dispose();
  }

  Future<void> _addDemoCard(String userId) async {
    if (!(_addCardFormKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(paymentRepositoryProvider).addCardMethod(
            userId: userId,
            brand: _brandController.text.trim(),
            cardNumber: _last4Controller.text.trim(),
          );
      final settings = ref.read(a11ySettingsProvider);
      unawaited(
        HapticCues.trigger(
          HapticCueType.tap,
          enabled: settings.hapticAlertsEnabled,
        ),
      );
      ref.invalidate(userPaymentMethodsProvider);
      if (mounted) {
        _last4Controller.clear();
        setState(() => _showAddForm = false);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setDefault(String userId, String methodId) async {
    await ref
        .read(paymentRepositoryProvider)
        .setDefaultPaymentMethod(userId, methodId);
    ref.invalidate(userPaymentMethodsProvider);
  }

  Future<void> _removeMethod(String userId, String methodId) async {
    await ref
        .read(paymentRepositoryProvider)
        .removePaymentMethod(userId, methodId);
    ref.invalidate(userPaymentMethodsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(activeUserProvider);
    final methodsAsync = ref.watch(userPaymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paymentsTitle),
      ),
      body: user == null
          ? ListView(
              children: [
                ResponsiveContentContainer(
                  child: Column(
                    children: [
                      DemoPaymentBanner(subtitle: l10n.paymentsSimulatedNotice),
                      const SizedBox(height: 16),
                      GuestAuthPromptCard(
                        onSignInPressed: () => navigateWithFallback(
                          context,
                          '/account',
                          fallbackBuilder: (_) => const AccountScreen(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView(
              children: [
                ResponsiveContentContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DemoPaymentBanner(subtitle: l10n.paymentsSimulatedNotice),
                      const SizedBox(height: 16),
                      BigButton(
                        icon: _showAddForm
                            ? Icons.close_rounded
                            : Icons.add_card_rounded,
                        label: _showAddForm
                            ? l10n.commonCancel
                            : l10n.paymentsAddMethod,
                        variant: _showAddForm
                            ? BigButtonVariant.outlined
                            : BigButtonVariant.primary,
                        expanded: true,
                        onPressed: () {
                          setState(() => _showAddForm = !_showAddForm);
                        },
                      ),
                      if (_showAddForm) ...[
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _addCardFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    l10n.paymentsCard,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _brandController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: InputDecoration(
                                      labelText: l10n.paymentsCardBrandLabel,
                                      prefixIcon:
                                          const Icon(Icons.credit_card_rounded),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return l10n.commonErrorBody;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  // Strictly accepts and stores ONLY the last 4 digits; never full PAN or CVV.
                                  TextFormField(
                                    controller: _last4Controller,
                                    maxLength: 4,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                    ],
                                    decoration: InputDecoration(
                                      labelText: l10n.paymentsLast4Label,
                                      hintText: '1234',
                                      prefixIcon:
                                          const Icon(Icons.pin_outlined),
                                    ),
                                    validator: (value) {
                                      if (!isValidCardLast4(value ?? '')) {
                                        return l10n.paymentsLast4Validation;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  BigButton(
                                    icon: Icons.save_outlined,
                                    label: l10n.commonSave,
                                    expanded: true,
                                    loading: _saving,
                                    onPressed: () => _addDemoCard(user.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      methodsAsync.when(
                        loading: () => const LoadingStateView(),
                        error: (_, _) => ErrorStateView(
                          onRetry: () =>
                              ref.invalidate(userPaymentMethodsProvider),
                        ),
                        data: (methods) {
                          if (methods.isEmpty) {
                            return EmptyStateView(
                              icon: Icons.credit_card_off_outlined,
                              title: l10n.commonEmpty,
                            );
                          }
                          return Column(
                            children: [
                              for (final method in methods) ...[
                                _PaymentMethodTile(
                                  method: method,
                                  onSetDefault: method.isDefault
                                      ? null
                                      : () => _setDefault(user.id, method.id),
                                  onRemove: () =>
                                      _removeMethod(user.id, method.id),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.onSetDefault,
    required this.onRemove,
  });

  final PaymentMethod method;
  final VoidCallback? onSetDefault;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final channelLabel = localizedPaymentTypeLabel(l10n, method.type);
    final displayTitle = method.type == PaymentMethodType.card
        ? '${method.brand} •••• ${method.last4Digits ?? ''}'.trim()
        : (method.label.isNotEmpty ? method.label : channelLabel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  iconForPaymentType(method.type),
                  size: 28,
                  color: scheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        channelLabel,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (method.isDefault)
                  StatusChip(
                    type: TransitStatusType.onTime,
                    label: l10n.paymentsDefaultBadge,
                    compact: true,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (onSetDefault != null)
                  BigButton(
                    icon: Icons.check_circle_outline_rounded,
                    label: l10n.paymentsSetDefault,
                    variant: BigButtonVariant.secondary,
                    onPressed: onSetDefault,
                  ),
                BigButton(
                  icon: Icons.delete_outline_rounded,
                  label: l10n.commonRemove,
                  variant: BigButtonVariant.outlined,
                  onPressed: onRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
