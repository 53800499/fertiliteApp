import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_skeleton_loader.dart';
import '../../../../core/error/error_feedback.dart';
import '../../../users/data/models/user_profile_model.dart';
import '../bloc/fertility_bloc.dart';
import '../../data/models/fertility_models.dart';

class FertilityExplanationBottomSheet extends StatefulWidget {
  const FertilityExplanationBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<FertilityBloc>(),
        child: const FertilityExplanationBottomSheet(),
      ),
    );
  }

  @override
  State<FertilityExplanationBottomSheet> createState() =>
      _FertilityExplanationBottomSheetState();
}

class _FertilityExplanationBottomSheetState
    extends State<FertilityExplanationBottomSheet> {
  FullUserProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await ServiceLocator.userRepository.getProfile();
      if (mounted) setState(() => _profile = p);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final objective = _profile?.profil.objectifPrincipal ?? 'suivi_cycle';
    Color headerColor;
    IconData headerIcon;
    String headerSubtitle;
    String bannerTitle;
    String bannerSubtitle;

    switch (objective) {
      case 'planifier_grossesse':
      case 'concevoir':
        headerColor = AppTheme.accentRose;
        headerIcon = Icons.favorite_rounded;
        headerSubtitle = 'Optimisation conception & biomarqueurs';
        bannerTitle = 'Projet conception & fertilité ciblée';
        bannerSubtitle = 'Estimation continue pour synchroniser vos essais avec votre physiologie.';
        break;
      case 'eviter_grossesse':
      case 'contraception_naturelle':
        headerColor = Colors.teal.shade700;
        headerIcon = Icons.shield_rounded;
        headerSubtitle = 'Vigilance naturelle & marge de précaution';
        bannerTitle = 'Observation éclairée & précaution';
        bannerSubtitle = 'Repère de sécurité pour vous guider dans la gestion naturelle de votre cycle.';
        break;
      case 'comprendre_corps':
        headerColor = Colors.purple.shade700;
        headerIcon = Icons.auto_awesome_rounded;
        headerSubtitle = 'Biorhythme hormonal & écoute de soi';
        bannerTitle = 'Harmonie hormonale & écoute de soi';
        bannerSubtitle = 'Décryptez l’impact de vos cycles sur votre énergie, vos sensations et votre humeur.';
        break;
      case 'suivi_cycle':
      case 'suivre_cycle':
      default:
        headerColor = AppTheme.primary;
        headerIcon = Icons.calendar_today_rounded;
        headerSubtitle = 'Repères physiologiques & régularité';
        bannerTitle = 'Pédagogie & régularité du cycle';
        bannerSubtitle = 'Repères clairs pour anticiper chaque étape et vivre vos cycles en toute sérénité.';
        break;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 14),

          // En-tête adapté à l'objectif
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(headerIcon, color: headerColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comprendre mon estimation',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        headerSubtitle,
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 20, color: AppTheme.borderLight),

          // Contenu défilant
          Expanded(
            child: BlocBuilder<FertilityBloc, FertilityState>(
              builder: (context, state) {
                if (state is FertilityLoadingState) {
                  return const _FertilityExplanationSkeleton();
                }

                if (state is FertilityFailureState) {
                  return AppErrorEmptyView(
                    error: state.message,
                    onRetry: () => context
                        .read<FertilityBloc>()
                        .add(const LoadCurrentFertilityEvent()),
                  );
                }

                final loadedState = state is FertilityLoadedState ? state : null;
                final prediction = loadedState?.currentPrediction;

                if (prediction == null) {
                  return const Center(child: Text('Aucune estimation disponible.'));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bannière Bienveillante & Pédagogique avec visuel authentique
                      Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7F9),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                'assets/images/woman_serenity_journal.jpg',
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 56,
                                  height: 56,
                                  color: headerColor.withValues(alpha: 0.12),
                                  child: Icon(headerIcon, color: headerColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bannerTitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    bannerSubtitle,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 1. Orientation selon l'objectif déclaré
                      _buildObjectiveGuidanceBanner(prediction),
                      const SizedBox(height: 16),

                      // 2. Carte Score & Jauge
                      _buildScoreGaugeCard(prediction),
                      const SizedBox(height: 20),

                      // 2. Niveau de confiance
                      _buildConfidenceCard(prediction),
                      const SizedBox(height: 22),

                      // 3. Titre Facteurs
                      const Text(
                        'Facteurs pris en compte (Explicabilité)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 4. Cartes des facteurs
                      if (prediction.factors.isEmpty)
                        const Text(
                          'Aucun facteur disponible pour cette estimation.',
                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        )
                      else
                        ...prediction.factors.map((factor) => _buildFactorCard(factor)),

                      const SizedBox(height: 16),

                      // 5. Bouton Recalculer
                      OutlinedButton.icon(
                        onPressed: () {
                          context
                              .read<FertilityBloc>()
                              .add(const RecalculateFertilityEvent());
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Actualiser mon estimation'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 6. Mention Légale & Éthique Obligatoire
                      _buildMedicalDisclaimer(),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveGuidanceBanner(PredictionModel prediction) {
    final objective = _profile?.profil.objectifPrincipal ?? 'suivi_cycle';
    String tag;
    String title;
    String desc;
    List<Map<String, String>> points;
    Color accentColor;
    IconData icon;

    switch (objective) {
      case 'planifier_grossesse':
      case 'concevoir':
        tag = 'OBJECTIF CONCEPTION';
        title = 'Calcul calibré pour maximiser vos chances';
        desc =
            'Votre score continu de ${prediction.fertilityScoreValue.round()}% traduit votre probabilité biologique de concevoir aujourd\'hui. Visez des rapports rapprochés lorsque le score s\'élève.';
        points = [
          {
            'title': 'Score continu de conception',
            'desc': 'Calcul en temps réel basé sur la viabilité des ovocytes et spermatozoïdes.',
          },
          {
            'title': 'Biomarqueurs amplificateurs',
            'desc': 'La glaire cervicale filante et les tests d\'ovulation (LH) augmentent considérablement l\'estimation.',
          },
          {
            'title': 'Fenêtre prioritaire',
            'desc': 'Les 5 jours précédant l\'ovulation et le jour J offrent les meilleures chances.',
          },
        ];
        accentColor = AppTheme.accentRose;
        icon = Icons.favorite_rounded;
        break;

      case 'eviter_grossesse':
      case 'contraception_naturelle':
        tag = 'MÉTHODE NATURELLE';
        title = 'Calcul appliquant une marge de sécurité stricte';
        desc =
            'Dans une démarche d\'observation naturelle, toute incertitude élargit la zone de précaution afin de garantir votre sérénité.';
        points = [
          {
            'title': 'Marge de précaution maximale',
            'desc': 'Le calcul intègre la survie prolongée des spermatozoïdes (jusqu\'à 5 jours dans les voies génitales).',
          },
          {
            'title': 'Surveillance des biomarqueurs',
            'desc': 'Dès l\'apparition d\'une glaire fertile ou d\'un test LH positif, la zone de vigilance est immédiate.',
          },
          {
            'title': 'Recommandation barrière',
            'desc': 'Préservatif ou abstinence recommandés durant toute la zone colorée.',
          },
        ];
        accentColor = Colors.teal.shade700;
        icon = Icons.shield_rounded;
        break;

      case 'comprendre_corps':
        tag = 'BIORHYTHME & HORMONES';
        title = 'Décodage de votre climat hormonal';
        desc =
            'Ce pourcentage mesure l\'intensité de votre climat œstrogénique et la réceptivité globale de votre corps tout au long du cycle.';
        points = [
          {
            'title': 'Climat œstrogénique & progestatif',
            'desc': 'Suivez le passage de la phase folliculaire (énergie montante) à la phase lutéale (ancrage et calme).',
          },
          {
            'title': 'Corrélation énergie & humeur',
            'desc': 'Comprenez pourquoi votre vitalité, votre libido et votre sommeil évoluent selon ce score.',
          },
          {
            'title': 'Écoute active des signaux',
            'desc': 'Reliez vos observations quotidiennes (glaire, température, tension) à vos cycles biologiques.',
          },
        ];
        accentColor = Colors.purple.shade700;
        icon = Icons.auto_awesome_rounded;
        break;

      case 'suivi_cycle':
      case 'suivre_cycle':
      default:
        tag = 'SUIVI DU CYCLE';
        title = 'Repères physiologiques & calendrier prédictif';
        desc =
            'Ce calcul mesure votre position dans votre cycle habituel pour anticiper les étapes clés avec régularité.';
        points = [
          {
            'title': 'Anticipation des règles',
            'desc': 'Calcul automatique basé sur une phase lutéale standard (~14 jours post-ovulation).',
          },
          {
            'title': 'Détection des retards & SPM',
            'desc': 'Alertes douces pour vous préparer aux variations prémenstruelles sans stress.',
          },
          {
            'title': 'Stabilité et régularité',
            'desc': 'Plus vous complétez vos cycles, plus l\'algorithme affine vos intervalles personnalisés.',
          },
        ];
        accentColor = AppTheme.primary;
        icon = Icons.calendar_today_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: accentColor),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Adapté au profil',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppTheme.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.5, color: AppTheme.borderLight),
          const SizedBox(height: 10),
          ...points.map((pt) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.check_circle_rounded, size: 14, color: accentColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${pt['title']!} : ',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            TextSpan(
                              text: pt['desc']!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textMuted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildScoreGaugeCard(PredictionModel prediction) {
    final objective = _profile?.profil.objectifPrincipal ?? 'suivi_cycle';
    final isElevee = prediction.fertilityCategory == 'elevee';
    final isMoyenne = prediction.fertilityCategory == 'moyenne';

    Color categoryColor;
    String categoryLabel;
    String scoreSubtitle;
    String ovulationLabel;
    String windowLabel;

    switch (objective) {
      case 'planifier_grossesse':
      case 'concevoir':
        categoryColor = isElevee
            ? AppTheme.accentRose
            : (isMoyenne ? Colors.orange : Colors.grey.shade600);
        categoryLabel = isElevee
            ? 'Chances de conception maximales 🔥'
            : (isMoyenne ? 'Chances de conception modérées 🌱' : 'Chances de conception faibles 💤');
        scoreSubtitle = 'Score continu de conception : ${prediction.fertilityScoreValue.toStringAsFixed(1)} / 100';
        ovulationLabel = 'Pic ovulatoire estimé';
        windowLabel = 'Fenêtre de conception';
        break;

      case 'eviter_grossesse':
      case 'contraception_naturelle':
        categoryColor = isElevee
            ? Colors.deepOrange.shade700
            : (isMoyenne ? Colors.amber.shade800 : Colors.teal.shade700);
        categoryLabel = isElevee
            ? 'Période fertile (Prudence) ⚠️'
            : (isMoyenne ? 'Zone d’incertitude fertile 🛡️' : 'Période peu fertile ✅');
        scoreSubtitle = 'Indice d’exposition : ${prediction.fertilityScoreValue.toStringAsFixed(1)} / 100';
        ovulationLabel = 'Charnière ovulatoire';
        windowLabel = 'Zone de prudence';
        break;

      case 'comprendre_corps':
        categoryColor = isElevee
            ? Colors.purple.shade700
            : (isMoyenne ? Colors.indigo.shade600 : Colors.teal.shade700);
        categoryLabel = isElevee
            ? 'Apogée œstrogénique ✨'
            : (isMoyenne ? 'Transition hormonale 🌸' : 'Phase de repos hormonal 🌙');
        scoreSubtitle = 'Intensité hormonale : ${prediction.fertilityScoreValue.toStringAsFixed(1)} / 100';
        ovulationLabel = 'Bascule hormonale';
        windowLabel = 'Fenêtre œstrogénique';
        break;

      case 'suivi_cycle':
      case 'suivre_cycle':
      default:
        categoryColor = isElevee
            ? AppTheme.accentRose
            : (isMoyenne ? Colors.orange : Colors.grey.shade600);
        categoryLabel = isElevee
            ? 'Fécondité élevée 📈'
            : (isMoyenne ? 'Approche de l’ovulation 🗓️' : 'Phase non fertile 📅');
        scoreSubtitle = 'Score physiologique : ${prediction.fertilityScoreValue.toStringAsFixed(1)} / 100';
        ovulationLabel = 'Ovulation estimée';
        windowLabel = 'Fenêtre fertile';
        break;
    }

    final scoreRatio = (prediction.fertilityScoreValue / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryLabel,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scoreSubtitle,
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${prediction.fertilityScoreValue.round()}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: categoryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barre de progression du score
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: scoreRatio,
              minHeight: 9,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
            ),
          ),
          const SizedBox(height: 14),

          // Repères physiologiques
          Row(
            children: [
              Expanded(
                flex: 4,
                child: _buildMetricChip(
                  ovulationLabel,
                  _formatDate(prediction.estimatedOvulationDate),
                  Icons.egg_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: _buildMetricChip(
                  windowLabel,
                  _formatWindow(prediction.fertileWindow.startDate, prediction.fertileWindow.endDate),
                  Icons.date_range_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty || raw == '--') return '--';
    try {
      final parts = raw.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}';
      }
      return raw;
    } catch (_) {
      return raw;
    }
  }

  String _formatWindow(String start, String end) {
    try {
      final sParts = start.split('-');
      final eParts = end.split('-');
      if (sParts.length == 3 && eParts.length == 3) {
        return '${sParts[2]}/${sParts[1]} au ${eParts[2]}/${eParts[1]}';
      }
      return '$start au $end';
    } catch (_) {
      return '$start au $end';
    }
  }

  Widget _buildConfidenceCard(PredictionModel prediction) {
    final objective = _profile?.profil.objectifPrincipal ?? 'suivi_cycle';
    String label = 'Confiance moyenne';
    Color color = Colors.orange;
    String tip =
        'Basée sur un historique partiel de vos cycles. Continuez vos saisies pour affiner la prédiction.';

    if (prediction.confidenceLevel == 'eleve') {
      label = 'Confiance élevée';
      color = Colors.teal;
      tip = (objective == 'eviter_grossesse' || objective == 'contraception_naturelle')
          ? 'Vos biomarqueurs confirment une excellente régularité, réduisant au minimum la marge d’aléa statistique.'
          : 'Vos cycles présentent une forte régularité statistique confirmée par vos observations.';
    } else if (prediction.confidenceLevel == 'faible') {
      label = 'Confiance indicative';
      color = Colors.deepOrange;
      tip = (objective == 'eviter_grossesse' || objective == 'contraception_naturelle')
          ? 'Historique jeune ou cycles variables. La zone de prudence est volontairement élargie pour votre sécurité.'
          : 'Historique encore jeune ou variabilité constatée. La fenêtre est élargie par précaution.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 3),
                Text(
                  tip,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorCard(FactorExplanationModel factor) {
    IconData icon = Icons.info_outline_rounded;
    Color iconColor = AppTheme.primary;

    switch (factor.type) {
      case 'historique_cycles':
        icon = Icons.history_rounded;
        iconColor = Colors.purple;
        break;
      case 'regularite':
        icon = Icons.timeline_rounded;
        iconColor = Colors.indigo;
        break;
      case 'test_ovulation':
        icon = Icons.biotech_rounded;
        iconColor = Colors.teal;
        break;
      case 'glaire_cervicale':
        icon = Icons.water_drop_outlined;
        iconColor = Colors.cyan;
        break;
      case 'temperature_basale':
        icon = Icons.thermostat_rounded;
        iconColor = Colors.amber.shade800;
        break;
      case 'position_dans_cycle':
        icon = Icons.calendar_today_rounded;
        iconColor = AppTheme.periodColor;
        break;
    }

    final isReinforcing = factor.direction == 'renforce';
    final effectColor = isReinforcing ? Colors.green.shade700 : Colors.amber.shade800;
    final effectLabel = isReinforcing ? 'Renforce l’estimation' : 'Ajuste l’incertitude';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor.description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: effectColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        effectLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: effectColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Poids : ${(factor.weight * 100).round()}%',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalDisclaimer() {
    final objective = _profile?.profil.objectifPrincipal ?? 'suivi_cycle';
    String title;
    String text;
    Color iconColor;

    switch (objective) {
      case 'planifier_grossesse':
      case 'concevoir':
        title = 'Projet de conception & fertilité';
        text =
            'Ces repères visent à optimiser vos chances de concevoir. La fécondation dépend de multiples facteurs physiologiques chez les deux partenaires. En cas de questions ou d’essais prolongés, consultez un professionnel de santé spécialisé.';
        iconColor = AppTheme.accentRose;
        break;

      case 'eviter_grossesse':
      case 'contraception_naturelle':
        title = 'Avertissement méthode naturelle & sécurité';
        text =
            'Cette estimation algorithmique est un outil d’auto-observation et de repère statistique. Elle ne constitue en aucun cas une méthode contraceptive médicale infaillible ni un substitut à l’apprentissage rigoureux de la symptothermie avec un professionnel formé.';
        iconColor = Colors.teal.shade700;
        break;

      case 'comprendre_corps':
        title = 'Accompagnement bien-être & écoute de soi';
        text =
            'Ce décodage hormonal est indicatif et pédagogique. Chaque organisme réagit à son rythme face au stress, à la fatigue et au mode de vie. En cas de douleurs inhabituelles ou d’irrégularités soudaines, demandez l’avis d’un professionnel.';
        iconColor = Colors.purple.shade700;
        break;

      case 'suivi_cycle':
      case 'suivre_cycle':
      default:
        title = 'Avertissement médical';
        text =
            'Cette estimation repose sur des règles physiologiques et statistiques. Elle ne garantit jamais la survenue d’une grossesse et ne constitue pas une méthode de contraception ni un diagnostic médical.';
        iconColor = AppTheme.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    height: 1.4,
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

class _FertilityExplanationSkeleton extends StatefulWidget {
  const _FertilityExplanationSkeleton();

  @override
  State<_FertilityExplanationSkeleton> createState() =>
      _FertilityExplanationSkeletonState();
}

class _FertilityExplanationSkeletonState
    extends State<_FertilityExplanationSkeleton>
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
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShimmerBone(height: 70, borderRadius: 18, opacity: opacity),
              const SizedBox(height: 16),
              ShimmerBone(height: 140, borderRadius: 24, opacity: opacity),
              const SizedBox(height: 16),
              ShimmerBone(height: 80, borderRadius: 16, opacity: opacity),
              const SizedBox(height: 12),
              ShimmerBone(height: 80, borderRadius: 16, opacity: opacity),
            ],
          ),
        );
      },
    );
  }
}
