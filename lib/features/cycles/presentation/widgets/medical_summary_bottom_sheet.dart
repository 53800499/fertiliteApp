import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../data/models/cycle_models.dart';
import '../../../users/data/models/user_profile_model.dart';

class MedicalSummaryBottomSheet extends StatelessWidget {
  final CycleStatsModel? stats;
  final List<CycleModel> cycles;
  final FullUserProfileModel? userProfile;

  const MedicalSummaryBottomSheet({
    super.key,
    required this.stats,
    required this.cycles,
    this.userProfile,
  });

  static Future<void> show(
    BuildContext context, {
    required CycleStatsModel? stats,
    required List<CycleModel> cycles,
    FullUserProfileModel? userProfile,
    bool useRootNavigator = true,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: useRootNavigator,
      backgroundColor: Colors.transparent,
      builder: (_) => MedicalSummaryBottomSheet(
        stats: stats,
        cycles: cycles,
        userProfile: userProfile,
      ),
    );
  }

  static const _moisFr = [
    '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  String _formatDate(DateTime d) => '${d.day} ${_moisFr[d.month]} ${d.year}';

  String _formatShortDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return '${d.day}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return raw;
    }
  }

  int? _getMaxPain(List<JourReglesModel> jours) {
    int? max;
    for (final j in jours) {
      if (j.douleurNiveau != null) {
        if (max == null || j.douleurNiveau! > max) {
          max = j.douleurNiveau;
        }
      }
    }
    return max;
  }

  double _getAveragePain(List<CycleModel> completedCycles) {
    final pains = <int>[];
    for (final c in completedCycles) {
      for (final j in c.joursRegles) {
        if (j.douleurNiveau != null && j.douleurNiveau! > 0) {
          pains.add(j.douleurNiveau!);
        }
      }
    }
    if (pains.isEmpty) return 0.0;
    return pains.reduce((a, b) => a + b) / pains.length;
  }

  String _generateClinicalText(List<CycleModel> completedCycles, double avgPain) {
    final now = DateTime.now();
    final buffer = StringBuffer();
    buffer.writeln('📋 BILAN MÉDICAL DU CYCLE MENSTRUEL (Relevé FEMAX)');
    buffer.writeln('Date de génération : ${_formatDate(now)}');
    if (userProfile?.profil.prenom != null && userProfile!.profil.prenom!.isNotEmpty) {
      buffer.writeln('Patiente : ${userProfile!.profil.prenom}');
    }
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('📊 SYNTHÈSE BIOMÉTRIQUE :');
    buffer.writeln('• Cycles analysés : ${completedCycles.length}');
    buffer.writeln('• Durée moyenne des cycles : ${stats?.averageDuration.toStringAsFixed(1) ?? "--"} jours (Norme FIGO : 24 - 38 j)');
    buffer.writeln('• Écart-type (variabilité) : ± ${stats?.standardDeviation.toStringAsFixed(1) ?? "--"} jours');
    buffer.writeln('• Indice de régularité : ${stats?.regularityLabel ?? "Indéterminé"}');
    buffer.writeln('• Durée moyenne des règles : ${stats?.averagePeriodDuration.toStringAsFixed(1) ?? "--"} jours');
    buffer.writeln('• Amplitude observée : min ${stats?.minDuration ?? "--"} j / max ${stats?.maxDuration ?? "--"} j');
    if (avgPain > 0) {
      buffer.writeln('• Douleur menstruelle moyenne (EVA 0-10) : ${avgPain.toStringAsFixed(1)} / 10');
    }
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('🗓️ HISTORIQUE RÉCENT DES CYCLES :');

    for (int i = 0; i < completedCycles.length; i++) {
      final c = completedCycles[i];
      final maxP = _getMaxPain(c.joursRegles);
      final painStr = maxP != null ? ' | Douleur max: $maxP/10' : '';
      buffer.writeln(
        '${i + 1}. Début : ${_formatShortDate(c.dateDebut)} | Durée : ${c.dureeCycleJours ?? "--"} j | Règles : ${c.dureeReglesJours ?? c.joursRegles.length} j$painStr',
      );
    }
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('ℹ️ Relevé physiologique d\'auto-observation partagé pour faciliter l\'anamnèse.');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final completedCycles = cycles.where((c) => !c.isEnCours && c.dureeCycleJours != null).toList();
    final avgPain = _getAveragePain(completedCycles);
    final isReliable = (stats?.completedCycles ?? 0) >= 2;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
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
                    color: Colors.teal.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medical_services_rounded, color: Colors.teal, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bilan pour consultation',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Synthèse gynécologique & biométrique',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bandeau identité & date
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProfile?.profil.prenom != null && userProfile!.profil.prenom!.isNotEmpty
                                  ? userProfile!.profil.prenom!
                                  : 'Dossier Personnel',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Généré le ${_formatDate(DateTime.now())}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${completedCycles.length} cycles',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Synthèse des 4 paramètres clés
                  const Text(
                    'Paramètres cliniques observés',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricBox(
                          label: 'Durée moyenne',
                          value: '${stats?.averageDuration.toStringAsFixed(1) ?? "28.0"} j',
                          norm: 'Norme : 24 - 38 j',
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricBox(
                          label: 'Variabilité (±)',
                          value: isReliable ? '± ${stats?.standardDeviation.toStringAsFixed(1)} j' : '--',
                          norm: 'Stabilité cycle',
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricBox(
                          label: 'Durée des règles',
                          value: '${stats?.averagePeriodDuration.toStringAsFixed(1) ?? "5.0"} j',
                          norm: 'Norme : 3 - 7 j',
                          color: AppTheme.periodColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricBox(
                          label: 'Douleur moyenne',
                          value: avgPain > 0 ? '${avgPain.toStringAsFixed(1)} / 10' : 'Non notée',
                          norm: 'Échelle EVA',
                          color: avgPain >= 6 ? Colors.red : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Tableau chronologique des cycles récents
                  const Text(
                    'Historique chronologique des cycles',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 10),
                  if (completedCycles.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: const Center(
                        child: Text(
                          'Aucun cycle clôturé à afficher dans le bilan.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: [
                            Container(
                              color: const Color(0xFFF7F8FA),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: const Row(
                                children: [
                                  Expanded(flex: 3, child: Text('Date début', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                                  Expanded(flex: 2, child: Text('Durée', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted), textAlign: TextAlign.center)),
                                  Expanded(flex: 2, child: Text('Règles', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted), textAlign: TextAlign.center)),
                                  Expanded(flex: 2, child: Text('Douleur', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted), textAlign: TextAlign.right)),
                                ],
                              ),
                            ),
                            ...completedCycles.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final cycle = entry.value;
                              final maxPain = _getMaxPain(cycle.joursRegles);
                              final isOdd = idx % 2 == 1;

                              return Container(
                                color: isOdd ? const Color(0xFFFAFAFA) : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        _formatShortDate(cycle.dateDebut),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${cycle.dureeCycleJours ?? "--"} j',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${cycle.dureeReglesJours ?? cycle.joursRegles.length} j',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.periodColor, fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        maxPain != null ? '$maxPain/10' : '--',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: maxPain != null && maxPain >= 6 ? Colors.red : Colors.grey.shade700,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),

                  // 3. Note déontologique médicale
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: Colors.amber),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ce relevé est un historique d\'auto-observation indicatif. Il a pour vocation de faciliter la communication avec votre praticien de santé et ne constitue pas un diagnostic médical.',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF6D4C41), height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Actions
                  ElevatedButton.icon(
                    onPressed: () async {
                      final text = _generateClinicalText(completedCycles, avgPain);
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) {
                        AppFeedback.showSuccess(
                          context,
                          title: 'Bilan médical copié ✨',
                          message: 'Le compte-rendu a été copié dans votre presse-papier.',
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copier le compte-rendu textuel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textDark,
                      side: const BorderSide(color: AppTheme.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required String norm,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(norm, style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
