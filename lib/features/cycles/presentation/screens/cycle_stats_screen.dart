import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../users/data/models/user_profile_model.dart';
import '../../data/models/cycle_models.dart';
import '../bloc/cycle_bloc.dart';
import '../bloc/cycle_event.dart';
import '../bloc/cycle_state.dart';
import '../../../../core/network/network_cubit.dart';
import '../../../../core/widgets/offline_state_view.dart';
import '../../../../core/widgets/offline_badge_chip.dart';
import '../../../../core/widgets/modern_app_header.dart';
import '../../../../core/widgets/natural_wellness_card.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/glass_skeleton_loader.dart';
import '../../../../core/error/error_feedback.dart';
import '../widgets/cycle_detail_bottom_sheet.dart';
import '../widgets/medical_summary_bottom_sheet.dart';
import '../../../observations/presentation/bloc/observation_bloc.dart';
import '../../../observations/presentation/bloc/observation_event.dart';
import '../../../observations/presentation/bloc/observation_state.dart';
import '../../../observations/presentation/widgets/bbt_chart_widget.dart';
import '../../../observations/presentation/widgets/observation_entry_bottom_sheet.dart';
import '../../../observations/data/models/observation_models.dart';

class CycleStatsScreen extends StatefulWidget {
  const CycleStatsScreen({super.key});

  @override
  State<CycleStatsScreen> createState() => _CycleStatsScreenState();
}

class _FilteredStatsData {
  final List<CycleModel> filteredCycles;
  final List<CycleModel> completedCycles;
  final double averageDuration;
  final double averagePeriodDuration;
  final int minDuration;
  final int maxDuration;
  final double standardDeviation;
  final String regularityLabel;
  final int completedCount;

  _FilteredStatsData({
    required this.filteredCycles,
    required this.completedCycles,
    required this.averageDuration,
    required this.averagePeriodDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.standardDeviation,
    required this.regularityLabel,
    required this.completedCount,
  });
}

class _PainAndFlowMetrics {
  final double averagePain;
  final int maxPain;
  final int totalPainDays;
  final int peakPainDay;
  final Map<String, int> flowCounts;
  final int totalFlowDays;

  _PainAndFlowMetrics({
    required this.averagePain,
    required this.maxPain,
    required this.totalPainDays,
    required this.peakPainDay,
    required this.flowCounts,
    required this.totalFlowDays,
  });
}

class _CycleStatsScreenState extends State<CycleStatsScreen> {
  FullUserProfileModel? _profile;
  String _selectedPeriod = 'all'; // '3m', '6m', '1an', 'all'
  String? _selectedCycleId;

  static const _moisFrCourt = [
    '', 'Jan.', 'Fév.', 'Mars', 'Avr.', 'Mai', 'Juin',
    'Juil.', 'Août', 'Sept.', 'Oct.', 'Nov.', 'Déc.'
  ];

  @override
  void initState() {
    super.initState();
    context.read<CycleBloc>().add(LoadCycleStatsEvent());
    context.read<CycleBloc>().add(LoadCyclesEvent());
    _loadBbtAnalysis();
    _loadProfile();
  }

