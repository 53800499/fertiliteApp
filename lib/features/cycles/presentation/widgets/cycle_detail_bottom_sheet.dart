import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../users/data/models/user_profile_model.dart';
import '../../data/models/cycle_models.dart';
import '../bloc/cycle_bloc.dart';
import '../bloc/cycle_event.dart';
import '../../../fertility/presentation/bloc/fertility_bloc.dart';
import '../../../observations/presentation/bloc/observation_bloc.dart';
import 'edit_cycle_bottom_sheet.dart';
import 'log_flow_bottom_sheet.dart';

class CycleDetailBottomSheet extends StatefulWidget {
  final CycleModel cycle;

  const CycleDetailBottomSheet({super.key, required this.cycle});

  static Future<void> show(
    BuildContext context, {
    required CycleModel cycle,
    bool useRootNavigator = true,
  }) {
    CycleBloc cycleBloc;
    try {
      cycleBloc = context.read<CycleBloc>();
    } catch (_) {
      cycleBloc = ServiceLocator.cycleBloc;
    }

    FertilityBloc fertBloc;
    try {
      fertBloc = context.read<FertilityBloc>();
    } catch (_) {
      fertBloc = ServiceLocator.fertilityBloc;
    }

    ObservationBloc obsBloc;
    try {
      obsBloc = context.read<ObservationBloc>();
    } catch (_) {
      obsBloc = ServiceLocator.observationBloc;
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: useRootNavigator,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cycleBloc),
          BlocProvider.value(value: fertBloc),
          BlocProvider.value(value: obsBloc),
        ],
        child: CycleDetailBottomSheet(cycle: cycle),
      ),
    );
  }

  @override
  State<CycleDetailBottomSheet> createState() => _CycleDetailBottomSheetState();
}

class _CycleDetailBottomSheetState extends State<CycleDetailBottomSheet> {
  late CycleModel _cycle;
  FullUserProfileModel? _profile;

  static const _moisFr = [
    '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];
  static const _moisFrCourt = [
    '', 'Jan.', 'Fév.', 'Mars', 'Avr.', 'Mai', 'Juin',
    'Juil.', 'Août', 'Sept.', 'Oct.', 'Nov.', 'Déc.'
  ];
  static const _joursFr = [
    '', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
  ];

  @override
  void initState() {
    super.initState();
    _cycle = widget.cycle;
    _loadProfile();
    _refreshCycleDetails();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await ServiceLocator.userRepository.getProfile();
      if (mounted) setState(() => _profile = p);
    } catch (_) {}
  }

  Future<void> _refreshCycleDetails() async {
    if (!mounted) return;
    try {
      final fresh = await ServiceLocator.cycleRepository.getCycleById(_cycle.id);
      if (mounted) {
        setState(() => _cycle = fresh);
      }
    } catch (_) {}
  }

  Future<void> _openEditCycle() async {
    final result = await EditCycleBottomSheet.show(
      context,
      cycle: _cycle,
      useRootNavigator: true,
    );
    if (!mounted) return;
    if (result == 'deleted') {
      Navigator.of(context).pop();
      return;
    }
    await _refreshCycleDetails();
    if (mounted) {
      try {
        context.read<CycleBloc>().add(LoadCyclesEvent());
      } catch (_) {
        ServiceLocator.cycleBloc.add(LoadCyclesEvent());
      }
    }
  }

