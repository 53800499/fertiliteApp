import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/fertility_bloc.dart';
import '../../data/models/fertility_models.dart';

class FertilityExplanationBottomSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
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

          // En-tête
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comprendre mon estimation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'Explications médicales & facteurs d’influence',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
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
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                if (state is FertilityFailureState) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(state.message, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context
                                .read<FertilityBloc>()
                                .add(const LoadCurrentFertilityEvent()),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
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
                      // 1. Carte Score & Jauge
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

  Widget _buildScoreGaugeCard(PredictionModel prediction) {
    Color categoryColor = Colors.grey;
    String categoryLabel = 'Probabilité faible';

    if (prediction.fertilityCategory == 'elevee') {
      categoryColor = AppTheme.accentRose;
      categoryLabel = 'Probabilité élevée';
    } else if (prediction.fertilityCategory == 'moyenne') {
      categoryColor = Colors.orange;
      categoryLabel = 'Probabilité moyenne';
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Score continu : ${prediction.fertilityScoreValue.toStringAsFixed(1)} / 100',
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                  ),
                ],
              ),
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
                  'Ovulation estimée',
                  _formatDate(prediction.estimatedOvulationDate),
                  Icons.egg_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: _buildMetricChip(
                  'Fenêtre fertile',
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
    String label = 'Confiance moyenne';
    Color color = Colors.orange;
    String tip =
      'Basée sur un historique partiel de vos cycles. Continuez vos saisies pour affiner la prédiction.';

    if (prediction.confidenceLevel == 'eleve') {
      label = 'Confiance élevée';
      color = Colors.teal;
      tip =
        'Vos cycles présentent une forte régularité statistique confirmée par vos observations.';
    } else if (prediction.confidenceLevel == 'faible') {
      label = 'Confiance indicative';
      color = Colors.deepOrange;
      tip =
        'Historique encore jeune ou variabilité constatée. La fenêtre est élargie par précaution.';
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.shield_outlined, size: 18, color: AppTheme.textMuted),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Avertissement médical : Cette estimation repose sur des règles physiologiques et statistiques. Elle ne garantit jamais la survenue d’une grossesse et ne constitue pas une méthode de contraception ni un diagnostic médical.',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
