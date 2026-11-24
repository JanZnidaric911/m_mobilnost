// Marprom Fares & Digital Ticket Portal page wrapping interactive ticket shop & wallet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accessibility/a11y_settings.dart';
import '../../../../core/theme/colors.dart';
import '../../../../data/seed/seed_tickets.dart';

/// Marprom Web Tickets & Fares Page (`/tickets`) presenting official fare tiers,
/// 75-minute free transfer info, and direct access to digital ticket checkout & wallet.
class WebTicketsPage extends ConsumerWidget {
  /// Creates the [WebTicketsPage].
  const WebTicketsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(a11ySettingsProvider).localeCode;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vozovnice in cenik mestnega prometa Marprom',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enotna vozovnica z brezplačnim prestopanjem v 75 minutah na vseh 19 linijah (G1–G6 & P7–P19).',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: MarpromColors.marpromRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    onPressed: () => context.go('/tickets/shop'),
                    icon: const Icon(Icons.shopping_bag_rounded),
                    label: const Text(
                      'Odpri spletno trgovino vozovnic',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 960
                      ? 3
                      : (constraints.maxWidth >= 600 ? 2 : 1);
                  final cardWidth =
                      (constraints.maxWidth - (16 * (cols - 1))) / cols;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final ticket in seedTicketTypes)
                        SizedBox(
                          width: cardWidth,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ticket.localizedTitle(localeCode),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: MarpromColors.marpromRed
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${ticket.priceEur.toStringAsFixed(2)} €',
                                          style: const TextStyle(
                                            color: MarpromColors.marpromRed,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    ticket.localizedDescription(localeCode),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          height: 1.45,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => context.go(
                                        '/tickets/checkout/${Uri.encodeComponent(ticket.id)}',
                                      ),
                                      icon: const Icon(
                                        Icons.qr_code_2_rounded,
                                      ),
                                      label: const Text('Kupi digitalno'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
