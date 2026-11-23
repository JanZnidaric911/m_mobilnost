// Configures MaterialApp.router with localization, theming, and 200% text scaling.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessibility/a11y_settings.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/high_contrast_theme.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';

/// Root MaterialApp widget wired to Riverpod accessibility settings and GoRouter.
class MMobilnostApp extends ConsumerWidget {
  /// Creates the root [MMobilnostApp] widget.
  const MMobilnostApp({super.key});

  /// Explicitly declared supported locales matching ARB translations.
  static const List<Locale> appSupportedLocales = <Locale>[
    Locale('sl'),
    Locale('en'),
    Locale('de'),
    Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
    Locale('sr'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(a11ySettingsProvider);
    final router = ref.watch(routerProvider);

    final lightTheme = settings.isHighContrast
        ? HighContrastTheme.build(reducedMotion: settings.reducedMotion)
        : AppTheme.light(reducedMotion: settings.reducedMotion);
    final darkTheme = settings.isHighContrast
        ? HighContrastTheme.build(reducedMotion: settings.reducedMotion)
        : AppTheme.dark(reducedMotion: settings.reducedMotion);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (ctx) =>
          AppLocalizations.of(ctx)?.appTitle ?? 'M Mobilnost',
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appSupportedLocales,
      locale: settings.toLocale(),
      themeMode: settings.materialThemeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final baseScale = media.textScaler.scale(1.0);
        final effectiveScale = settings.extraLargeText
            ? 2.0
            : baseScale.clamp(1.0, 2.0);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(effectiveScale),
            disableAnimations: settings.reducedMotion,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
