import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// Système de squelettes (Skeleton Loaders) en verre dépoli (Frosted Glass).
/// Remplace avantageusement les spinners (CircularProgressIndicator) pour offrir
/// un ressenti de vitesse instantanée, sans coupure visuelle ni écran blanc.
class ShimmerBone extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final double opacity;

  const ShimmerBone({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8.0,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: (opacity * 0.7).clamp(0.15, 0.7)),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Squelette dédié à la page de Statistiques des Cycles
class StatsSkeletonView extends StatefulWidget {
  const StatsSkeletonView({super.key});

  @override
  State<StatsSkeletonView> createState() => _StatsSkeletonViewState();
}

class _StatsSkeletonViewState extends State<StatsSkeletonView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.35 + (_controller.value * 0.45);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // 1. Carte Bien-être au naturel
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ShimmerBone(width: 82, height: 82, borderRadius: 18, opacity: opacity),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBone(width: 90, height: 14, opacity: opacity),
                        const SizedBox(height: 10),
                        ShimmerBone(width: 160, height: 18, opacity: opacity),
                        const SizedBox(height: 8),
                        ShimmerBone(height: 13, opacity: opacity * 0.8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. Hero Card Régularité
            GlassCard(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.85),
                  AppTheme.accentRose.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 110,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: opacity * 0.45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: opacity * 0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 200,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: opacity * 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 250,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: opacity * 0.35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Grille des 4 métriques biométriques (2x2)
            Row(
              children: [
                Expanded(child: _buildMetricBone(opacity)),
                const SizedBox(width: 14),
                Expanded(child: _buildMetricBone(opacity)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildMetricBone(opacity)),
                const SizedBox(width: 14),
                Expanded(child: _buildMetricBone(opacity)),
              ],
            ),
            const SizedBox(height: 20),

            // 4. Histogramme des cycles récents
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBone(width: 140, height: 16, opacity: opacity),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBarBone(60, opacity),
                      _buildBarBone(90, opacity),
                      _buildBarBone(75, opacity),
                      _buildBarBone(110, opacity),
                      _buildBarBone(85, opacity),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricBone(double opacity) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBone(width: 32, height: 32, borderRadius: 10, opacity: opacity),
              ShimmerBone(width: 40, height: 12, opacity: opacity * 0.8),
            ],
          ),
          const SizedBox(height: 14),
          ShimmerBone(width: 60, height: 24, opacity: opacity),
          const SizedBox(height: 6),
          ShimmerBone(width: 90, height: 12, opacity: opacity * 0.7),
        ],
      ),
    );
  }

  Widget _buildBarBone(double height, double opacity) {
    return Container(
      width: 28,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.accentRoseLight.withValues(alpha: opacity * 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
    );
  }
}

/// Squelette dédié au Calendrier des Cycles & Fertilité
class CalendarSkeletonView extends StatefulWidget {
  const CalendarSkeletonView({super.key});

  @override
  State<CalendarSkeletonView> createState() => _CalendarSkeletonViewState();
}