  void _loadBbtAnalysis({CycleModel? cycle}) {
    if (!mounted) return;
    try {
      final obsBloc = context.read<ObservationBloc>();
      if (cycle != null) {
        obsBloc.add(LoadBbtAnalysisEvent(
          startDate: cycle.dateDebut,
          endDate: cycle.dateFin ?? DateTime.now().toIso8601String().substring(0, 10),
        ));
      } else if (_selectedPeriod != 'all') {
        final now = DateTime.now();
        final days = _selectedPeriod == '3m' ? 90 : (_selectedPeriod == '6m' ? 180 : 365);
        final cutoff = now.subtract(Duration(days: days)).toIso8601String().substring(0, 10);
        obsBloc.add(LoadBbtAnalysisEvent(startDate: cutoff));
      } else {
        obsBloc.add(const LoadBbtAnalysisEvent());
      }
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    try {
      final p = await ServiceLocator.userRepository.getProfile();
      if (mounted) setState(() => _profile = p);
    } catch (_) {}
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    context.read<CycleBloc>().add(LoadCycleStatsEvent());
    context.read<CycleBloc>().add(LoadCyclesEvent());
    _loadBbtAnalysis();
    await _loadProfile();
    await Future.delayed(const Duration(milliseconds: 700));
  }

  bool _isOffline(BuildContext context) {
    try {
      return !BlocProvider.of<NetworkCubit>(context).state.isOnline;
    } catch (_) {
      return false;
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

  void _openMedicalSummary(CycleStatsModel? stats, List<CycleModel> cycles) {
    HapticFeedback.selectionClick();
    MedicalSummaryBottomSheet.show(
      context,
      stats: stats,
      cycles: cycles,
      userProfile: _profile,
      useRootNavigator: true,
    );
  }

  _FilteredStatsData _calculateFilteredStats(CycleStatsModel? stats, List<CycleModel> allCycles) {
    List<CycleModel> filtered = allCycles;

    if (_selectedPeriod != 'all') {
      final now = DateTime.now();
      int days = _selectedPeriod == '3m' ? 90 : (_selectedPeriod == '6m' ? 180 : 365);
      final cutoff = now.subtract(Duration(days: days));

      final matched = allCycles.where((c) {
        try {
          return DateTime.parse(c.dateDebut).isAfter(cutoff);
        } catch (_) {
          return true;
        }
      }).toList();

      if (matched.isNotEmpty) {
        filtered = matched;
      } else {
        // Fallback si dates anciennes : N derniers cycles
        int count = _selectedPeriod == '3m' ? 3 : (_selectedPeriod == '6m' ? 6 : 12);
        filtered = allCycles.take(count).toList();
      }
    }

    final completed = filtered.where((c) => !c.isEnCours && c.dureeCycleJours != null).toList();

    if (_selectedPeriod == 'all' && stats != null) {
      return _FilteredStatsData(
        filteredCycles: filtered,
        completedCycles: completed,
        averageDuration: stats.averageDuration,
        averagePeriodDuration: stats.averagePeriodDuration,
        minDuration: stats.minDuration,
        maxDuration: stats.maxDuration,
        standardDeviation: stats.standardDeviation,
        regularityLabel: stats.regularityLabel,
        completedCount: stats.completedCycles,
      );
    }

    if (completed.isEmpty) {
      return _FilteredStatsData(
        filteredCycles: filtered,
        completedCycles: [],
        averageDuration: stats?.averageDuration ?? 28.0,
        averagePeriodDuration: stats?.averagePeriodDuration ?? 5.0,
        minDuration: stats?.minDuration ?? 28,
        maxDuration: stats?.maxDuration ?? 28,
        standardDeviation: stats?.standardDeviation ?? 0.0,
        regularityLabel: stats?.regularityLabel ?? 'Données préliminaires',
        completedCount: 0,
      );
    }

    final durations = completed.map((c) => c.dureeCycleJours!).toList();
    final periodDurations = completed.map((c) => (c.dureeReglesJours ?? c.joursRegles.length)).toList();

    final avgDuration = durations.reduce((a, b) => a + b) / durations.length;
    final avgPeriod = periodDurations.reduce((a, b) => a + b) / periodDurations.length;

    int minD = durations.reduce(math.min);
    int maxD = durations.reduce(math.max);

    double sumSqDiff = 0.0;
    for (final d in durations) {
      sumSqDiff += math.pow(d - avgDuration, 2);
    }
    final sd = math.sqrt(sumSqDiff / durations.length);

    String regLabel;
    if (completed.length < 2) {
      regLabel = 'Données préliminaires';
    } else if (sd < 2.0) {
      regLabel = 'Très régulier (< 2 j)';
    } else if (sd <= 4.0) {
      regLabel = 'Régulier (± 2-4 j)';
    } else {
      regLabel = 'Irrégulier (> 4 j)';
    }

    return _FilteredStatsData(
      filteredCycles: filtered,
      completedCycles: completed,
      averageDuration: avgDuration,
      averagePeriodDuration: avgPeriod,
      minDuration: minD,
      maxDuration: maxD,
      standardDeviation: sd,
      regularityLabel: regLabel,
      completedCount: completed.length,
    );
  }

  _PainAndFlowMetrics _calculatePainAndFlow(List<CycleModel> cycles) {
    final pains = <int>[];
    final flowCounts = <String, int>{
      'spotting': 0,
      'leger': 0,
      'moyen': 0,
      'abondant': 0,
    };
    final painByCycleDay = <int, List<int>>{};

    for (final cycle in cycles) {
      final sortedJours = List<JourReglesModel>.from(cycle.joursRegles)
        ..sort((a, b) => a.date.compareTo(b.date));

      for (int i = 0; i < sortedJours.length; i++) {
        final j = sortedJours[i];
        final cycleDay = i + 1; // J1, J2, ...

        if (j.douleurNiveau != null && j.douleurNiveau! > 0) {
          pains.add(j.douleurNiveau!);
          painByCycleDay.putIfAbsent(cycleDay, () => []).add(j.douleurNiveau!);
        }

        final flow = j.intensiteFlux.toLowerCase();
        if (flowCounts.containsKey(flow)) {
          flowCounts[flow] = flowCounts[flow]! + 1;
        } else if (flow == 'tres_abondant') {
          flowCounts['abondant'] = (flowCounts['abondant'] ?? 0) + 1;
        }
      }
    }

    double avgPain = pains.isEmpty ? 0.0 : (pains.reduce((a, b) => a + b) / pains.length);
    int maxPain = pains.isEmpty ? 0 : pains.reduce(math.max);

    // Jour du pic de douleur
    int peakDay = 1;
    double highestAvgPain = 0.0;
    painByCycleDay.forEach((day, dayPains) {
      final avg = dayPains.reduce((a, b) => a + b) / dayPains.length;
      if (avg > highestAvgPain) {
        highestAvgPain = avg;
        peakDay = day;
      }
    });

    final totalFlowDays = flowCounts.values.fold(0, (sum, count) => sum + count);

    return _PainAndFlowMetrics(
      averagePain: avgPain,
      maxPain: maxPain,
      totalPainDays: pains.length,
      peakPainDay: peakDay,
      flowCounts: flowCounts,
      totalFlowDays: totalFlowDays,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CycleBloc, CycleState>(
      listener: (context, state) {
        if (state is CycleFailureState) {
          AppFeedback.showError(
            context,
            error: state.message,
            customTitle: 'Statistiques du cycle',
          );
        }
      },
      builder: (context, state) {
        final loaded = state is CyclesLoadedState ? state : null;
        final stats = loaded?.stats;
        final allCycles = loaded?.cycles ?? [];

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: ModernAppHeader(
            transparent: true,
            subtitle: 'Biométrie & Régularité',
            title: 'Statistiques & Régularité',
            onRefresh: _handleRefresh,
            actions: [
              ModernHeaderIconButton(
                icon: Icons.medical_services_outlined,
                tooltip: 'Bilan consultation',
                onPressed: () => _openMedicalSummary(stats, allCycles),
              ),
            ],
          ),
          body: AtmosphericBackground(
            imagePath: 'assets/images/woman_stats_empowerment.jpg',
            child: _buildBody(context, state, stats, allCycles),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    CycleState state,
    CycleStatsModel? stats,
    List<CycleModel> allCycles,
  ) {
    if (state is CycleLoadingState) {
      return const StatsSkeletonView();
    }

    if (state is CycleFailureState) {
      final isOffline = _isOffline(context) ||
          state.message.toLowerCase().contains('connexion') ||
          state.message.toLowerCase().contains('hors ligne') ||
          state.message.toLowerCase().contains('socketexception') ||
          state.message.toLowerCase().contains('failed host lookup');

      return RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: Colors.white,
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: isOffline ? OfflineStateView(onRetry: _handleRefresh) : AppErrorEmptyView(error: state.message, onRetry: _handleRefresh),
        ),
      );
    }

    if (stats == null && allCycles.isEmpty && _isOffline(context)) {
      return RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: Colors.white,
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: OfflineStateView(onRetry: _handleRefresh),
        ),
      );
    }

    if (allCycles.isEmpty && (stats == null || (stats.completedCycles == 0 && stats.totalCycles == 0))) {
      return RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: Colors.white,
        onRefresh: _handleRefresh,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: NaturalWellnessEmptyView(
            imagePath: 'assets/images/woman_stats_empowerment.jpg',
            title: 'Vos statistiques s’enrichiront bientôt',
            message: 'Dès que vos premiers cycles seront enregistrés, cette page révélera vos tendances physiologiques, votre durée moyenne et votre indice de régularité.',
          ),
        ),
      );
    }

    // Calcul dynamique selon le filtre temporel
    final filteredData = _calculateFilteredStats(stats, allCycles);
    final painMetrics = _calculatePainAndFlow(filteredData.filteredCycles);

    return RefreshIndicator(
      color: AppTheme.primary,
      backgroundColor: Colors.white,
      displacement: 40,
      strokeWidth: 2.5,
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Builder(
              builder: (ctx) {
                if (!_isOffline(ctx)) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      OfflineBadgeChip(label: 'Statistiques basées sur les données locales'),
                    ],
                  ),
                );
              },
            ),

