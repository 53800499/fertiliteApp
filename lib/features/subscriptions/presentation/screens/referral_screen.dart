import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/modern_app_header.dart';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_event.dart';
import '../bloc/subscription_state.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionBloc>().add(LoadReferralInfoEvent());
    context.read<SubscriptionBloc>().add(LoadReferralHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const ModernAppHeader(
        title: 'Parrainage & Récompenses',
        subtitle: 'Offrez 30 jours • Gagnez 30 jours',
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionFailureState) {
            AppFeedback.showError(
              context,
              title: state.title ?? 'Parrainage',
              error: state.errorMessage,
            );
          } else if (state is SubscriptionLoadedState) {
            if (state.errorMessage != null) {
              AppFeedback.showError(
                context,
                title: state.errorTitle ?? 'Parrainage',
                error: state.errorMessage!,
              );
            }
            if (state.successMessage != null) {
              AppFeedback.showSuccess(
                context,
                title: 'Parrainage',
                message: state.successMessage!,
              );
            }
          }
        },
        builder: (context, state) {
          if (state is SubscriptionLoadingState) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final refInfo = state is SubscriptionLoadedState ? state.referralInfo : null;
          final history = state is SubscriptionLoadedState ? state.referralHistory : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hero Header bienveillant
                  _buildHeroHeader(),
                  const SizedBox(height: 20),

                  // 2. Mon code de parrainage à partager
                  _buildMyCodeCard(refInfo),
                  const SizedBox(height: 20),

                  // 3. Compteurs de statistiques
                  _buildStatsRow(refInfo),
                  const SizedBox(height: 24),

                  // 4. Explication du fonctionnement
                  _buildHowItWorksCard(),
                  const SizedBox(height: 24),

                  // 5. Historique des filleules
                  if (history != null && history.isNotEmpty) ...[
                    _buildHistorySection(history),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E24AA), Color(0xFFE91E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.card_giftcard_rounded, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Partagez FertiliteApp',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pour chaque amie qui découvre l\'application, vous recevez toutes les deux 30 jours d\'accès Premium offerts !',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCodeCard(dynamic refInfo) {
    final code = refInfo?.codeParrainage ?? 'CHARGEMENT...';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Votre code de parrainage exclusif',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),

          // Badge affichant le code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
            ),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.5,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Boutons d'action : Copier & Partager
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copier le code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: code));
                    AppFeedback.showSuccess(
                      context,
                      title: 'Copié !',
                      message: 'Code $code copié dans le presse-papier.',
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Partager le lien', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 10)),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    final shareText =
                        'Rejoins-moi sur FertiliteApp pour suivre ton cycle en toute sérénité ! Utilise mon code de parrainage $code pour débloquer 30 jours de Premium offerts : https://fertiliteapp.com/invitation?ref=$code';
                    Clipboard.setData(ClipboardData(text: shareText));
                    AppFeedback.showSuccess(
                      context,
                      title: 'Message prêt !',
                      message: 'Le message d\'invitation avec votre lien a été copié.',
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(dynamic refInfo) {
    final int count = refInfo?.totalFilleules ?? 0;
    final int days = refInfo?.totalJoursGagnes ?? 0;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.group_rounded, color: AppTheme.primary, size: 22),
                const SizedBox(height: 8),
                Text(
                  '$count',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                ),
                const SizedBox(height: 2),
                const Text('Amies parrainées', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.celebration_rounded, color: Colors.amber, size: 22),
                const SizedBox(height: 8),
                Text(
                  '+$days j',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.teal),
                ),
                const SizedBox(height: 2),
                const Text('Jours Premium offerts', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorksCard() {
    final steps = [
      {'num': '1', 'title': 'Partagez', 'desc': 'Envoyez votre code ou lien unique à vos amies.'},
      {
        'num': '2',
        'title': 'Votre amie crée son compte',
        'desc': 'Elle saisit votre code lors de son inscription et reçoit 30 jours de Premium offerts.'
      },
      {'num': '3', 'title': 'Vous gagnez', 'desc': 'Votre compte est automatiquement crédité de 30 jours gratuits !'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comment ça fonctionne ?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 16),
          ...steps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        s['num']!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(s['desc']!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(List<dynamic> history) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vos amies invitées',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 12),
          ...history.map(
            (h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: AppTheme.accentRose, size: 18),
                      const SizedBox(width: 10),
                      Text(h.libelle as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${h.joursGagnes} jours',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

