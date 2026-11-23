// Five-step visual, TTS-enabled beginner bus guide for Marprom riders.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/accessibility/a11y_settings.dart';
import '../../../core/accessibility/read_aloud.dart';
import '../../../core/accessibility/semantics_helpers.dart';
import '../../../core/layout/responsive_builder.dart';
import '../../../core/widgets/big_button.dart';

/// Accessible 5-card tutorial explaining how to ride Marprom city buses.
class NewRiderGuideScreen extends ConsumerStatefulWidget {
  /// Creates the [NewRiderGuideScreen] walkthrough.
  const NewRiderGuideScreen({super.key});

  @override
  ConsumerState<NewRiderGuideScreen> createState() =>
      _NewRiderGuideScreenState();
}

class _NewRiderGuideScreenState extends ConsumerState<NewRiderGuideScreen> {
  int _stepIndex = 0;

  void _goToStep(int index) {
    final clamped = index.clamp(0, 4);
    if (clamped == _stepIndex) return;
    setState(() => _stepIndex = clamped);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(a11ySettingsProvider);
    final scheme = Theme.of(context).colorScheme;

    final steps = <(IconData, String, String)>[
      (Icons.pin_drop_rounded, l10n.guideCard1Title, l10n.guideCard1Body),
      (Icons.qr_code_2_rounded, l10n.guideCard2Title, l10n.guideCard2Body),
      (
        Icons.directions_bus_filled_rounded,
        l10n.guideCard3Title,
        l10n.guideCard3Body,
      ),
      (Icons.gps_fixed_rounded, l10n.guideCard4Title, l10n.guideCard4Body),
      (
        Icons.transfer_within_a_station_rounded,
        l10n.guideCard5Title,
        l10n.guideCard5Body,
      ),
    ];

    final (icon, title, body) = steps[_stepIndex];
    final progressText = l10n.guideCardProgress(_stepIndex + 1, steps.length);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.guideTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ResponsiveContentContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.guideSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    progressText,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_stepIndex + 1) / steps.length,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity < -250) {
                      _goToStep(_stepIndex + 1);
                    } else if (velocity > 250) {
                      _goToStep(_stepIndex - 1);
                    }
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              icon,
                              size: 40,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            body,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 20),
                          BigButton(
                            icon: Icons.volume_up_rounded,
                            label: l10n.a11yReadAloudButton,
                            variant: BigButtonVariant.outlined,
                            expanded: true,
                            onPressed: () {
                              final text = '$title. $body';
                              ref.read(readAloudProvider).speak(
                                    text,
                                    enabled: true,
                                    localeCode: settings.localeCode,
                                  );
                              announceForAccessibility(context, text);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < steps.length; i++)
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: i == _stepIndex
                            ? FilledButton(
                                onPressed: () => _goToStep(i),
                                child: Text('${i + 1}'),
                              )
                            : OutlinedButton(
                                onPressed: () => _goToStep(i),
                                child: Text('${i + 1}'),
                              ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final stackButtons =
                        constraints.maxWidth < 420 || textScale >= 1.5;

                    final prevBtn = BigButton(
                      icon: Icons.arrow_back_rounded,
                      label: l10n.commonPrevious,
                      variant: BigButtonVariant.outlined,
                      expanded: true,
                      onPressed: _stepIndex > 0
                          ? () => _goToStep(_stepIndex - 1)
                          : null,
                    );

                    final nextBtn = _stepIndex < steps.length - 1
                        ? BigButton(
                            icon: Icons.arrow_forward_rounded,
                            label: l10n.commonNext,
                            expanded: true,
                            onPressed: () => _goToStep(_stepIndex + 1),
                          )
                        : BigButton(
                            icon: Icons.check_circle_outline_rounded,
                            label: l10n.guideFinishCta,
                            expanded: true,
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/');
                              }
                            },
                          );

                    if (stackButtons) {
                      return Column(
                        children: [
                          nextBtn,
                          const SizedBox(height: 10),
                          prevBtn,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: prevBtn),
                        const SizedBox(width: 12),
                        Expanded(child: nextBtn),
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