            // Carte Vitalité & Compréhension de son corps avec visuel naturel rayonnant
            const NaturalWellnessCard(
              imagePath: 'assets/images/woman_stats_empowerment.jpg',
              title: 'Comprendre & Célébrer son corps',
              message: 'Les variations de durée sont naturelles. Vos statistiques vous aident à vivre chaque phase en pleine harmonie.',
              badgeText: 'Vitalité & Confiance',
            ),
            const SizedBox(height: 18),

            // 1. Sélecteur de période temporelle
            _buildPeriodFilterChips(),
            const SizedBox(height: 18),

            // 2. Hero Card : Jauge Visuelle de Régularité Biométrique
            _buildHeroRegularityCard(stats, filteredData),
            const SizedBox(height: 20),

            // 3. Grille des 4 indicateurs biométriques
            _buildMetricsGrid(filteredData),
            const SizedBox(height: 20),

            // 4. Histogramme interactif double-teinte (Stacked Bar Chart)
            _buildCycleLengthBarChart(filteredData, allCycles),
            const SizedBox(height: 20),

            // 5. Courbe biphasique de température basale (UC-16 DataViz BBT)
            _buildBbtAnalysisSection(allCycles),
            const SizedBox(height: 20),

            // 6. Bilan des Douleurs Menstruelles & Intensités de Flux
            _buildPainAndFlowCard(painMetrics),
            const SizedBox(height: 20),

