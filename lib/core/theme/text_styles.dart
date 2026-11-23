// Defines the 5-step accessible typographic scale for M Mobilnost 2.0.

import 'package:flutter/material.dart';

/// Builds a readable 5-step typographic scale (display, headline, title, body, label).
abstract final class MarpromTextStyles {
  /// Returns a [TextTheme] tuned for transit legibility in the given [foreground].
  static TextTheme buildTextTheme(Color foreground, Color secondary) {
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 30,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: foreground,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        height: 1.28,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: foreground,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
    );
  }
}
