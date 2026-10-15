import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/cycle_models.dart';
import '../bloc/cycle_bloc.dart';
import '../bloc/cycle_event.dart';
import '../../../../core/network/network_cubit.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_feedback.dart';

class LogFlowBottomSheet extends StatefulWidget {
  final DateTime initialDate;
  final JourReglesModel? existingJour;

  const LogFlowBottomSheet({
    super.key,
    required this.initialDate,
    this.existingJour,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    JourReglesModel? existingJour,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CycleBloc>(),
        child: LogFlowBottomSheet(
          initialDate: date,
          existingJour: existingJour,
        ),
      ),
    );
  }

  @override
  State<LogFlowBottomSheet> createState() => _LogFlowBottomSheetState();
}

class _LogFlowBottomSheetState extends State<LogFlowBottomSheet> {
  late DateTime _selectedDate;
  late String _intensite;
  late int _douleur;
  final _notesController = TextEditingController();
  bool _isNewCycleStart = false;

  final List<Map<String, dynamic>> _intensities = [
    {'key': 'absent', 'label': 'Aucun', 'drops': 0, 'color': Colors.grey},
    {'key': 'spotting', 'label': 'Spotting', 'drops': 1, 'color': Color(0xFFFFAB91)},
    {'key': 'leger', 'label': 'Léger', 'drops': 2, 'color': Color(0xFFEF9A9A)},
    {'key': 'moyen', 'label': 'Moyen', 'drops': 3, 'color': Color(0xFFE57373)},
    {'key': 'abondant', 'label': 'Abondant', 'drops': 4, 'color': Color(0xFFD32F2F)},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _intensite = widget.existingJour?.intensiteFlux ?? 'moyen';
    _douleur = widget.existingJour?.douleurNiveau ?? 0;
    _notesController.text = widget.existingJour?.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    bool isOnline = true;
    try {
      isOnline = BlocProvider.of<NetworkCubit>(context, listen: false).state.isOnline;
    } catch (_) {}
    if (!isOnline) {
      AppErrorFeedback.showSnackBar(
        context,
        error: const ApiException(
          title: 'Mode hors ligne',
          userFriendlyMessage:
              'Une connexion Internet est requise pour enregistrer et synchroniser un nouveau cycle ou une saisie de flux.',
          actionSuggestion: 'Veuillez vous reconnecter au réseau avant d\'enregistrer.',
          errorCode: 'NETWORK_OFFLINE',
        ),
      );
      return;
    }

    final dateStr =
        "${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    if (_isNewCycleStart) {
      // Début d'un nouveau cycle (UC-07)
      context.read<CycleBloc>().add(
            StartNewCycleEvent(
              StartCycleRequestModel(
                dateDebut: dateStr,
                intensiteFlux: _intensite,
                douleurNiveau: _douleur,
                notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
              ),
            ),
          );
    } else {
      // Saisie de flux ordinaire (UC-08)
      context.read<CycleBloc>().add(
            LogDayFlowEvent(
              LogFlowRequestModel(
                date: dateStr,
                intensiteFlux: _intensite,
                douleurNiveau: _douleur,
                notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
              ),
            ),
          );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isNewCycleStart ? 'Nouveau cycle démarré avec succès !' : 'Observations enregistrées.'),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barre de saisie supérieure
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date & Titre
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saisie du flux menstruel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(height: 2),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRoseLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.water_drop_rounded, color: AppTheme.accentRose, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bannière bienveillante d'écoute du corps avec illustration naturelle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/woman_wellness_natural.jpg',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 44,
                        height: 44,
                        color: AppTheme.primaryLight,
                        child: const Icon(Icons.spa_rounded, color: AppTheme.primary, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Prenez un instant pour vous : notez vos ressentis sans jugement ni pression.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 1. Sélecteur d'intensité du flux (5 pilules)
            const Text('Intensité des saignements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            Row(
              children: _intensities.map((item) {
                final key = item['key'] as String;
                final isSelected = _intensite == key;
                final color = item['color'] as Color;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _intensite = key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? color : AppTheme.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : AppTheme.borderLight,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            key == 'absent' ? Icons.block_rounded : Icons.water_drop_rounded,
                            size: 18,
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // 2. Échelle de douleur (0 à 10)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Intensité des douleurs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textDark)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getPainColor(_douleur).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_douleur/10 • ${_getPainLabel(_douleur)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getPainColor(_douleur)),
                  ),
                ),
              ],
            ),
            Slider(
              value: _douleur.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              activeColor: _getPainColor(_douleur),
              onChanged: (v) => setState(() => _douleur = v.round()),
            ),
            const SizedBox(height: 12),

            // 3. Option : Déclarer comme début de nouveau cycle (UC-07)
            InkWell(
              onTap: () => setState(() => _isNewCycleStart = !_isNewCycleStart),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isNewCycleStart ? AppTheme.primaryLight : AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _isNewCycleStart ? AppTheme.primary : AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isNewCycleStart ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: _isNewCycleStart ? AppTheme.primary : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mes règles ont commencé ce jour (J1)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                          Text('Clôture le cycle précédent et amorce un nouveau cycle menstruel.', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Notes personnelles
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes ou ressentis (optionnel)',
                hintText: 'Ex: Fatigue, tiraillements légers, migraine...',
                prefixIcon: Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 20),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 22),

            // Bouton Enregistrer
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.floatingShadow,
              ),
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Enregistrer les observations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPainColor(int score) {
    if (score == 0) return Colors.teal;
    if (score <= 3) return Colors.lightGreen.shade700;
    if (score <= 6) return Colors.amber.shade800;
    return Colors.red.shade700;
  }

  String _getPainLabel(int score) {
    if (score == 0) return 'Aucune';
    if (score <= 3) return 'Légère';
    if (score <= 6) return 'Modérée';
    return 'Intense';
  }
}
