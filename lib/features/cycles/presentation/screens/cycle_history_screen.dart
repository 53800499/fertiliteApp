import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/cycle_models.dart';
import '../bloc/cycle_bloc.dart';
import '../bloc/cycle_event.dart';
import '../bloc/cycle_state.dart';
import '../widgets/log_flow_bottom_sheet.dart';
import '../widgets/edit_cycle_bottom_sheet.dart';
import '../../../../core/network/network_cubit.dart';
import '../../../../core/widgets/offline_state_view.dart';
import '../../../../core/widgets/modern_app_header.dart';
import '../../../../core/error/error_feedback.dart';

class CycleHistoryScreen extends StatefulWidget {
  const CycleHistoryScreen({super.key});

  @override
  State<CycleHistoryScreen> createState() => _CycleHistoryScreenState();
}

class _CycleHistoryScreenState extends State<CycleHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CycleBloc>().add(LoadCyclesEvent());
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
        subtitle: 'Suivi temporel',
        title: 'Historique des Cycles',
        onRefresh: () => context.read<CycleBloc>().add(LoadCyclesEvent()),
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
                onRetry: () => context.read<CycleBloc>().add(LoadCyclesEvent()),
              );
            }

            return AppErrorEmptyView(
              error: state.message,
              onRetry: () => context.read<CycleBloc>().add(LoadCyclesEvent()),
            );
          }

          final cycles = state is CyclesLoadedState ? state.cycles : <CycleModel>[];

          if (cycles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history_rounded, size: 48, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Aucun cycle enregistré',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Commencez par déclarer le premier jour de vos règles pour amorcer votre historique menstruel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        LogFlowBottomSheet.show(context, date: DateTime.now());
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Déclarer mes règles'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Calculs statistiques rapides
          final completedCycles = cycles.where((c) => c.dureeCycleJours != null).toList();
          double avgCycleLength = 28.0;
          if (completedCycles.isNotEmpty) {
            final total = completedCycles.fold<int>(0, (sum, c) => sum + (c.dureeCycleJours ?? 28));
            avgCycleLength = total / completedCycles.length;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Carte de Synthèse statistique
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.softHeroGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.floatingShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Cycles saisis', '${cycles.length}', Icons.repeat_rounded),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildStatColumn('Durée moyenne', '${avgCycleLength.toStringAsFixed(1)} j', Icons.timelapse_rounded),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildStatColumn('Régularité', 'Bonne', Icons.auto_graph_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Tous vos cycles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 12),

                // Liste chronologique des cycles
                ...cycles.map((cycle) => _buildCycleCard(cycle)),
                const SizedBox(height: 90),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.white70)),
      ],
    );
  }

  Widget _buildCycleCard(CycleModel cycle) {
    final isEnCours = cycle.isEnCours;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isEnCours ? AppTheme.primary : AppTheme.borderLight, width: isEnCours ? 1.5 : 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isEnCours ? Colors.teal : AppTheme.primary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isEnCours ? 'Cycle en cours' : 'Cycle terminé',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isEnCours ? Colors.teal : AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (cycle.dureeCycleJours != null)
                    Text(
                      '${cycle.dureeCycleJours} jours',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${cycle.joursRegles.length} jours de règles',
                    style: const TextStyle(fontSize: 11.5, color: AppTheme.periodColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textMuted),
                    onPressed: () => EditCycleBottomSheet.show(context, cycle: cycle),
                    tooltip: 'Modifier les dates',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dates début et fin
          Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Text(
                'Du ${cycle.dateDebut} ${cycle.dateFin != null ? "au ${cycle.dateFin}" : "(en cours)"}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Aperçu des flux enregistrés
          if (cycle.joursRegles.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: cycle.joursRegles.map((j) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.water_drop_rounded, size: 11, color: AppTheme.periodColor),
                      const SizedBox(width: 4),
                      Text('${j.date.substring(5)} : ${j.intensiteFlux}', style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
