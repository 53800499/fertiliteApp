import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../fertility/presentation/bloc/fertility_bloc.dart';
import '../../data/models/user_profile_model.dart';

class ObjectiveInfo {
  final String key;
  final String title;
  final String shortLabel;
  final String subtitle;
  final String systemGuidance;
  final IconData icon;
  final Color color;

  const ObjectiveInfo({
    required this.key,
    required this.title,
    required this.shortLabel,
    required this.subtitle,
    required this.systemGuidance,
    required this.icon,
    required this.color,
  });
}

class ObjectiveHelper {
  static const Map<String, ObjectiveInfo> objectives = {
    'planifier_grossesse': ObjectiveInfo(
      key: 'planifier_grossesse',
      title: 'Concevoir un enfant',
      shortLabel: 'PROJET CONCEPTION',
      subtitle: 'Maximiser vos chances de fécondation',
      systemGuidance:
          'Vos prédictions ciblent votre jour d\'ovulation et valorisent votre fenêtre fertile maximale pour optimiser chaque cycle.',
      icon: Icons.child_care_rounded,
      color: AppTheme.accentRose,
    ),
    'concevoir': ObjectiveInfo(
      key: 'planifier_grossesse',
      title: 'Concevoir un enfant',
      shortLabel: 'PROJET CONCEPTION',
      subtitle: 'Maximiser vos chances de fécondation',
      systemGuidance:
          'Vos prédictions ciblent votre jour d\'ovulation et valorisent votre fenêtre fertile maximale pour optimiser chaque cycle.',
      icon: Icons.child_care_rounded,
      color: AppTheme.accentRose,
    ),
    'eviter_grossesse': ObjectiveInfo(
      key: 'eviter_grossesse',
      title: 'Observation & Méthode naturelle',
      shortLabel: 'MÉTHODE NATURELLE',
      subtitle: 'Identifier la période de précaution',
      systemGuidance:
          'Vos alertes identifient la zone de prudence fertile et vous guident sur l\'écoute fine de vos biomarqueurs corporels.',
      icon: Icons.shield_outlined,
      color: Colors.teal,
    ),
    'contraception_naturelle': ObjectiveInfo(
      key: 'eviter_grossesse',
      title: 'Observation & Méthode naturelle',
      shortLabel: 'MÉTHODE NATURELLE',
      subtitle: 'Identifier la période de précaution',
      systemGuidance:
          'Vos alertes identifient la zone de prudence fertile et vous guident sur l\'écoute fine de vos biomarqueurs corporels.',
      icon: Icons.shield_outlined,
      color: Colors.teal,
    ),
    'comprendre_corps': ObjectiveInfo(
      key: 'comprendre_corps',
      title: 'Comprendre mon corps & mes hormones',
      shortLabel: 'ÉCOUTE HORMONALE',
      subtitle: 'Décoder vos 4 saisons intérieures',
      systemGuidance:
          'Vos repères analysent vos 4 phases hormonales pour adapter naturellement votre rythme, votre énergie et votre bien-être.',
      icon: Icons.psychology_rounded,
      color: Color(0xFF8E24AA),
    ),
    'suivi_cycle': ObjectiveInfo(
      key: 'suivi_cycle',
      title: 'Suivre mon cycle & mes règles',
      shortLabel: 'SUIVI DU CYCLE',
      subtitle: 'Anticiper règles, durée et symptômes',
      systemGuidance:
          'Vos repères anticipent l\'arrivée de vos règles, la régularité de vos cycles et vous aident à mieux vivre le syndrome prémenstruel.',
      icon: Icons.calendar_today_rounded,
      color: AppTheme.primaryDark,
    ),
  };

  static ObjectiveInfo getInfo(String? key) {
    if (key == null) return objectives['suivi_cycle']!;
    return objectives[key] ?? objectives['suivi_cycle']!;
  }
}