  Future<void> _openLogFlow({DateTime? date, JourReglesModel? existingJour}) async {
    DateTime targetDate = date ?? DateTime.now();
    if (date == null) {
      if (_cycle.joursRegles.isNotEmpty) {
        try {
          final sorted = List<JourReglesModel>.from(_cycle.joursRegles)
            ..sort((a, b) => a.date.compareTo(b.date));
          targetDate = DateTime.parse(sorted.last.date).add(const Duration(days: 1));
        } catch (_) {
          targetDate = DateTime.now();
        }
      } else {
        try {
          targetDate = DateTime.parse(_cycle.dateDebut);
        } catch (_) {
          targetDate = DateTime.now();
        }
      }
    }

    final result = await LogFlowBottomSheet.show(
      context,
      date: targetDate,
      existingJour: existingJour,
      useRootNavigator: true,
    );
    if (!mounted) return;
    if (result != null) {
      await _refreshCycleDetails();
      if (mounted) {
        try {
          context.read<CycleBloc>().add(LoadCyclesEvent());
        } catch (_) {
          ServiceLocator.cycleBloc.add(LoadCyclesEvent());
        }
      }
    }
  }

  String _formatLongDate(String? raw) {
    if (raw == null || raw.isEmpty) return '--';
    try {
      final d = DateTime.parse(raw);
      return '${_joursFr[d.weekday]} ${d.day} ${_moisFr[d.month]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  String _formatShortDate(String? raw) {
    if (raw == null || raw.isEmpty) return '--';
    try {
      final d = DateTime.parse(raw);
      return '${d.day} ${_moisFrCourt[d.month]}';
    } catch (_) {
      return raw;
    }
  }

  int _calculateOvulationDay(int cycleLength) {
    // Phase lutéale standard de 14 jours
    final ovDay = cycleLength - 14;
    return ovDay > 5 ? ovDay : 14;
  }

  String _getDominantFlow(List<JourReglesModel> jours) {
    if (jours.isEmpty) return 'Non renseigné';
    final counts = <String, int>{};
    for (final j in jours) {
      counts[j.intensiteFlux] = (counts[j.intensiteFlux] ?? 0) + 1;
    }
    String dominant = 'moyen';
    int maxCount = 0;
    counts.forEach((flow, count) {
      if (count > maxCount) {
        maxCount = count;
        dominant = flow;
      }
    });
    return _getFlowLabel(dominant);
  }

  int? _getMaxPain(List<JourReglesModel> jours) {
    int? maxP;
    for (final j in jours) {
      if (j.douleurNiveau != null) {
        if (maxP == null || j.douleurNiveau! > maxP) {
          maxP = j.douleurNiveau;
        }
      }
    }
    return maxP;
  }

  String _getFlowLabel(String flow) {
    switch (flow) {
      case 'spotting':
        return 'Spotting (très léger)';
      case 'leger':
        return 'Léger';
      case 'moyen':
        return 'Moyen';
      case 'abondant':
        return 'Abondant';
      case 'tres_abondant':
        return 'Très abondant';
      default:
        return flow;
    }
  }

  Color _getFlowColor(String flow) {
    switch (flow) {
      case 'spotting':
        return const Color(0xFFE57373);
      case 'leger':
        return const Color(0xFFEF5350);
      case 'moyen':
        return AppTheme.periodColor;
      case 'abondant':
        return const Color(0xFFC2185B);
      case 'tres_abondant':
        return const Color(0xFF880E4F);
      default:
        return AppTheme.periodColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnCours = _cycle.isEnCours;
    final userAverageLength = _profile?.profil.dureeMoyenneCycle ?? 28;
    final totalDays = _cycle.dureeCycleJours ?? userAverageLength;
    final currentCycleDay = _cycle.currentCycleDay;
    final reglesDays = _cycle.dureeReglesJours ?? _cycle.joursRegles.length;
    final ovDay = _calculateOvulationDay(totalDays >= 20 ? totalDays : 28);
    final dominantFlow = _getDominantFlow(_cycle.joursRegles);
    final maxPain = _getMaxPain(_cycle.joursRegles);

    final statusColor = isEnCours ? Colors.teal : AppTheme.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
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

          // En-tête
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEnCours ? Icons.timelapse_rounded : Icons.check_circle_outline_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Cycle du ${_formatShortDate(_cycle.dateDebut)}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isEnCours ? 'En cours' : 'Terminé',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _cycle.dateFin != null
                            ? 'Du ${_formatShortDate(_cycle.dateDebut)} au ${_formatShortDate(_cycle.dateFin!)} (${_cycle.dureeCycleJours ?? totalDays}j)'
                            : 'Débuté le ${_formatShortDate(_cycle.dateDebut)} (Jour $currentCycleDay)',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Modifier ce cycle',
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                  onPressed: _openEditCycle,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Grille des 4 indicateurs clés
                  _buildStatsGrid(
                    totalDays: totalDays,
                    currentCycleDay: currentCycleDay,
                    isEnCours: isEnCours,
                    reglesDays: reglesDays,
                    ovDay: ovDay,
                    dominantFlow: dominantFlow,
                    maxPain: maxPain,
                  ),
                  const SizedBox(height: 18),

                  // 2. Bannière Réactive selon l'objectif de l'utilisatrice
                  _buildObjectiveInsightCard(
                    totalDays: totalDays,
                    reglesDays: reglesDays,
                    ovDay: ovDay,
                    isEnCours: isEnCours,
                  ),
                  const SizedBox(height: 20),

                  // 3. Chronologie des 4 phases physiologiques du cycle
                  _buildPhasesTimeline(
                    totalDays: totalDays,
                    reglesDays: reglesDays,
                    ovDay: ovDay,
                    currentDay: currentCycleDay,
                    isEnCours: isEnCours,
                  ),
                  const SizedBox(height: 22),

                  // 4. Section Journal des règles
                  _buildJoursReglesSection(context),
                  const SizedBox(height: 20),

                  // 5. Actions rapides
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openEditCycle,
                          icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                          label: const Text('Corriger dates'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textDark,
                            side: const BorderSide(color: AppTheme.borderLight),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openLogFlow(),
                          icon: const Icon(Icons.add_rounded, size: 17),
                          label: const Text('Ajouter un flux'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid({
    required int totalDays,
    required int currentCycleDay,
    required bool isEnCours,
    required int reglesDays,
    required int ovDay,
    required String dominantFlow,
    required int? maxPain,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.calendar_month_rounded,
                  iconColor: AppTheme.primary,
                  label: isEnCours ? 'Jour actuel' : 'Durée du cycle',
                  value: isEnCours ? 'Jour $currentCycleDay' : '$totalDays jours',
                  subtext: isEnCours ? 'Prévu : ~$totalDays j' : (totalDays >= 25 && totalDays <= 35 ? 'Régulier' : 'Cycle atypique'),
                ),
              ),
              Container(width: 1, height: 46, color: AppTheme.borderLight),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.water_drop_rounded,
                  iconColor: AppTheme.periodColor,
                  label: 'Règles',
                  value: '$reglesDays jours',
                  subtext: dominantFlow,
                ),
              ),
            ],
          ),
          const Divider(height: 22, color: AppTheme.borderLight),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.egg_outlined,
                  iconColor: Colors.deepOrange,
                  label: 'Ovulation estimée',
                  value: 'Jour $ovDay',
                  subtext: 'Phase lutéale : 14j',
                ),
              ),
              Container(width: 1, height: 46, color: AppTheme.borderLight),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.sentiment_satisfied_rounded,
                  iconColor: maxPain != null && maxPain >= 6 ? Colors.red : Colors.teal,
                  label: 'Douleur ressentie',
                  value: maxPain != null ? '$maxPain / 10' : 'Non notée',
                  subtext: maxPain != null
                      ? (maxPain <= 3 ? 'Crampes légères' : (maxPain <= 6 ? 'Douleur modérée' : 'Douleur vive'))
                      : 'Aucune saisie',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtext,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveInsightCard({
    required int totalDays,
    required int reglesDays,
    required int ovDay,
    required bool isEnCours,
  }) {
    final objective = _profile?.profil.objectifPrincipal ?? 'suivi_cycle';
    String tag;
    String title;
    String description;
    IconData icon;
    Color color;

    switch (objective) {
      case 'planifier_grossesse':
      case 'concevoir':
        tag = 'OBJECTIF CONCEPTION';
        title = 'Bilan de fertilité du cycle';
        description = isEnCours
            ? 'La fenêtre idéale de fécondation se situe aux alentours du Jour $ovDay (du Jour ${ovDay - 5} au Jour ${ovDay + 1}). Multipliez vos observations (glaire filante, tests LH) pour maximiser vos chances.'
            : 'Durant ce cycle, votre pic ovulatoire théorique a eu lieu vers le Jour $ovDay. Si des rapports ont eu lieu durant les 5 jours précédant ce repère, les chances de nidation étaient optimales.';
        icon = Icons.favorite_rounded;
        color = AppTheme.accentRose;
        break;

      case 'eviter_grossesse':
      case 'contraception_naturelle':
        tag = 'MÉTHODE NATURELLE';
        title = 'Zone de prudence & phase stérile';
        description = isEnCours
            ? 'Zone de vigilance active du Jour ${ovDay - 6} au Jour ${ovDay + 2}. Appliquez une protection barrière ou l\'abstinence jusqu\'à confirmation du décalage post-ovulatoire.'
            : 'Ce cycle a présenté une phase fertile théorique entre le Jour ${ovDay - 6} et le Jour ${ovDay + 2}. La période précédant les règles était physiologiquement stérile.';
        icon = Icons.shield_rounded;
        color = Colors.teal.shade700;
        break;

      case 'comprendre_corps':
        tag = 'BIORHYTHME & HORMONES';
        title = 'Décodage hormonal du cycle';
        description = isEnCours
            ? 'Vous êtes actuellement au Jour ${_cycle.currentCycleDay}. Observez votre niveau d\'énergie et votre clarté mentale en corrélation avec vos hormones dominantes (œstrogènes vs progestérone).'
            : 'Un cycle de $totalDays jours avec $reglesDays jours de flux témoigne d\'un équilibre physiologique. Les variations de vitalité ressenties reflètent le passage des 4 saisons de votre cycle.';
        icon = Icons.auto_awesome_rounded;
        color = Colors.purple.shade700;
        break;

      case 'suivi_cycle':
      case 'suivre_cycle':
      default:
        tag = 'RÉGULARITÉ DU CYCLE';
        title = 'Constat physiologique';
        description = isEnCours
            ? 'Cycle en cours au Jour ${_cycle.currentCycleDay}. Si votre cycle moyen est de 28 jours, vos prochaines règles sont estimées dans environ ${28 - _cycle.currentCycleDay} jours.'
            : 'Ce cycle complet a duré $totalDays jours avec $reglesDays jours de règles. Ces données affinent automatiquement la prédiction de vos prochains cycles.';
        icon = Icons.calendar_today_rounded;
        color = AppTheme.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: color),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: color,
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
                'Analyse profil',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppTheme.textMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhasesTimeline({
    required int totalDays,
    required int reglesDays,
    required int ovDay,
    required int currentDay,
    required bool isEnCours,
  }) {
    // Durée de référence sécurisée pour le calcul géométrique des phases (minimum 21 jours)
    final total = totalDays >= 21 ? totalDays : 28;
    final reglesEnd = (reglesDays > 0 ? reglesDays : 5).clamp(1, 8);
    final safeOv = ovDay.clamp(reglesEnd + 3, total - 4);
    final fertStart = (safeOv - 4).clamp(reglesEnd + 1, safeOv);
    final fertEnd = (safeOv + 1).clamp(fertStart, total - 1);

    final folliRange = reglesEnd + 1 <= fertStart - 1
        ? 'J${reglesEnd + 1} à J${fertStart - 1}'
        : 'J${reglesEnd + 1}';
    final lutealRange = fertEnd + 1 <= total
        ? 'J${fertEnd + 1} à J$total'
        : 'J$total';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, size: 18, color: AppTheme.primary),
              SizedBox(width: 8),
              Text(
                'Les 4 phases de ce cycle',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Phase des règles
          _buildPhaseRow(
            label: 'Phase des règles',
            subtitle: 'Desquamation & repos',
            dayRange: 'J1 à J$reglesEnd',
            color: AppTheme.periodColor,
            icon: Icons.water_drop_rounded,
            isActive: isEnCours && currentDay <= reglesEnd,
          ),
          const SizedBox(height: 10),

          // 2. Phase folliculaire
          _buildPhaseRow(
            label: 'Phase folliculaire',
            subtitle: 'Maturation & montée des œstrogènes',
            dayRange: folliRange,
            color: Colors.purple.shade400,
            icon: Icons.spa_rounded,
            isActive: isEnCours && currentDay > reglesEnd && currentDay < fertStart,
          ),
          const SizedBox(height: 10),

          // 3. Fenêtre fertile & ovulation
          _buildPhaseRow(
            label: 'Fenêtre fertile & Ovulation',
            subtitle: 'Pic de LH & réceptivité maximale',
            dayRange: 'J$fertStart à J$fertEnd (Pic J$safeOv)',
            color: AppTheme.accentRose,
            icon: Icons.favorite_rounded,
            isActive: isEnCours && currentDay >= fertStart && currentDay <= fertEnd,
          ),
          const SizedBox(height: 10),

          // 4. Phase lutéale
          _buildPhaseRow(
            label: 'Phase lutéale',
            subtitle: 'Progestérone & préparation',
            dayRange: lutealRange,
            color: Colors.indigo.shade400,
            icon: Icons.nightlight_round,
            isActive: isEnCours && currentDay > fertEnd,
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseRow({
    required String label,
    required String subtitle,
    required String dayRange,
    required Color color,
    required IconData icon,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.4) : AppTheme.borderLight,
          width: isActive ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isActive ? color : AppTheme.textDark,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Actuelle',
                          style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Text(
            dayRange,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive ? color : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoursReglesSection(BuildContext context) {
    final sortedJours = List<JourReglesModel>.from(_cycle.joursRegles)
      ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop_rounded, size: 18, color: AppTheme.periodColor),
                const SizedBox(width: 6),
                const Text(
                  'Journal des règles',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.periodColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${sortedJours.length} j',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.periodColor,
                    ),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _openLogFlow(),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Ajouter', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (sortedJours.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: const Center(
              child: Text(
                'Aucun jour de règles détaillé n’a encore été consigné pour ce cycle.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...sortedJours.asMap().entries.map((entry) {
            final index = entry.key;
            final jour = entry.value;
            final flowColor = _getFlowColor(jour.intensiteFlux);
            final flowLabel = _getFlowLabel(jour.intensiteFlux);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  DateTime target = DateTime.now();
                  try {
                    target = DateTime.parse(jour.date);
                  } catch (_) {}
                  _openLogFlow(date: target, existingJour: jour);
                },
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: flowColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'J${index + 1}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: flowColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _formatLongDate(jour.date),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: flowColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  flowLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: flowColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (jour.douleurNiveau != null || (jour.notes != null && jour.notes!.isNotEmpty)) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (jour.douleurNiveau != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.sentiment_neutral_rounded,
                                        size: 13,
                                        color: jour.douleurNiveau! >= 5 ? Colors.red : Colors.orange,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Douleur ${jour.douleurNiveau}/10',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: jour.douleurNiveau! >= 5 ? Colors.red : Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (jour.douleurNiveau != null && (jour.notes != null && jour.notes!.isNotEmpty))
                                  const Text('  •  ', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                if (jour.notes != null && jour.notes!.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      jour.notes!,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit_outlined, size: 15, color: AppTheme.textMuted),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
