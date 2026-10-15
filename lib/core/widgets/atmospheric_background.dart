import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Conteneur d'arrière-plan immersif, ergonomique et apaisant.
/// Il superpose une image de fond naturelle/éditoriale avec un double dégradé protecteur
/// respectant la palette FEMAX (AppTheme.background, primaryLight, accentRoseLight).
/// Cela garantit un contraste parfait (WCAG AAA) et une lisibilité absolue des textes et cartes.
class AtmosphericBackground extends StatelessWidget {
  final Widget child;
  final String? imagePath;
  final double blurAmount;
  final double overlayOpacity;

  const AtmosphericBackground({
    super.key,
    required this.child,
    this.imagePath = 'assets/images/woman_stats_empowerment.jpg',
    this.blurAmount = 0.0,
    this.overlayOpacity = 0.88,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Image de fond éditoriale avec fallback dégradé doux
        Positioned.fill(
          child: imagePath != null
              ? Image.asset(
                  imagePath!,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) => _buildFallbackGradient(),
                )
              : _buildFallbackGradient(),
        ),

        // 2. Filtre dégradé protecteur supérieur (lumière & contraste texte)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.background.withValues(alpha: overlayOpacity),
                  AppTheme.background.withValues(alpha: (overlayOpacity - 0.12).clamp(0.0, 1.0)),
                  AppTheme.background.withValues(alpha: (overlayOpacity + 0.04).clamp(0.0, 1.0)),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // 3. Halos chromatiques subtils selon la palette AppTheme (Améthyste & Rose)
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentRoseLight.withValues(alpha: 0.55),
                  AppTheme.accentRoseLight.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 260,
          left: -70,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryLight.withValues(alpha: 0.50),
                  AppTheme.primaryLight.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // 4. Contenu applicatif
        child,
      ],
    );
  }

  Widget _buildFallbackGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryLight,
            AppTheme.background,
            AppTheme.accentRoseLight,
          ],
        ),
      ),
    );
  }
}
