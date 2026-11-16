import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/modern_app_header.dart';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_event.dart';
import '../bloc/subscription_state.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/subscription_plan_model.dart';
import '../../data/models/payment_transaction_model.dart';
import 'referral_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  /// Indique si l'écran s'ouvre comme passage initial exigé par l'administrateur.
  final bool isInitialMandatoryGate;

  const SubscriptionScreen({
    super.key,
    this.isInitialMandatoryGate = false,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _selectedBillingPeriod = 1; // 0 = mensuel, 1 = annuel (recommandé)
  bool _isShowingPaymentDialog = false;
  SubscriptionLoadedState? _lastLoadedState;

  static const List<SubscriptionPlanModel> _defaultFallbackPlans = [
    SubscriptionPlanModel(
      id: 'premium_mensuel',
      nom: 'Premium Sérénité (Mensuel)',
      prix: 1000,
      devise: 'XOF',
      periode: 'par mois',
      description: 'La puissance de l\'algorithme avancé et le décryptage complet de vos biomarqueurs.',
      populaire: false,
      avantages: [
        'Fenêtre fertile haute précision avec indice de confiance',
        'Détection automatique du décalage thermique (courbe BBT)',
        'Export PDF du Bilan Médical de Cycle pour votre praticien',
        'Historique illimité de tous vos cycles passés',
        'Alertes anticipées et conseils personnalisés',
      ],
    ),
    SubscriptionPlanModel(
      id: 'premium_annuel',
      nom: 'Premium Sérénité (Annuel)',
      prix: 10000,
      devise: 'XOF',
      periode: 'par an (~833 XOF/mois)',
      description: 'Une année complète de clarté, sérénité et accompagnement avec 2 mois offerts.',
      populaire: true,
      economie: '2 mois offerts',
      avantages: [
        'Tous les avantages Premium inclus',
        '2 mois offerts par rapport au paiement mensuel',
        'Analyses comparatives multi-cycles sur 12 mois',
        'Évolution des phases lutéales et régularité',
        'Accès garanti à toutes les futures fonctionnalités',
      ],
    ),
  ];

  SubscriptionLoadedState _buildFallbackLoadedState() {
    return SubscriptionLoadedState(
      subscription: SubscriptionModel(
        id: 'default_free',
        plan: 'gratuit',
        statut: 'actif',
        isPremium: false,
        dateDebut: DateTime.now(),
        renouvellementAutomatique: false,
        fournisseur: 'systeme',
        montant: 0,
        devise: 'XOF',
        libellePlan: 'Plan Essentiel (Gratuit)',
        avantagesActifs: const [
          'Calendrier menstruel intuitif',
          'Estimation standard',
          'Saisie quotidienne des observations',
        ],
      ),
      plans: _defaultFallbackPlans,
    );
  }

  @override
  void initState() {
    super.initState();
    final current = context.read<SubscriptionBloc>().state;
    if (current is SubscriptionLoadedState) {
      _lastLoadedState = current;
    }
    context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent(silent: true));
  }

  Future<void> _handleRefresh() async {
    context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent(silent: true));
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isInitialMandatoryGate,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: ModernAppHeader(
          leading: widget.isInitialMandatoryGate ? const SizedBox.shrink() : null,
          title: widget.isInitialMandatoryGate ? 'Bienvenue sur FertiliteApp' : 'Offres & Abonnement',
          subtitle: widget.isInitialMandatoryGate
              ? 'Activez Premium ou continuez gratuitement'
              : 'Expérience Premium Sérénité',
          onRefresh: _handleRefresh,
          actions: [
            IconButton(
              icon: const Icon(Icons.card_giftcard_rounded, color: AppTheme.primary, size: 22),
              tooltip: 'Parrainage & 30 jours offerts',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReferralScreen()),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
          listener: (context, state) {
            if (state is SubscriptionFailureState) {
              AppFeedback.showError(
                context,
                title: state.title ?? 'Abonnement',
                error: state.errorMessage,
              );
            } else if (state is SubscriptionLoadedState) {
              _lastLoadedState = state;
              if (state.errorMessage != null) {
                AppFeedback.showError(
                  context,
                  title: state.errorTitle ?? 'Abonnement',
                  error: state.errorMessage!,
                );
              }
              if (state.successMessage != null) {
                AppFeedback.showSuccess(
                  context,
                  title: 'Succès',
                  message: state.successMessage!,
                );
              }
              if (widget.isInitialMandatoryGate && state.subscription.isPremium) {
                ServiceLocator.storage.markInitialSubscriptionGateCompleted();
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop(true);
                }
                return;
              }
              if (state.activePaymentTransaction != null && !_isShowingPaymentDialog) {
                _openFedaPayCheckoutModal(context, state.activePaymentTransaction!);
              }
            }
          },
        builder: (context, state) {
          final effectiveState = state is SubscriptionLoadedState
              ? state
              : (_lastLoadedState ?? _buildFallbackLoadedState());
          final sub = effectiveState.subscription;
          final isPremium = sub.isPremium;
          final isLoading = state is SubscriptionLoadingState;

          return Column(
            children: [
              if (isLoading)
                const LinearProgressIndicator(
                  minHeight: 2.5,
                  color: AppTheme.primary,
                  backgroundColor: Colors.transparent,
                ),
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _handleRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 580),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.isInitialMandatoryGate && !isPremium) ...[
                              _buildInitialRequirementBanner(effectiveState),
                              const SizedBox(height: 16),
                            ],

                            // 1. Carte de statut actuel
                            _buildCurrentStatusCard(sub),
                            const SizedBox(height: 20),

                            // 2. Bannière Parrainage incitative
                            _buildReferralPromoBanner(context),
                            const SizedBox(height: 24),

                            // 3. Sélecteur de formule : Mensuel vs Annuel
                            _buildPeriodToggle(),
                            const SizedBox(height: 20),

                            // 4. Cartes des formules d'abonnement
                            _buildPlansSection(effectiveState),
                            const SizedBox(height: 28),

                            // 5. Comparatif des fonctionnalités (Gratuit vs Premium)
                            _buildComparisonTable(),
                            const SizedBox(height: 24),

                            // 6. Gestion / Résiliation si abonnée
                            if (isPremium) ...[
                              _buildManageSubscriptionSection(context, effectiveState),
                              const SizedBox(height: 24),
                            ],

                            if (widget.isInitialMandatoryGate && !isPremium) ...[
                              _buildContinueFreeButton(),
                              const SizedBox(height: 20),
                            ],

                            // 7. Mention légale et réassurance
                            _buildTrustFooter(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  Future<void> _handleContinueFree() async {
    await ServiceLocator.storage.markInitialSubscriptionGateCompleted();
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop(false);
    }
  }

  Widget _buildInitialRequirementBanner(SubscriptionLoadedState state) {
    final policyMsg = (state.policy.messageRecommandation ?? '').trim();
    final description = policyMsg.isNotEmpty
        ? policyMsg
        : 'Activez votre abonnement Premium (1 000 FCFA/mois) pour débloquer l’analyse médicale complète, ou continuez en mode gratuit.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuration initiale — Abonnement',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
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

  Widget _buildContinueFreeButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _handleContinueFree,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text(
            'Continuer avec la version gratuite',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textDark,
            side: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.35)),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vous pourrez activer Premium à tout moment pour accéder au bilan médical et aux statistiques avancées.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildCurrentStatusCard(SubscriptionModel sub) {
    final bool isPremium = sub.isPremium;
    final int? daysLeft = sub.joursRestants;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPremium
            ? const LinearGradient(
                colors: [Color(0xFF8E24AA), Color(0xFFC2185B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.subtleShadow,
        border: Border.all(
          color: isPremium ? Colors.transparent : AppTheme.primaryLight.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isPremium ? Icons.stars_rounded : Icons.spa_rounded,
                      color: isPremium ? const Color(0xFFFFD54F) : AppTheme.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isPremium ? 'Formule active : Premium' : 'Formule active : Plan Gratuit',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isPremium ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPremium ? Colors.white.withValues(alpha: 0.22) : AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPremium ? 'Actif ⭐' : 'Essentiel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPremium ? Colors.white : AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isPremium
                ? (daysLeft != null
                    ? 'Il vous reste $daysLeft jours d\'accès Premium privilégié.'
                    : 'Votre abonnement Premium Sérénité est pleinement actif.')
                : 'Accédez à la pleine puissance de vos cycles : prédictions haute confiance, détection BBT et bilans PDF.',
            style: TextStyle(
              fontSize: 13,
              color: isPremium ? Colors.white.withValues(alpha: 0.9) : AppTheme.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralPromoBanner(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReferralScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade300, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard_rounded, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Gagnez 30 jours de Premium gratuits ! 🎁',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF795548),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Parrainez une amie : 30 jours offerts pour elle et pour vous.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8D6E63)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF795548)),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedBillingPeriod = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedBillingPeriod == 0 ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Mensuel',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: _selectedBillingPeriod == 0 ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedBillingPeriod = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: _selectedBillingPeriod == 1 ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Annuel',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: _selectedBillingPeriod == 1 ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _selectedBillingPeriod == 1 ? Colors.amber : AppTheme.accentRose,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '2 mois offerts',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: _selectedBillingPeriod == 1 ? Colors.black87 : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection(SubscriptionLoadedState state) {
    final plans = state.plans.isNotEmpty ? state.plans : _defaultFallbackPlans;

    // Filtre sur le plan payant sélectionné
    final targetPlanId = _selectedBillingPeriod == 0
        ? 'premium_mensuel'
        : 'premium_annuel';

    final selectedPlan = plans.firstWhere(
      (p) => p.id == targetPlanId,
      orElse: () => plans.first,
    );

    final bool isAlreadySubscribed = state.subscription.isPremium &&
        state.subscription.plan == selectedPlan.id;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35), width: 1.5),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedPlan.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedPlan.description,
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              if (selectedPlan.populaire) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Recommandé',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),

          // Prix
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '${selectedPlan.prix.toStringAsFixed(0)} ${selectedPlan.devise}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ ${selectedPlan.periode}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
          const Divider(height: 28),

          // Liste des avantages
          ...selectedPlan.avantages.map(
            (av) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 18, color: Colors.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      av,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bouton d'action
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isAlreadySubscribed ? Colors.grey.shade400 : AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: isAlreadySubscribed || state.isSubmitting
                ? null
                : () => _confirmSubscription(context, selectedPlan),
            child: state.isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    isAlreadySubscribed ? 'Formule déjà active' : 'Souscrire maintenant',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    final rows = [
      {'feature': 'Calendrier menstruel interactif', 'free': true, 'premium': true},
      {'feature': 'Saisie observations (glaire, humeur, flux)', 'free': true, 'premium': true},
      {'feature': 'Estimation basique du cycle', 'free': true, 'premium': true},
      {'feature': 'Fenêtre fertile haute confiance probante', 'free': false, 'premium': true},
      {'feature': 'Détection automatique BBT (thermique)', 'free': false, 'premium': true},
      {'feature': 'Bilan médical PDF pour professionnel', 'free': false, 'premium': true},
      {'feature': 'Historique illimité de tous les cycles', 'free': false, 'premium': true},
      {'feature': 'Alertes prédictives & conseils intimes', 'free': false, 'premium': true},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparatif des formules',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(4),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Fonctionnalité', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: Text('Gratuit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text('Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary)),
                    ),
                  ),
                ],
              ),
              ...rows.map(
                (r) => TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.borderLight.withValues(alpha: 0.5))),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(r['feature'] as String, style: const TextStyle(fontSize: 12.5)),
                    ),
                    Center(
                      child: Icon(
                        (r['free'] as bool) ? Icons.check_circle_rounded : Icons.remove_rounded,
                        size: 16,
                        color: (r['free'] as bool) ? Colors.teal : Colors.grey.shade400,
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManageSubscriptionSection(BuildContext context, SubscriptionLoadedState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Gérer votre abonnement',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                SizedBox(height: 2),
                Text(
                  'Interrompez le renouvellement automatique à tout moment.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade200),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _confirmCancellation(context),
            child: const Text('Résilier', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustFooter() {
    return Column(
      children: const [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, size: 14, color: AppTheme.textMuted),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Paiement sécurisé • Sans engagement • Annulation en 1 clic',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          'Vos données intimes de santé ne sont jamais revendues ni partagées à des fins publicitaires.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  void _confirmSubscription(BuildContext context, SubscriptionPlanModel plan) {
    HapticFeedback.mediumImpact();
    _showPaymentMethodSheet(context, plan);
  }

  void _showPaymentMethodSheet(BuildContext context, SubscriptionPlanModel plan) {
    String selectedMethod = 'mtn';
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Barre indicatrice
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Titre & Sous-titre
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.payment_rounded, color: AppTheme.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Passerelle FedaPay',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                'Réglez facilement par Mobile Money ou Carte',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Récapitulatif de l'offre
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.nom,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  plan.periode,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${plan.prix.toStringAsFixed(0)} ${plan.devise}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Choix du moyen de paiement
                    const Text(
                      'Choisissez votre moyen de paiement :',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildPaymentMethodOption(
                      title: 'MTN Mobile Money (MoMo)',
                      subtitle: 'Bénin, Togo, Côte d\'Ivoire',
                      icon: Icons.phone_android_rounded,
                      color: const Color(0xFFFFCC00),
                      textColor: Colors.black87,
                      value: 'mtn',
                      groupValue: selectedMethod,
                      onChanged: (val) => setSheetState(() => selectedMethod = val!),
                    ),
                    const SizedBox(height: 8),

                    _buildPaymentMethodOption(
                      title: 'Moov Money (Flooz)',
                      subtitle: 'Bénin, Togo, Côte d\'Ivoire',
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFF0066B2),
                      textColor: Colors.white,
                      value: 'moov',
                      groupValue: selectedMethod,
                      onChanged: (val) => setSheetState(() => selectedMethod = val!),
                    ),
                    const SizedBox(height: 8),

                    _buildPaymentMethodOption(
                      title: 'Celtiis Cash',
                      subtitle: 'Bénin',
                      icon: Icons.flash_on_rounded,
                      color: const Color(0xFF8A2BE2),
                      textColor: Colors.white,
                      value: 'celtiis',
                      groupValue: selectedMethod,
                      onChanged: (val) => setSheetState(() => selectedMethod = val!),
                    ),
                    const SizedBox(height: 8),

                    _buildPaymentMethodOption(
                      title: 'Carte Bancaire (Visa / Mastercard)',
                      subtitle: 'Paiement international sécurisé',
                      icon: Icons.credit_card_rounded,
                      color: const Color(0xFF1E3A8A),
                      textColor: Colors.white,
                      value: 'carte',
                      groupValue: selectedMethod,
                      onChanged: (val) => setSheetState(() => selectedMethod = val!),
                    ),
                    const SizedBox(height: 16),

                    // Champ Numéro de téléphone Mobile Money
                    if (selectedMethod != 'carte') ...[
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Numéro Mobile Money (ex: 97000000)',
                          hintText: '8 chiffres sans indicatif',
                          prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 20),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Bouton de paiement FedaPay
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        context.read<SubscriptionBloc>().add(
                              InitiatePaymentEvent(
                                plan: plan.id,
                                moyenPaiement: selectedMethod,
                                phoneNumber: phoneController.text.trim(),
                              ),
                            );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Payer ${plan.prix.toStringAsFixed(0)} ${plan.devise} via FedaPay',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Badge de sécurité FedaPay
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.verified_user_rounded, size: 13, color: AppTheme.textMuted),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Transaction cryptée et certifiée par FedaPay SAS',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentMethodOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color textColor,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: textColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: AppTheme.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  void _openFedaPayCheckoutModal(BuildContext context, PaymentTransactionModel tx) {
    _isShowingPaymentDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return BlocConsumer<SubscriptionBloc, SubscriptionState>(
          listener: (ctx, state) {
            if (state is SubscriptionLoadedState && state.activePaymentTransaction == null) {
              if (Navigator.canPop(dialogCtx)) {
                Navigator.pop(dialogCtx);
              }
            }
          },
          builder: (ctx, state) {
            final isVerifying = state is SubscriptionLoadedState && state.isVerifyingPayment;
            final isSimulation = tx.mode == 'simulation';

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Paiement FedaPay',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isSimulation) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber.shade800),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Environnement de test Sandbox FedaPay',
                              style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Récapitulatif montant
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Montant à régler',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tx.amount.toStringAsFixed(0)} ${tx.devise}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Réf: ${tx.transactionId}',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '1. Cliquez sur le bouton ci-dessous pour ouvrir la page sécurisée FedaPay et valider sur votre téléphone.\n'
                    '2. Revenez ici et appuyez sur « Vérifier mon paiement » pour activer immédiatement vos avantages.',
                    style: TextStyle(fontSize: 12.5, color: AppTheme.textDark, height: 1.4),
                  ),
                  const SizedBox(height: 18),

                  // Bouton Ouvrir FedaPay
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                    label: const Text('Ouvrir la page de paiement FedaPay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () async {
                      try {
                        final uri = Uri.parse(tx.checkoutUrl);
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        if (context.mounted) {
                          AppFeedback.showInfo(
                            context,
                            message: 'Lien FedaPay: ${tx.checkoutUrl}',
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // Bouton Vérifier le statut
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: isVerifying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                          )
                        : const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text(
                      isVerifying ? 'Vérification en cours...' : 'Vérifier mon paiement',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: isVerifying
                        ? null
                        : () {
                            context.read<SubscriptionBloc>().add(
                                  VerifyPaymentEvent(transactionId: tx.transactionId),
                                );
                          },
                  ),

                  // Option simulation immédiate si sandbox
                  if (isSimulation) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.amber.shade900,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Simuler succès (Test instantané)', style: TextStyle(fontSize: 12)),
                      onPressed: isVerifying
                          ? null
                          : () {
                              context.read<SubscriptionBloc>().add(
                                    VerifyPaymentEvent(transactionId: tx.transactionId),
                                  );
                            },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    context.read<SubscriptionBloc>().add(ClearPaymentStateEvent());
                  },
                  child: const Text('Fermer / Plus tard', style: TextStyle(color: AppTheme.textMuted)),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _isShowingPaymentDialog = false;
    });
  }

  void _confirmCancellation(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Résilier le renouvellement ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: const Text(
          'Vous conserverez l\'ensemble de vos avantages Premium jusqu\'à la fin de la période en cours. Aucun prélèvement futur ne sera effectué.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Conserver mon offre'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SubscriptionBloc>().add(CancelSubscriptionEvent());
            },
            child: const Text('Confirmer la résiliation'),
          ),
        ],
      ),
    );
  }
}

