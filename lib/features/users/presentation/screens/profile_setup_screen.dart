import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/user_profile_model.dart';

class ProfileSetupScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const ProfileSetupScreen({super.key, this.onCompleted});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _prenomController = TextEditingController();
  int _cycleDuration = 28;
  int _flowDuration = 5;
  String _objective = 'concevoir';
  bool _irregular = false;
  DateTime? _lastPeriodDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _prenomController.dispose();
    super.dispose();
  }

  Future<void> _pickLastPeriodDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodDate ?? now.subtract(const Duration(days: 14)),
      firstDate: now.subtract(const Duration(days: 90)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _lastPeriodDate = picked);
    }
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isSaving = true);
    try {
      final req = UpdateProfileRequestModel(
        prenom: _prenomController.text.trim().isNotEmpty ? _prenomController.text.trim() : null,
        dureeMoyenneCycle: _cycleDuration,
        dureeMoyenneRegles: _flowDuration,
        objectifPrincipal: _objective,
        irregulariteDeclaree: _irregular,
      );

      await ServiceLocator.userRepository.updateProfile(req);

      if (mounted) {
        if (widget.onCompleted != null) {
          widget.onCompleted!();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Assistant de cycle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textDark),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête
                const Text(
                  'Personnalisons votre cycle',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ces repères permettent d\'amorcer vos prédictions physiologiques avec précision.',
                  style: TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 24),

                // 1. Prénom
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Comment vous appeler ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _prenomController,
                        decoration: const InputDecoration(
                          hintText: 'Votre prénom ou pseudo',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Objectif principal
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Votre objectif principal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
                      const SizedBox(height: 14),
                      _buildObjectiveTile('concevoir', 'Concevoir un enfant', 'Identifier vos jours les plus favorables', Icons.child_care_rounded),
                      const SizedBox(height: 10),
                      _buildObjectiveTile('suivre_cycle', 'Suivre mon cycle sans projet', 'Prévoir vos règles et comprendre vos symptômes', Icons.calendar_today_rounded),
                      const SizedBox(height: 10),
                      _buildObjectiveTile('contraception_naturelle', 'Observation & Méthode naturelle', 'Comprendre les signaux corporels sans pression', Icons.spa_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Durées physiologiques
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vos repères habituels', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
                      const SizedBox(height: 16),

                      // Durée du cycle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Durée du cycle', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppTheme.textDark)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('$_cycleDuration jours', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13)),
                          ),
                        ],
                      ),
                      Slider(
                        value: _cycleDuration.toDouble(),
                        min: 20,
                        max: 45,
                        divisions: 25,
                        activeColor: AppTheme.primary,
                        onChanged: (v) => setState(() => _cycleDuration = v.round()),
                      ),
                      const SizedBox(height: 12),

                      // Durée des règles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Durée des règles', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppTheme.textDark)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentRoseLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('$_flowDuration jours', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentRose, fontSize: 13)),
                          ),
                        ],
                      ),
                      Slider(
                        value: _flowDuration.toDouble(),
                        min: 2,
                        max: 10,
                        divisions: 8,
                        activeColor: AppTheme.accentRose,
                        onChanged: (v) => setState(() => _flowDuration = v.round()),
                      ),
                      const SizedBox(height: 10),

                      // Régularité
                      InkWell(
                        onTap: () => setState(() => _irregular = !_irregular),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _irregular ? Colors.amber.shade50 : AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _irregular ? Colors.amber.shade300 : AppTheme.borderLight),
                          ),
                          child: Row(
                            children: [
                              Icon(_irregular ? Icons.shuffle_rounded : Icons.check_circle_outline_rounded,
                                  color: _irregular ? Colors.amber.shade800 : AppTheme.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _irregular ? 'Cycles irréguliers déclarés (marge de sécurité accrue)' : 'Cycles généralement réguliers',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _irregular ? Colors.amber.shade900 : AppTheme.textDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Date des dernières règles
                InkWell(
                  onTap: _pickLastPeriodDate,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.periodColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.water_drop_rounded, color: AppTheme.periodColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Premier jour des dernières règles', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              const SizedBox(height: 2),
                              Text(
                                _lastPeriodDate == null
                                    ? 'Sélectionner la date (optionnel)'
                                    : '${_lastPeriodDate!.day.toString().padLeft(2, '0')}/${_lastPeriodDate!.month.toString().padLeft(2, '0')}/${_lastPeriodDate!.year}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _lastPeriodDate == null ? AppTheme.textLight : AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Bouton de validation
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.floatingShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Enregistrer et accéder au tableau de bord', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildObjectiveTile(String key, String title, String subtitle, IconData icon) {
    final isSelected = _objective == key;

    return InkWell(
      onTap: () => setState(() => _objective = key),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : AppTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.borderLight,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppTheme.textMuted, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isSelected ? AppTheme.primaryDark : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
