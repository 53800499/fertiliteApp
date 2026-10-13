import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../network/network_cubit.dart';
import '../network/network_state.dart';
import '../theme/app_theme.dart';

/// Vue complète et soignée affichée lors d'un état hors-ligne sans données exploitables
class OfflineStateView extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customTitle;
  final String? customMessage;
  final bool showCards;

  const OfflineStateView({
    super.key,
    this.onRetry,
    this.customTitle,
    this.customMessage,
    this.showCards = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, netState) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration / Halo animé
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF3E5F5).withValues(alpha: 0.6),
                      ),
                    ),
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8E24AA), Color(0xFFF06292)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.wifi_off_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Titre
                Text(
                  customTitle ?? 'Pas de connexion Internet',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Explication rassurante
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Text(
                    customMessage ??
                        'Vous êtes actuellement hors ligne. Vos informations enregistrées localement restent protégées. Les échanges avec le serveur reprendront dès le retour d\'Internet.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.textMuted,
                      height: 1.45,
                    ),
                  ),
                ),

                if (showCards) ...[
                  const SizedBox(height: 24),
                  // Cartes d'assurance utilisateur
                  _buildFeatureRow(
                    icon: Icons.shield_outlined,
                    color: const Color(0xFF7E57C2),
                    title: 'Données protégées',
                    subtitle: 'Aucune donnée sensible n\'est perdue sur cet appareil.',
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureRow(
                    icon: Icons.sync_rounded,
                    color: const Color(0xFFEC407A),
                    title: 'Synchronisation automatique',
                    subtitle: 'Mise à jour immédiate dès la reconnexion.',
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureRow(
                    icon: Icons.phone_android_rounded,
                    color: const Color(0xFF26A69A),
                    title: 'Mode consultation locale',
                    subtitle: 'Votre calendrier et votre historique restent lisibles.',
                  ),
                ],

                const SizedBox(height: 28),

                // Bouton interactif de reconnexion
                ElevatedButton.icon(
                  onPressed: netState.isChecking
                      ? null
                      : () async {
                          final online = await context
                              .read<NetworkCubit>()
                              .checkConnectivity();
                          if (online && onRetry != null) {
                            onRetry!();
                          }
                        },
                  icon: netState.isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(
                    netState.isChecking
                        ? 'Vérification...'
                        : 'Tester la connexion',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
