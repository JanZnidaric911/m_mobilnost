// Builds WCAG AA light and dark Material 3 themes for M Mobilnost 2.0.

import 'package:flutter/material.dart';

import 'colors.dart';
import 'text_styles.dart';

/// Provides WCAG AA compliant light and dark [ThemeData] configurations.
abstract final class AppTheme {
  /// Builds the standard Marprom light theme.
  static ThemeData light({bool reducedMotion = false}) {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: MarpromColors.transitBlue,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFFFE0E4),
      onPrimaryContainer: MarpromColors.transitBlueDark,
      secondary: MarpromColors.mobilityGreen,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFD3F0E4),
      onSecondaryContainer: const Color(0xFF043827),
      tertiary: const Color(0xFF0369A1),
      onTertiary: Colors.white,
      error: const Color(0xFF991B1B),
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: const Color(0xFF7F1D1D),
      surface: MarpromColors.lightSurface,
      onSurface: MarpromColors.lightOnSurface,
      surfaceContainerHighest: const Color(0xFFE7EEF5),
      onSurfaceVariant: MarpromColors.lightOnSurfaceVariant,
      outline: const Color(0xFF94A3B8),
      outlineVariant: const Color(0xFFE2E8F0),
    );

    return _buildBaseTheme(
      scheme: scheme,
      scaffoldBg: MarpromColors.lightBackground,
      statusColors: MarpromStatusColors.light,
      reducedMotion: reducedMotion,
    );
  }

  /// Builds the standard Marprom dark theme.
  static ThemeData dark({bool reducedMotion = false}) {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: MarpromColors.transitBlueLight,
      onPrimary: const Color(0xFF00284D),
      primaryContainer: const Color(0xFF0E3960),
      onPrimaryContainer: const Color(0xFFD6E7F7),
      secondary: MarpromColors.mobilityGreenLight,
      onSecondary: const Color(0xFF033322),
      secondaryContainer: const Color(0xFF0A4733),
      onSecondaryContainer: const Color(0xFFD3F0E4),
      tertiary: const Color(0xFF7DD3FC),
      onTertiary: const Color(0xFF082F49),
      error: const Color(0xFFFCA5A5),
      onError: const Color(0xFF450A0A),
      errorContainer: const Color(0xFF7F1D1D),
      onErrorContainer: const Color(0xFFFEE2E2),
      surface: MarpromColors.darkSurface,
      onSurface: MarpromColors.darkOnSurface,
      surfaceContainerHighest: const Color(0xFF233042),
      onSurfaceVariant: MarpromColors.darkOnSurfaceVariant,
      outline: const Color(0xFF64748B),
      outlineVariant: const Color(0xFF2A394D),
    );

    return _buildBaseTheme(
      scheme: scheme,
      scaffoldBg: MarpromColors.darkBackground,
      statusColors: MarpromStatusColors.dark,
      reducedMotion: reducedMotion,
    );
  }

  static ThemeData _buildBaseTheme({
    required ColorScheme scheme,
    required Color scaffoldBg,
    required MarpromStatusColors statusColors,
    required bool reducedMotion,
  }) {
    final textTheme = MarpromTextStyles.buildTextTheme(
      scheme.onSurface,
      scheme.onSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      extensions: [statusColors],
      pageTransitionsTheme: reducedMotion
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _NoMotionPageTransitionsBuilder(),
                TargetPlatform.iOS: _NoMotionPageTransitionsBuilder(),
                TargetPlatform.windows: _NoMotionPageTransitionsBuilder(),
                TargetPlatform.macOS: _NoMotionPageTransitionsBuilder(),
                TargetPlatform.linux: _NoMotionPageTransitionsBuilder(),
              },
            )
          : const PageTransitionsTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(56, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(56, 52),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2.5),
        ),
      ),
    );
  }
}

class _NoMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoMotionPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