/// Carte / Bannière élégante et interactive présentant l'objectif principal actif.
class UserObjectiveBanner extends StatelessWidget {
  final UserProfileDetailModel? profile;
  final bool isOffline;
  final ValueChanged<String>? onObjectiveChanged;

  const UserObjectiveBanner({
    super.key,
    required this.profile,
    this.isOffline = false,
    this.onObjectiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final info = ObjectiveHelper.getInfo(profile?.objectifPrincipal);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 20,
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.95),
          info.color.withValues(alpha: 0.06),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      customBorder: Border.all(
        color: info.color.withValues(alpha: 0.25),
        width: 1.2,
      ),
      customShadow: AppTheme.subtleShadow,
      onTap: () => _openObjectiveSelector(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(info.icon, size: 16, color: info.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'OBJECTIF ACTUEL',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: info.color,
                            ),
                          ),
                        ),
                        if (isOffline) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud_off_rounded, size: 9, color: Colors.amber.shade900),
                                const SizedBox(width: 3),
                                Text(
                                  'Hors-ligne',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _openObjectiveSelector(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: info.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: info.color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Changer',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: info.color,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.tune_rounded, size: 12, color: info.color),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            info.systemGuidance,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _openObjectiveSelector(BuildContext context) {
    HapticFeedback.lightImpact();
    ObjectiveSelectorBottomSheet.show(
      context,
      currentObjective: profile?.objectifPrincipal ?? 'suivi_cycle',
      onSelected: (newObjective) {
        onObjectiveChanged?.call(newObjective);
      },
    );
  }
}

/// BottomSheet moderne permettant de changer d'objectif en 1 clic.
class ObjectiveSelectorBottomSheet extends StatefulWidget {
  final String currentObjective;
  final ValueChanged<String> onSelected;

  const ObjectiveSelectorBottomSheet({
    super.key,
    required this.currentObjective,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentObjective,
    required ValueChanged<String> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ObjectiveSelectorBottomSheet(
        currentObjective: currentObjective,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<ObjectiveSelectorBottomSheet> createState() => _ObjectiveSelectorBottomSheetState();
}

class _ObjectiveSelectorBottomSheetState extends State<ObjectiveSelectorBottomSheet> {
  late String _selected;
  bool _isSaving = false;

  final List<String> _orderedKeys = const [
    'planifier_grossesse',
    'suivi_cycle',
    'eviter_grossesse',
    'comprendre_corps',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentObjective;
    if (_selected == 'concevoir') _selected = 'planifier_grossesse';
    if (_selected == 'contraception_naturelle') _selected = 'eviter_grossesse';
  }

  Future<void> _selectAndSave(String key) async {
    setState(() {
      _selected = key;
      _isSaving = true;
    });
    HapticFeedback.mediumImpact();

    try {
      await ServiceLocator.userRepository.updateProfile(
        UpdateProfileRequestModel(objectifPrincipal: key),
      );
      ServiceLocator.fertilityBloc.add(const RecalculateFertilityEvent());
      widget.onSelected(key);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Objectif adapté : ${ObjectiveHelper.getInfo(key).title}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {
      // Si hors-ligne ou erreur, appliquer localement
      widget.onSelected(key);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon objectif principal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      'Oriente vos prédictions et repères biométriques',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ..._orderedKeys.map((k) {
            final info = ObjectiveHelper.getInfo(k);
            final isSelected = _selected == k;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: _isSaving
                    ? null
                    : () {
                        setState(() => _selected = k);
                        HapticFeedback.selectionClick();
                      },
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? info.color.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? info.color : AppTheme.borderLight,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: info.color.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? info.color.withValues(alpha: 0.18)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          info.icon,
                          size: 20,
                          color: isSelected ? info.color : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    info.title,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? info.color : AppTheme.textDark,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: info.color,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'CHOISI',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              info.systemGuidance,
                              style: const TextStyle(
                                fontSize: 11.5,
                                height: 1.35,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.floatingShadow,
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => _selectAndSave(_selected),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Confirmer cet objectif',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