class _CalendarSkeletonViewState extends State<CalendarSkeletonView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.35 + (_controller.value * 0.45);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Hero Status Card
            GlassCard(
              gradient: AppTheme.softHeroGradient,
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: opacity * 0.4),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: opacity * 0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 180,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: opacity * 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Grille Calendaire
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerBone(width: 110, height: 18, opacity: opacity),
                      Row(
                        children: [
                          ShimmerBone(width: 28, height: 28, borderRadius: 8, opacity: opacity),
                          const SizedBox(width: 8),
                          ShimmerBone(width: 28, height: 28, borderRadius: 8, opacity: opacity),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: opacity * 0.35),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Squelette dédié à l'Historique des Cycles
class HistorySkeletonView extends StatefulWidget {
  const HistorySkeletonView({super.key});

  @override
  State<HistorySkeletonView> createState() => _HistorySkeletonViewState();
}

class _HistorySkeletonViewState extends State<HistorySkeletonView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.35 + (_controller.value * 0.45);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Insight Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ShimmerBone(width: 82, height: 82, borderRadius: 18, opacity: opacity),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBone(width: 100, height: 14, opacity: opacity),
                        const SizedBox(height: 10),
                        ShimmerBone(width: 160, height: 18, opacity: opacity),
                        const SizedBox(height: 8),
                        ShimmerBone(height: 13, opacity: opacity * 0.8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Summary metric card
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      ShimmerBone(width: 50, height: 22, opacity: opacity),
                      const SizedBox(height: 6),
                      ShimmerBone(width: 70, height: 12, opacity: opacity * 0.7),
                    ],
                  ),
                  Container(width: 1, height: 35, color: AppTheme.borderLight),
                  Column(
                    children: [
                      ShimmerBone(width: 50, height: 22, opacity: opacity),
                      const SizedBox(height: 6),
                      ShimmerBone(width: 70, height: 12, opacity: opacity * 0.7),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3 cycle items
            for (int i = 0; i < 3; i++) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ShimmerBone(width: 44, height: 44, borderRadius: 12, opacity: opacity),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBone(width: 120, height: 16, opacity: opacity),
                          const SizedBox(height: 8),
                          ShimmerBone(width: 80, height: 12, opacity: opacity * 0.7),
                        ],
                      ),
                    ),
                    ShimmerBone(width: 55, height: 26, borderRadius: 14, opacity: opacity),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

/// Squelette dédié à la page Confidentialité, RGPD & Sécurité
class PrivacySkeletonView extends StatefulWidget {
  const PrivacySkeletonView({super.key});

  @override
  State<PrivacySkeletonView> createState() => _PrivacySkeletonViewState();
}

class _PrivacySkeletonViewState extends State<PrivacySkeletonView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.35 + (_controller.value * 0.45);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // 1. Bandeau RGPD
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              child: Row(
                children: [
                  ShimmerBone(width: 46, height: 46, borderRadius: 23, opacity: opacity),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBone(width: 180, height: 16, opacity: opacity),
                        const SizedBox(height: 8),
                        ShimmerBone(height: 12, opacity: opacity * 0.7),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Section Paramètres de protection (4 interrupteurs)
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShimmerBone(width: 22, height: 22, borderRadius: 6, opacity: opacity),
                      const SizedBox(width: 10),
                      ShimmerBone(width: 160, height: 16, opacity: opacity),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (int i = 0; i < 4; i++) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBone(width: 190, height: 14, opacity: opacity),
                              const SizedBox(height: 6),
                              ShimmerBone(width: 230, height: 11, opacity: opacity * 0.7),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ShimmerBone(width: 44, height: 26, borderRadius: 14, opacity: opacity),
                      ],
                    ),
                    if (i < 3) const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. Section Consentements
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShimmerBone(width: 22, height: 22, borderRadius: 6, opacity: opacity),
                      const SizedBox(width: 10),
                      ShimmerBone(width: 170, height: 16, opacity: opacity),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (int i = 0; i < 2; i++) ...[
                    Row(
                      children: [
                        ShimmerBone(width: 18, height: 18, borderRadius: 9, opacity: opacity),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBone(width: 150, height: 13, opacity: opacity),
                              const SizedBox(height: 5),
                              ShimmerBone(width: 110, height: 10, opacity: opacity * 0.7),
                            ],
                          ),
                        ),
                        ShimmerBone(width: 55, height: 20, borderRadius: 6, opacity: opacity),
                      ],
                    ),
                    if (i < 1) const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 4. Section Sessions Actives
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShimmerBone(width: 22, height: 22, borderRadius: 6, opacity: opacity),
                      const SizedBox(width: 10),
                      ShimmerBone(width: 180, height: 16, opacity: opacity),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ShimmerBone(width: 22, height: 22, borderRadius: 6, opacity: opacity),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBone(width: 130, height: 13, opacity: opacity),
                            const SizedBox(height: 5),
                            ShimmerBone(width: 90, height: 10, opacity: opacity * 0.7),
                          ],
                        ),
                      ),
                      ShimmerBone(width: 75, height: 24, borderRadius: 8, opacity: opacity * 0.8),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}


