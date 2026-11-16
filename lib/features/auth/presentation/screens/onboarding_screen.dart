import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Comprendre votre cycle\nen toute sérénité',
      'subtitle':
          'Un suivi menstruel physiologique et intuitif, conçu pour respecter votre rythme biologique unique.',
      'badge': '100% Respectueux du corps',
      'image': 'assets/images/woman_wellness_natural.jpg',
      'icon': Icons.favorite_rounded,
      'gradient': const [Color(0xFF8E24AA), Color(0xFFF06292)],
      'quote': '« Estimer, expliquer et informer — jamais garantir. »',
    },
    {
      'title': 'Estimation intelligente\net contextualisée',
      'subtitle':
          'Anticipez votre fenêtre fertile et ovulation grâce à un moteur probabiliste clair, sans fausses certitudes.',
      'badge': 'Algorithme Transparent & Explicable',
      'image': 'assets/images/woman_stats_empowerment.jpg',
      'icon': Icons.auto_awesome_rounded,
      'gradient': const [Color(0xFF7B1FA2), Color(0xFFFF7043)],
      'quote': 'Des explications détaillées pour chaque estimation.',
    },
    {
      'title': 'Vos données intimes\nsous haute protection',
      'subtitle':
          'Vos données de santé restent strictement les vôtres. Chiffrement local renforcé et zéro pistage commercial.',
      'badge': 'Conforme RGPD & Zéro Revente',
      'image': 'assets/images/woman_serenity_journal.jpg',
      'icon': Icons.security_rounded,
      'gradient': const [Color(0xFF00897B), Color(0xFF8E24AA)],
      'quote': 'Stockage sécurisé sur votre appareil et en base isolée.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header supérieur avec badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: AppTheme.subtleShadow,
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'FertiliteApp',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                    child: const Text('Passer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  ),
                ],
              ),
            ),

            // Carrousel de diapositives
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  final List<Color> colors = slide['gradient'] as List<Color>;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration avec image naturelle et double halo
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors[0].withValues(alpha: 0.08),
                              ),
                            ),
                            Container(
                              width: 190,
                              height: 190,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors[0].withValues(alpha: 0.15),
                              ),
                            ),
                            Container(
                              width: 165,
                              height: 165,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors[0].withValues(alpha: 0.25),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: Image.asset(
                                  slide['image'] as String,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: AppTheme.primaryLight,
                                    child: Icon(
                                      slide['icon'] as IconData? ?? Icons.spa_rounded,
                                      size: 48,
                                      color: colors[0],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Badge de confiance
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors[0].withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colors[0].withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            slide['badge'] as String,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: colors[0],
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Titre principal
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Sous-titre descriptif concis
                        Text(
                          slide['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Citation / Tagline
                        Text(
                          slide['quote'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicateur de points animé
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppTheme.primary : AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Boutons d'action modernes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.floatingShadow,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Commencer l\'expérience', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('J\'ai déjà un compte', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
