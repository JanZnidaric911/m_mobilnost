// Standardized accessible loading, empty, and retryable error state views.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accessibility/a11y_settings.dart';
import '../accessibility/semantics_helpers.dart';
import 'big_button.dart';

/// Centered accessible loading indicator with localized message.
class LoadingStateView extends ConsumerWidget {
  /// Creates a [LoadingStateView] with optional custom [message].
  const LoadingStateView({super.key, this.message});

  /// Optional localized loading text override.
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reducedMotion = ref.watch(a11ySettingsProvider).reducedMotion;
    final text = message ?? l10n.commonLoading;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          liveRegion: true,
          label: text,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (reducedMotion)
                Icon(
                  Icons.hourglass_top_rounded,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                )
              else
                const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Accessible empty-state placeholder with optional primary action.
class EmptyStateView extends StatelessWidget {
  /// Creates an [EmptyStateView] displaying [icon], [title], and optional action.
  const EmptyStateView({
    super.key,
    this.icon = Icons.directions_bus_outlined,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  /// Decorative leading icon.
  final IconData icon;

  /// Localized primary headline; defaults to [AppLocalizations.commonEmpty].
  final String? title;

  /// Optional localized explanation text.
  final String? subtitle;

  /// Optional CTA button text.
  final String? actionLabel;

  /// Optional CTA callback.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title ?? l10n.commonEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              BigButton(
                icon: Icons.refresh_rounded,
                label: actionLabel!,
                onPressed: onAction,
                variant: BigButtonVariant.outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Accessible error state view with a clear retry [BigButton].
class ErrorStateView extends StatelessWidget {
  /// Creates an [ErrorStateView] with localized error text and [onRetry].
  const ErrorStateView({
    super.key,
    this.title,
    this.message,
    this.onRetry,
  });

  /// Optional localized title override.
  final String? title;

  /// Optional localized body override.
  final String? message;

  /// Callback invoked when the user taps Retry.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: scheme.error),
              const SizedBox(height: 16),
              Text(
                title ?? l10n.commonErrorTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                message ?? l10n.commonErrorBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                BigButton(
                  icon: Icons.refresh_rounded,
                  label: l10n.commonRetry,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
