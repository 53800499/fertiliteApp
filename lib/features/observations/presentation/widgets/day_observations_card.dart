import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/observation_models.dart';
import 'observation_entry_bottom_sheet.dart';

class DayObservationsCard extends StatelessWidget {
  final DateTime date;
  final DayObservationsModel? observations;
  final List<TypeSymptomeModel> catalog;

  const DayObservationsCard({
    super.key,
    required this.date,
    this.observations,
    this.catalog = const [],
  });

  @override
  Widget build(BuildContext context) {
    final obs = observations;
    final hasData = obs != null && obs.hasObservations;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.biotech_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Biomarqueurs & Symptômes',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  ObservationEntryBottomSheet.show(
                    context,
                    date: date,
                    existingObservations: obs,
                    catalog: catalog,
                  );
                },
                icon: Icon(
                  hasData ? Icons.edit_outlined : Icons.add_circle_outline_rounded,
                  size: 16,
                  color: AppTheme.primary,
                ),
                label: Text(
                  hasData ? 'Modifier' : 'Ajouter',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasData) ...[
            Text(
              'Ajoutez votre température, texture de glaire, test LH ou ressentis pour affiner vos prédictions.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Température
                if (obs.temperature != null)
                  _buildPill(
                    icon: Icons.thermostat_rounded,
                    label: obs.temperature!.formattedTemp,
                    color: obs.temperature!.estPerturbee ? Colors.orange : Colors.indigo,
                    subtitle: obs.temperature!.estPerturbee ? 'Perturbée' : null,
                  ),

                // Glaire cervicale
                if (obs.glaire != null)
                  _buildPill(
                    icon: Icons.water_drop_rounded,
                    label: obs.glaire!.label,
                    color: obs.glaire!.isFertile ? Colors.teal : Colors.blueGrey,
                    badge: obs.glaire!.isFertile ? 'Fertile' : null,
                  ),

                // Test LH
                if (obs.testsLh.isNotEmpty)
                  _buildPill(
                    icon: Icons.science_outlined,
                    label: 'LH: ${obs.testsLh.first.label}',
                    color: obs.testsLh.first.isPeak ? Colors.purple : Colors.blue,
                  ),
              ],
            ),
            if (obs.symptomes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Symptômes déclarés :',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: obs.symptomes.map((s) {
                  return Chip(
                    backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.6),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      '${s.displayName} (${s.intensite}/5)',
                      style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color color,
    String? subtitle,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(width: 4),
            Text(
              '($subtitle)',
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
            ),
          ],
        ],
      ),
    );
  }
}
