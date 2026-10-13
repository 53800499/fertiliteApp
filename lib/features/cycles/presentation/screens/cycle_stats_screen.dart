import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/cycle_models.dart';
import '../bloc/cycle_bloc.dart';
import '../bloc/cycle_event.dart';
import '../bloc/cycle_state.dart';
import '../../../../core/network/network_cubit.dart';
import '../../../../core/widgets/offline_state_view.dart';
import '../../../../core/widgets/offline_badge_chip.dart';
import '../../../../core/widgets/modern_app_header.dart';
import '../../../../core/error/error_feedback.dart';

class CycleStatsScreen extends StatefulWidget {
  const CycleStatsScreen({super.key});

  @override
  State<CycleStatsScreen> createState() => _CycleStatsScreenState();
}

class _CycleStatsScreenState extends State<CycleStatsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CycleBloc>().add(LoadCycleStatsEvent());
  }

  bool _isOffline(BuildContext context) {
    try {
      return !BlocProvider.of<NetworkCubit>(context).state.isOnline;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: ModernAppHeader(
        subtitle: 'Biométrie & Régularité',
        title: 'Statistiques & Régularité',
        onRefresh: () {
          context.read<CycleBloc>().add(LoadCycleStatsEvent());
          context.read<CycleBloc>().add(LoadCyclesEvent());
        },
      ),
      body: BlocBuilder<CycleBloc, CycleState>(
        builder: (context, state) {
          if (state is CycleLoadingState) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (state is CycleFailureState) {
            final isOffline = _isOffline(context) ||
                state.message.toLowerCase().contains('connexion') ||
                state.message.toLowerCase().contains('hors ligne') ||
                state.message.toLowerCase().contains('socketexception') ||
                state.message.toLowerCase().contains('failed host lookup');

            if (isOffline) {
              return OfflineStateView(
                onRetry: () {
                  context.read<CycleBloc>().add(LoadCycleStatsEvent());
                  context.read<CycleBloc>().add(LoadCyclesEvent());
                },
              );
            }

            return AppErrorEmptyView(
              error: state.message,
              onRetry: () {
                context.read<CycleBloc>().add(LoadCycleStatsEvent());
                context.read<CycleBloc>().add(LoadCyclesEvent());
              },
            );
          }

          final loaded = state is CyclesLoadedState ? state : null;
          final stats = loaded?.stats;
          final cycles = loaded?.cycles ?? [];

          if (stats == null && cycles.isEmpty && _isOffline(context)) {
            return OfflineStateView(
              onRetry: () {
                context.read<CycleBloc>().add(LoadCycleStatsEvent());
                context.read<CycleBloc>().add(LoadCyclesEvent());
              },
            );
          }

          return SingleChildScrollView(
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

                // 1. Hero Card : Synthèse de la régularité
                _buildHeroRegularityCard(stats),
                const SizedBox(height: 20),

                // 2. Grille des 4 indicateurs biométriques
                _buildMetricsGrid(stats),
                const SizedBox(height: 20),

                // 3. Histogramme des cycles récents
                _buildCycleLengthBarChart(stats, cycles),
                const SizedBox(height: 20),

                // 4. Note médicale & explications pédagogiques
                _buildMedicalExplanationCard(),
                const SizedBox(height: 90),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroRegularityCard(CycleStatsModel? stats) {
    final regularityLabel = stats?.regularityLabel ?? 'Analyse en cours';
    final isReliable = (stats?.completedCycles ?? 0) >= 2;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.softHeroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.floatingShadow,
      ),
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
                          isReliable ? 'Calcul basé sur vos cycles' : 'Données préliminaires',
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
              const Icon(Icons.auto_graph_rounded, color: Colors.white70, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Indice de régularité :',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            regularityLabel,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            isReliable
                ? 'Votre écart-type est de ± ${stats?.standardDeviation.toStringAsFixed(1)} jour(s). Une variation inférieure à 3 jours est un excellent signe d\'équilibre ovulatoire.'
                : 'Enregistrez au moins 2 cycles menstruels consécutifs pour une estimation précise de votre régularité biologique.',
            style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(CycleStatsModel? stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Durée moyenne',
                value: '${stats?.averageDuration.toStringAsFixed(1) ?? "28.0"} j',
                subtitle: 'Cycle typique',
                icon: Icons.timelapse_rounded,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricTile(
                title: 'Durée des règles',
                value: '${stats?.averagePeriodDuration.toStringAsFixed(1) ?? "5.0"} j',
                subtitle: 'Saignements',
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
                value: '${stats?.minDuration ?? 28} j',
                subtitle: 'Borne inférieure',
                icon: Icons.arrow_downward_rounded,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricTile(
                title: 'Cycle le plus long',
                value: '${stats?.maxDuration ?? 28} j',
                subtitle: 'Borne supérieure',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
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

  Widget _buildCycleLengthBarChart(CycleStatsModel? stats, List<CycleModel> cycles) {
    final history = stats?.history ?? [];
    final completedHistory = history.where((h) => h.dureeCycleJours != null).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Évolution des durées',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              Text(
                '${completedHistory.length} cycles analysés',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (completedHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    const Text(
                      'Aucun cycle clôturé à afficher',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 160,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: completedHistory.map((h) {
                      final duration = h.dureeCycleJours ?? 28;
                      // Hauteur normalisée : min 40px, max 130px
                      final barHeight = (duration / 40.0 * 120.0).clamp(30.0, 130.0);
                      final isNormal = duration >= 24 && duration <= 35;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$duration j',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isNormal ? AppTheme.primary : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 26,
                            height: barHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isNormal
                                    ? [AppTheme.primary, AppTheme.accentRose]
                                    : [Colors.orange, Colors.amber],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            h.dateDebut.length >= 7 ? h.dateDebut.substring(5, 7) : '',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        const Text('Normal (24-35 j)', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        const Text('Atypique (<24 ou >35 j)', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMedicalExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
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