            // 6. Découpage moyen des 4 phases physiologiques du cycle
            _buildPhasesBreakdownCard(filteredData),
            const SizedBox(height: 20),

            // 7. Bannière dynamique selon l'Objectif de l'utilisatrice
            _buildObjectiveInsightCard(filteredData),
            const SizedBox(height: 20),

            // 8. Carte d'invitation au Bilan Médical
            _buildDoctorExportCard(stats, allCycles),
            const SizedBox(height: 20),

            // 9. Note médicale & explications pédagogiques
            _buildMedicalExplanationCard(),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  // 1. Sélecteur de période temporelle
  Widget _buildPeriodFilterChips() {
    final periods = [
      {'key': '3m', 'label': '3 mois'},
      {'key': '6m', 'label': '6 mois'},
      {'key': '1an', 'label': '1 an'},
      {'key': 'all', 'label': 'Tous les cycles'},
    ];

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      borderRadius: 16,
      child: Row(
        children: periods.map((p) {
          final isSelected = _selectedPeriod == p['key'];
          return Expanded(
            child: InkWell(
              onTap: () {
                if (!isSelected) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedPeriod = p['key']!;
                    _selectedCycleId = null;
                  });
                  _loadBbtAnalysis();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  p['label']!,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 2. Hero Card : Jauge Visuelle de Régularité Biométrique
  Widget _buildHeroRegularityCard(CycleStatsModel? stats, _FilteredStatsData filteredData) {
    final isReliable = filteredData.completedCount >= 2;
    final sd = filteredData.standardDeviation;

    Color gaugeColor;
    String verdictSubtext;
    double needleRatio; // 0.0 to 1.0

    if (!isReliable) {
      gaugeColor = Colors.white70;
      needleRatio = 0.5;
      verdictSubtext = 'Enregistrez au moins 2 cycles clôturés pour mesurer la régularité mathématique.';
    } else if (sd < 2.0) {
      gaugeColor = Colors.tealAccent.shade400;
      needleRatio = (sd / 2.0 * 0.33).clamp(0.05, 0.33);
      verdictSubtext = 'Variabilité inférieure à 2 jours : votre équilibre hormonal est remarquable.';
    } else if (sd <= 4.0) {
      gaugeColor = Colors.amberAccent;
      needleRatio = 0.33 + ((sd - 2.0) / 2.0 * 0.34).clamp(0.0, 0.34);
      verdictSubtext = 'Variation de ± ${sd.toStringAsFixed(1)} j : fluctuation physiologique tout à fait normale.';
    } else {
      gaugeColor = Colors.orangeAccent;
      needleRatio = 0.67 + ((sd - 4.0) / 4.0 * 0.33).clamp(0.0, 0.33);
      verdictSubtext = 'Variations de plus de 4 jours : les prédictions appliquent une marge de sécurité accrue.';
    }

    return GlassCard(
      padding: const EdgeInsets.all(22),
      borderRadius: 24,
      gradient: AppTheme.softHeroGradient,
      customBorder: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
      customShadow: AppTheme.floatingShadow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isReliable ? Icons.verified_rounded : Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isReliable ? 'Calcul sur ${filteredData.completedCount} cycles' : 'Données préliminaires',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _openMedicalSummary(stats, filteredData.filteredCycles),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Indice de régularité biométrique :',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            filteredData.regularityLabel,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 14),

          // Jauge visuelle segmentée à 3 zones
          Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final needlePos = (totalWidth * needleRatio).clamp(8.0, totalWidth - 8.0);

                  return Column(
                    children: [
                      // Repère pointeur
                      SizedBox(
                        height: 12,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: needlePos - 6,
                              top: 0,
                              child: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: gaugeColor,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Barre segmentée à 3 zones
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 8,
                          child: Row(
                            children: [
                              Expanded(child: Container(color: Colors.tealAccent.shade400)),
                              const SizedBox(width: 2),
                              Expanded(child: Container(color: AppTheme.accentRose)),
                              const SizedBox(width: 2),
                              Expanded(child: Container(color: Colors.orangeAccent)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Légende sous la jauge
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Très régulier (<2j)', style: TextStyle(fontSize: 9.5, color: Colors.white70)),
                          Text('Régulier (±2-4j)', style: TextStyle(fontSize: 9.5, color: Colors.white70)),
                          Text('Irrégulier (>4j)', style: TextStyle(fontSize: 9.5, color: Colors.white70)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            isReliable
                ? 'Écart-type : ± ${sd.toStringAsFixed(1)} jour(s). $verdictSubtext'
                : verdictSubtext,
            style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
          ),
        ],
      ),
    );
  }

  // 3. Grille des 4 indicateurs biométriques
  Widget _buildMetricsGrid(_FilteredStatsData data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Durée moyenne',
                value: '${data.averageDuration.toStringAsFixed(1)} j',
                subtitle: 'Norme FIGO : 24-38j',
                icon: Icons.timelapse_rounded,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricTile(
                title: 'Durée des règles',
                value: '${data.averagePeriodDuration.toStringAsFixed(1)} j',
                subtitle: 'Saignements moyens',
                icon: Icons.water_drop_rounded,
                color: AppTheme.periodColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Cycle le plus court',
                value: '${data.minDuration} j',
                subtitle: 'Borne basse observée',
                icon: Icons.arrow_downward_rounded,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricTile(
                title: 'Cycle le plus long',
                value: '${data.maxDuration} j',
                subtitle: 'Borne haute observée',
                icon: Icons.arrow_upward_rounded,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppTheme.textDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 4. Histogramme interactif double-teinte (Stacked Bar Chart)
  Widget _buildCycleLengthBarChart(_FilteredStatsData filteredData, List<CycleModel> allCycles) {
    final completed = filteredData.completedCycles.reversed.toList();
    final avgDuration = filteredData.averageDuration;

    CycleModel? selectedCycle;
    if (_selectedCycleId != null) {
      try {
        selectedCycle = allCycles.firstWhere((c) => c.id == _selectedCycleId);
      } catch (_) {}
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Évolution des durées',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Toucher une barre pour inspecter le cycle',
                    style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${completed.length} cycles',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (completed.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    const Text(
                      'Aucun cycle clôturé dans cette période',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                // Repère de moyenne en ligne pointillée
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Moyenne : ${avgDuration.toStringAsFixed(1)} j',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return CustomPaint(
                              size: Size(constraints.maxWidth, 1),
                              painter: _DashedLinePainter(color: AppTheme.primary.withValues(alpha: 0.4)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Barres empilées
                SizedBox(
                  height: 170,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: completed.map((cycle) {
                      final duration = cycle.dureeCycleJours ?? 28;
                      final reglesDays = cycle.dureeReglesJours ?? cycle.joursRegles.length;

                      final isSelected = cycle.id == _selectedCycleId;
                      final isNormal = duration >= 24 && duration <= 35;

                      // Normalisation hauteur max (135px)
                      const maxPixelHeight = 135.0;
                      final totalBarHeight = (duration / 42.0 * maxPixelHeight).clamp(35.0, maxPixelHeight);
                      final reglesHeight = (reglesDays / duration * totalBarHeight).clamp(8.0, totalBarHeight - 10.0);
                      final otherHeight = totalBarHeight - reglesHeight;

                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final newSelected = isSelected ? null : cycle;
                          setState(() {
                            _selectedCycleId = newSelected?.id;
                          });
                          _loadBbtAnalysis(cycle: newSelected);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary.withValues(alpha: 0.08) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected ? Border.all(color: AppTheme.primary, width: 1.4) : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '$duration j',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppTheme.primary : (isNormal ? AppTheme.textDark : Colors.orange),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Barre empilée (Haut: cycle | Bas: règles)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: isSelected ? 26 : 22,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Phase post-règles
                                      Container(
                                        height: otherHeight,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isNormal
                                                ? [AppTheme.primary, AppTheme.accentRose]
                                                : [Colors.orange, Colors.amber],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                        ),
                                      ),
                                      // Phase des règles (rouge/rose)
                                      Container(
                                        height: reglesHeight,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Color(0xFFC2185B), Color(0xFFE57373)],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              Text(
                                _formatShortDate(cycle.dateDebut),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Légende couleurs
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFC2185B), shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        const Text('Règles', style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        const Text('Phase folliculaire & lutéale', style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                      ],
                    ),
                  ],
                ),

                // Fiche interactive du cycle sélectionné
                if (selectedCycle != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.event_available_rounded, size: 18, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cycle du ${_formatShortDate(selectedCycle.dateDebut)}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                              Text(
                                'Durée : ${selectedCycle.dureeCycleJours} jours  •  Règles : ${selectedCycle.dureeReglesJours ?? selectedCycle.joursRegles.length} jours',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            CycleDetailBottomSheet.show(context, cycle: selectedCycle!);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          child: const Row(
                            children: [
                              Text('Détails', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(width: 2),
                              Icon(Icons.arrow_forward_ios_rounded, size: 11),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // 5. Courbe biphasique de température basale (UC-16 DataViz BBT)
  Widget _buildBbtAnalysisSection(List<CycleModel> allCycles) {
    CycleModel? activeCycle;
    if (_selectedCycleId != null) {
      try {
        activeCycle = allCycles.firstWhere((c) => c.id == _selectedCycleId);
      } catch (_) {}
    } else if (allCycles.isNotEmpty) {
      try {
        activeCycle = allCycles.firstWhere((c) => c.isEnCours);
      } catch (_) {
        activeCycle = allCycles.first;
      }
    }

    return BlocBuilder<ObservationBloc, ObservationState>(
      buildWhen: (prev, curr) =>
          curr is BbtAnalysisLoadedState ||
          curr is ObservationLoadingState ||
          curr is ObservationFailureState,
      builder: (context, obsState) {
        BbtAnalysisModel? analysis;
        bool isLoading = false;

        if (obsState is BbtAnalysisLoadedState) {
          analysis = obsState.analysis;
        } else {
          analysis = context.read<ObservationBloc>().cachedBbtAnalysis;
          if (obsState is ObservationLoadingState && analysis == null) {
            isLoading = true;
          }
        }

        if (isLoading) {
          return GlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const ShimmerBone(width: 42, height: 42, borderRadius: 14, opacity: 0.6),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBone(width: 140, height: 16, borderRadius: 6, opacity: 0.6),
                        SizedBox(height: 6),
                        ShimmerBone(width: 190, height: 12, borderRadius: 6, opacity: 0.4),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const ShimmerBone(width: double.infinity, height: 180, borderRadius: 16, opacity: 0.5),
              ],
            ),
          );
        }

        final bbtAnalysis = analysis ??
            const BbtAnalysisModel(
              status: 'insufficient_data',
              message:
                  'Enregistrez chaque matin votre température au réveil pour détecter automatiquement votre décalage thermique post-ovulation (+0.2°C à +0.5°C).',
              shiftDetected: false,
              points: [],
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (activeCycle != null && _selectedCycleId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Zoom sur le cycle du ${_formatShortDate(activeCycle.dateDebut)}${activeCycle.dateFin != null ? ' au ${_formatShortDate(activeCycle.dateFin)}' : ' (en cours)'}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCycleId = null);
                        _loadBbtAnalysis();
                      },
                      child: const Text(
                        'Vue globale',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            BbtChartWidget(
              analysis: bbtAnalysis,
              onAddTemperature: () async {
                final res = await ObservationEntryBottomSheet.show(
                  context,
                  date: DateTime.now(),
                );
                if (res == true && mounted) {
                  _loadBbtAnalysis(cycle: activeCycle);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // 6. Bilan des Douleurs Menstruelles & Intensités de Flux
  Widget _buildPainAndFlowCard(_PainAndFlowMetrics metrics) {
    final hasPainData = metrics.totalPainDays > 0;
    final hasFlowData = metrics.totalFlowDays > 0;

    Color painColor;
    String painVerdict;
    if (metrics.averagePain <= 2.5) {
      painColor = Colors.teal;
      painVerdict = 'Inconfort léger ou nul';
    } else if (metrics.averagePain <= 5.5) {
      painColor = Colors.orange;
      painVerdict = 'Douleur modérée (crampes classiques)';
    } else {
      painColor = Colors.red;
      painVerdict = 'Douleur vive ou intense';
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_heart_rounded, size: 20, color: AppTheme.periodColor),
              SizedBox(width: 8),
              Text(
                'Bilan des douleurs & flux',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Double bloc Douleur & Flux
          Row(
            children: [
              // Bloc Douleur EVA
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF8FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Douleur menstruelle',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasPainData ? '${metrics.averagePain.toStringAsFixed(1)} / 10' : 'Non notée',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: hasPainData ? painColor : AppTheme.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasPainData ? painVerdict : 'Aucune saisie de crampes',
                        style: TextStyle(fontSize: 10, color: hasPainData ? painColor : AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasPainData) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Pic le plus fréquent : J${metrics.peakPainDay}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Bloc Pic Max de douleur
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF8FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Douleur maximale',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasPainData ? '${metrics.maxPain} / 10' : '--',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: metrics.maxPain >= 7 ? Colors.red : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        metrics.maxPain >= 7 ? 'Pic élevé enregistré' : 'Dans les normes tolérées',
                        style: TextStyle(fontSize: 10, color: metrics.maxPain >= 7 ? Colors.red : AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasPainData) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${metrics.totalPainDays} jour(s) noté(s)',
                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Répartition des intensités de flux
          const Text(
            'Répartition de l\'intensité des flux',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 10),

          if (!hasFlowData)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: const Center(
                child: Text(
                  'Consignez votre flux dans le journal pour afficher votre profil d\'intensité.',
                  style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else ...[
            _buildFlowDistributionRow(
              label: 'Spotting (très léger)',
              count: metrics.flowCounts['spotting'] ?? 0,
              total: metrics.totalFlowDays,
              color: const Color(0xFFFFAB91),
            ),
            const SizedBox(height: 6),
            _buildFlowDistributionRow(
              label: 'Flux léger',
              count: metrics.flowCounts['leger'] ?? 0,
              total: metrics.totalFlowDays,
              color: const Color(0xFFEF9A9A),
            ),
            const SizedBox(height: 6),
            _buildFlowDistributionRow(
              label: 'Flux moyen',
              count: metrics.flowCounts['moyen'] ?? 0,
              total: metrics.totalFlowDays,
              color: AppTheme.periodColor,
            ),
            const SizedBox(height: 6),
            _buildFlowDistributionRow(
              label: 'Flux abondant',
              count: metrics.flowCounts['abondant'] ?? 0,
              total: metrics.totalFlowDays,
              color: const Color(0xFF880E4F),
            ),
          ],

          // Alerte bienveillante dysménorrhée si douleur fréquente >= 7
          if (metrics.maxPain >= 7) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Des douleurs ≥ 7/10 ont été relevées. Si ces crampes entravent vos activités quotidiennes, pensez à les partager avec votre médecin pour explorer des solutions douces ou un bilan ciblé.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB71C1C), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlowDistributionRow({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final ratio = total > 0 ? (count / total) : 0.0;
    final percent = (ratio * 100).toInt();

    return Row(
      children: [
        SizedBox(
          width: 115,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textDark, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 7,
              child: Stack(
                children: [
                  Container(color: Colors.grey.shade200),
                  FractionallySizedBox(
                    widthFactor: ratio.clamp(0.0, 1.0),
                    child: Container(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 48,
          child: Text(
            '$count j ($percent%)',
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // 6. Découpage moyen des 4 phases physiologiques du cycle
  Widget _buildPhasesBreakdownCard(_FilteredStatsData data) {
    final totalDays = data.averageDuration.round().clamp(20, 45);
    final reglesDays = data.averagePeriodDuration.round().clamp(2, 8);
    final ovDay = (totalDays - 14).clamp(reglesDays + 2, totalDays - 8);
    final folliDays = (ovDay - 5 - reglesDays).clamp(1, 15);
    const fertDays = 6;
    final lutealDays = (totalDays - (reglesDays + folliDays + fertDays)).clamp(10, 16);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_rounded, size: 20, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Les 4 phases de votre cycle type',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                ],
              ),
              Text(
                '~$totalDays j',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Barre segmentée continue
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(flex: reglesDays, child: Container(color: AppTheme.periodColor)),
                  const SizedBox(width: 2),
                  Expanded(flex: folliDays, child: Container(color: Colors.purple.shade400)),
                  const SizedBox(width: 2),
                  Expanded(flex: fertDays, child: Container(color: AppTheme.accentRose)),
                  const SizedBox(width: 2),
                  Expanded(flex: lutealDays, child: Container(color: Colors.indigo.shade400)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4 Phases avec détails
          _buildPhaseLegendTile(
            color: AppTheme.periodColor,
            name: 'Phase menstruelle',
            days: 'J1 à J$reglesDays (~$reglesDays j)',
            hormones: 'Desquamation • Repos & vitalité introspective',
          ),
          const SizedBox(height: 8),
          _buildPhaseLegendTile(
            color: Colors.purple.shade400,
            name: 'Phase folliculaire',
            days: 'J${reglesDays + 1} à J${reglesDays + folliDays} (~$folliDays j)',
            hormones: 'Montée des œstrogènes • Énergie ascendante',
          ),
          const SizedBox(height: 8),
          _buildPhaseLegendTile(
            color: AppTheme.accentRose,
            name: 'Fenêtre fertile & Ovulation',
            days: 'J${ovDay - 5} à J$ovDay (Pic J$ovDay)',
            hormones: 'Pic de LH • Fertilité & réceptivité maximale',
          ),
          const SizedBox(height: 8),
          _buildPhaseLegendTile(
            color: Colors.indigo.shade400,
            name: 'Phase lutéale',
            days: 'J${ovDay + 1} à J$totalDays (~$lutealDays j)',
            hormones: 'Sécrétion de progestérone • Sérénité & préparation',
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseLegendTile({
    required Color color,
    required String name,
    required String days,
    required String hormones,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    days,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(hormones, style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  // 7. Bannière dynamique selon l'Objectif de l'utilisatrice
  Widget _buildObjectiveInsightCard(_FilteredStatsData data) {
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
        title = 'Stabilité de la phase lutéale & Fertilité';
        description =
            'Votre cycle moyen de ${data.averageDuration.toStringAsFixed(1)} jours situe votre pic ovulatoire régulier vers le Jour ${(data.averageDuration - 14).round()}. Une phase lutéale stable de ~14 jours est un atout idéal pour favoriser la nidation.';
        icon = Icons.favorite_rounded;
        color = AppTheme.accentRose;
        break;

      case 'eviter_grossesse':
      case 'contraception_naturelle':
        tag = 'MÉTHODE NATURELLE';
        title = 'Marge statistique & Période d\'attention';
        description =
            'Avec un écart-type de ± ${data.standardDeviation.toStringAsFixed(1)} jour(s), appliquez une marge de sécurité minimale de 6 jours avant l\'ovulation théorique. Les auto-observations (glaire cervicale) priment toujours sur le calendrier.';
        icon = Icons.shield_rounded;
        color = Colors.teal.shade700;
        break;

      case 'comprendre_corps':
        tag = 'BIORHYTHME HORMONAL';
        title = 'Synchronisation aux 4 saisons intérieures';
        description =
            'Vos ${data.completedCount} cycles analysés démontrent une belle réactivité physiologique. Vos phases d\'énergie maximale coïncident avec la montée des œstrogènes précédant l\'ovulation.';
        icon = Icons.auto_awesome_rounded;
        color = Colors.purple.shade700;
        break;

      case 'suivi_cycle':
      default:
        tag = 'ÉQUILIBRE & RÉGULARITÉ';
        title = 'Constat biométrique général';
        description =
            'Vos cycles oscillent entre ${data.minDuration} et ${data.maxDuration} jours. Cette fourchette est en parfait accord avec les recommandations internationales de santé féminine (norme FIGO : 24 à 38 jours).';
        icon = Icons.calendar_today_rounded;
        color = AppTheme.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: color),
                    const SizedBox(width: 4),
                    Text(
                      tag,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Adapté au profil',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 12, color: AppTheme.textDark, height: 1.4)),
        ],
      ),
    );
  }

  // 8. Carte d'invitation au Bilan Médical
  Widget _buildDoctorExportCard(CycleStatsModel? stats, List<CycleModel> allCycles) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medical_services_rounded, color: Colors.teal, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bilan pour consultation médicale',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Générez un compte-rendu synthétique à partager avec votre gynécologue ou sage-femme.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.3),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _openMedicalSummary(stats, allCycles),
                  borderRadius: BorderRadius.circular(8),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ouvrir mon bilan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.teal),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 9. Note médicale & explications pédagogiques
  Widget _buildMedicalExplanationCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      surfaceColor: AppTheme.primaryLight.withValues(alpha: 0.55),
      customBorder: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: AppTheme.primary, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comprendre vos variations',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                SizedBox(height: 4),
                Text(
                  'Il est tout à fait naturel pour un cycle féminin de fluctuer de 2 à 4 jours d\'un mois à l\'autre sous l\'effet du sommeil, de l\'alimentation ou du stress. Le moteur de calcul ajuste continuellement votre fenêtre de fertilité en tenant compte de cette marge statistique.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textDark, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
}
