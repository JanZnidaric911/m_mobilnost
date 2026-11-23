// Provides responsive builder and centered max-width container widgets.

import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Builds adaptive UI based on the available width breakpoint.
class ResponsiveBuilder extends StatelessWidget {
  /// Creates a [ResponsiveBuilder] passing [ScreenLayoutSize] to [builder].
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  /// Called whenever constraints change with the resolved [ScreenLayoutSize].
  final Widget Function(
    BuildContext context,
    ScreenLayoutSize layoutSize,
    BoxConstraints constraints,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = LayoutBreakpoints.fromWidth(constraints.maxWidth);
        return builder(context, size, constraints);
      },
    );
  }
}

/// Constrains content to a comfortable reading width with adaptive padding.
class ResponsiveContentContainer extends StatelessWidget {
  /// Creates a centered container bounded by [LayoutBreakpoints.maxContentWidth].
  const ResponsiveContentContainer({
    super.key,
    required this.child,
    this.padding,
  });

  /// Child widget rendered inside the bounded column.
  final Widget child;

  /// Optional custom outer padding.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, layoutSize, _) {
        final horizontal = layoutSize == ScreenLayoutSize.compact ? 16.0 : 24.0;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: LayoutBreakpoints.maxContentWidth(layoutSize),
            ),
            child: Padding(
              padding: padding ??
                  EdgeInsets.symmetric(horizontal: horizontal, vertical: 16),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
