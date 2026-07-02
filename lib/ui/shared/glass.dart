import 'dart:ui';

import 'package:flutter/material.dart';

/// Wiederverwendbare Liquid-Glass-Fläche (iOS-26-Optik).
///
/// Kombiniert einen Backdrop-Blur mit halbtransparentem Tint,
/// hellem Rand und weichem Schatten. Funktioniert am besten über
/// dem App-Hintergrundverlauf (siehe [AppTheme.hintergrundGradient]).
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Color? tint;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.blur = 18,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final basis = tint ?? Colors.white;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                basis.withValues(alpha: 0.60),
                basis.withValues(alpha: 0.30),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.65),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Drop-in-Ersatz für [Card] mit Liquid-Glass-Optik.
/// Der Inhalt bringt sein eigenes Padding mit (wie bei Card).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }
}
