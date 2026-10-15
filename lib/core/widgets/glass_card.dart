import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Carte moderne en verre dépoli (Frosted Glassmorphism).
/// Conçue pour flotter au-dessus d'un arrière-plan avec image tout en garantissant
/// une lisibilité parfaite des données médicales et biométriques.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? surfaceColor;
  final Border? customBorder;
  final Gradient? gradient;
  final List<BoxShadow>? customShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = 22.0,
    this.surfaceColor,
    this.customBorder,
    this.gradient,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = customBorder ??
        Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1.2,
        );

    final effectiveColor = surfaceColor ?? Colors.white.withValues(alpha: 0.82);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14.0, sigmaY: 14.0),
        child: Container(
          decoration: BoxDecoration(
            color: gradient == null ? effectiveColor : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: effectiveBorder,
            boxShadow: customShadow ?? AppTheme.softShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(18),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
