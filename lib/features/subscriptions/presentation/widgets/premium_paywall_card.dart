import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_state.dart';
import '../screens/referral_screen.dart';
import '../screens/subscription_screen.dart';

/// Utilitaires centralisés de vérification et d'affichage du Paywall Premium.
class PremiumPaywallHelper {
  PremiumPaywallHelper._();

  /// Retourne l'état SubscriptionLoadedState courant s'il existe.
  static SubscriptionLoadedState? _loadedState(BuildContext context) {
    try {
      final state = BlocProvider.of<SubscriptionBloc>(context, listen: true).state;
      if (state is SubscriptionLoadedState) return state;
    } catch (_) {
      final state = ServiceLocator.subscriptionBloc.state;
      if (state is SubscriptionLoadedState) return state;
    }
    return null;
  }

  /// Retourne true si l'utilisatrice dispose actuellement d'un abonnement Premium actif.
  static bool isPremium(BuildContext context) {
    return _loadedState(context)?.subscription.isPremium ?? false;
  }

  /// Retourne true si les paywalls doivent bloquer cette fonctionnalité :
  /// utilisatrice non-Premium ET exigence Paywalls activée par le Super Admin.
  static bool shouldEnforcePaywall(BuildContext context) {
    final loaded = _loadedState(context);
    if (loaded == null) return false;
    if (loaded.subscription.isPremium) return false;
    return loaded.policy.exigencePaywallsPremium;
  }

  /// Retourne le message de recommandation configuré par le Super Admin (ou message par défaut).
  static String recommendationMessage(BuildContext context) {
    final msg = _loadedState(context)?.policy.messageRecommandation;
    if (msg != null && msg.trim().isNotEmpty) return msg.trim();
    return 'Activez Premium Sérénité (1 000 XOF/mois ou 10 000 XOF/an) pour débloquer l\'analyse BBT, le bilan médical et l\'historique illimité.';
  }

  /// Ouvre la feuille modale d'invitation Premium lorsqu'une fonction verrouillée est sollicitée.
  static Future<void> showPaywallSheet(
    BuildContext context, {
    required String featureTitle,
    required String featureDescription,
    IconData icon = Icons.workspace_premium_rounded,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          padding: EdgeInsets.only(
            top: 14,
            left: 22,
            right: 22,
            bottom: MediaQuery.of(sheetCtx).viewPadding.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8E24AA), Color(0xFFC2185B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'FONCTIONNALITÉ PREMIUM ⭐',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                featureTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                featureDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7FC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.5)),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '1 000 XOF',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          ' / mois',
                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ou 10 000 XOF/an (2 mois offerts) • MTN MoMo, Moov, Celtiis & Carte',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.lock_open_rounded, size: 19),
                label: const Text(
                  'Débloquer Premium maintenant',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.card_giftcard_rounded, size: 17, color: AppTheme.accentRose),
                label: const Text(
                  'Ou obtenir 30 jours offerts par parrainage',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentRose,
                  ),
                ),
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const ReferralScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Carte inline élégante pour verrouiller une section Premium sans casser le layout.
class PremiumPaywallCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String ctaLabel;

  const PremiumPaywallCard({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.lock_outline_rounded,
    this.ctaLabel = 'Passer à Premium • 1 000 XOF/mois',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFAF5FD), Color(0xFFFDF2F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8E24AA), Color(0xFFC2185B)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PREMIUM ⭐',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(Icons.workspace_premium_rounded, size: 18),
            label: Text(
              ctaLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

