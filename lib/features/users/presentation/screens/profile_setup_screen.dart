import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/error_feedback.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/modern_app_header.dart';
import '../../../cycles/data/models/cycle_models.dart';
import '../../../cycles/presentation/bloc/cycle_event.dart';
import '../../../fertility/presentation/bloc/fertility_event.dart';
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
  String _objective = 'planifier_grossesse';
  bool _irregular = false;
  DateTime? _lastPeriodDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final full = await ServiceLocator.userRepository.getProfile();
      if (!mounted) return;
      final p = full.profil;
      setState(() {
        if (p.prenom != null && p.prenom!.isNotEmpty) {
          _prenomController.text = p.prenom!;
        }
        _cycleDuration = p.dureeMoyenneCycle.clamp(20, 45);
        _flowDuration = p.dureeMoyenneRegles.clamp(2, 10);
        _objective = p.objectifPrincipal;
        _irregular = p.irregulariteDeclaree;
        if (p.dateDernieresReglesConnues != null) {
          _lastPeriodDate = DateTime.tryParse(p.dateDernieresReglesConnues!);
        }
      });
    } catch (_) {}
  }

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
      final lastPeriodStr = _lastPeriodDate != null
          ? DateFormat('yyyy-MM-dd').format(_lastPeriodDate!)
          : null;

      final req = UpdateProfileRequestModel(
        prenom: _prenomController.text.trim().isNotEmpty ? _prenomController.text.trim() : null,
        dureeMoyenneCycle: _cycleDuration,
        dureeMoyenneRegles: _flowDuration,
        objectifPrincipal: _objective,
        irregulariteDeclaree: _irregular,
        dateDernieresReglesConnues: lastPeriodStr,
      );

      await ServiceLocator.userRepository.updateProfile(req);

      // Si l'utilisatrice a choisi une date de dernières règles et qu'aucun cycle actif n'existe, on initialise le cycle
      if (_lastPeriodDate != null) {
        try {
          final activeCycle = await ServiceLocator.cycleRepository.getActiveCycle();
          if (activeCycle == null) {
            await ServiceLocator.cycleRepository.startCycle(StartCycleRequestModel(
              dateDebut: lastPeriodStr!,
              intensiteFlux: 'moyen',
            ));
          }
        } catch (_) {}
      }

      // Recalcul immédiat du Fertility Engine
      try {
        await ServiceLocator.fertilityRepository.recalculateFertility();
      } catch (_) {}

      // Notification de tous les blocs pour mise à jour synchrone de toutes les pages
      ServiceLocator.cycleBloc.add(LoadCyclesEvent());
      ServiceLocator.fertilityBloc.add(const LoadCurrentFertilityEvent());
      final now = DateTime.now();
      ServiceLocator.fertilityBloc.add(LoadMonthCalendarEvent(year: now.year, month: now.month));

      if (mounted) {
        AppFeedback.showSuccess(
          context,
          title: 'Algorithme calibré ✨',
          message: 'Vos prédictions et repères ont été adaptés à vos paramètres.',
        );
        if (widget.onCompleted != null) {
          widget.onCompleted!();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        AppErrorFeedback.showSnackBar(
          context,
          error: e,
          customTitle: 'Enregistrement impossible',
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
      appBar: const ModernAppHeader(
        title: 'Assistant de cycle',
        subtitle: 'Personnalisation',
        showNetworkStatus: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
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
                      _buildObjectiveTile(
                        'planifier_grossesse',
                        'Concevoir un enfant',
                        'Identifier les jours de fertilité maximale & cibler l\'ovulation',
                        Icons.child_care_rounded,
                      ),
                      const SizedBox(height: 10),
                      _buildObjectiveTile(
                        'suivi_cycle',
                        'Suivre mon cycle & mes règles',
                        'Prévoir l\'arrivée des règles, le SPM et comprendre vos symptômes',
                        Icons.calendar_today_rounded,
                      ),
                      const SizedBox(height: 10),
                      _buildObjectiveTile(
                        'eviter_grossesse',
                        'Observation & Méthode naturelle',
                        'Connaître votre zone de prudence et les signaux corporels',
                        Icons.spa_rounded,
                      ),
                      const SizedBox(height: 10),
                      _buildObjectiveTile(
                        'comprendre_corps',
                        'Comprendre mon corps & mes hormones',
                        'Analyser les 4 phases physiologiques et leurs impacts',
                        Icons.psychology_rounded,
                      ),
                      const SizedBox(height: 14),
                      _buildObjectiveReactionCard(),
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
                        value: _cycleDuration.toDouble().clamp(20.0, 45.0),
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
                        value: _flowDuration.toDouble().clamp(2.0, 10.0),
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

  Widget _buildObjectiveReactionCard() {
    Color cardColor;
    Color accentColor;
    IconData headerIcon;
    String title;
    String subtitle;
    List<Map<String, String>> points;

    switch (_objective) {
      case 'planifier_grossesse':
      case 'concevoir':
        cardColor = const Color(0xFFFFF0F5);
        accentColor = AppTheme.accentRose;
        headerIcon = Icons.favorite_rounded;
        title = 'Mode Projet Bébé & Conception';
        subtitle = 'FertiliteApp oriente ses algorithmes pour maximiser vos chances :';
        points = [
          {
            'title': 'Ciblage des jours clés',
            'desc': 'Mise en avant immédiate de votre pic de fertilité (J-2, J-1 et jour d\'ovulation).',
          },
          {
            'title': 'Biomarqueurs décisifs',
            'desc': 'Vos tests d\'ovulation (LH) et votre glaire cervicale ajustent en temps réel le pic d\'ovulation.',
          },
          {
            'title': 'Conseils de synchronisation',
            'desc': 'Repères sans stress pour planifier vos moments d\'intimité en pleine harmonie.',
          },
        ];
        break;

      case 'eviter_grossesse':
      case 'contraception_naturelle':
        cardColor = const Color(0xFFF0FDF4);
        accentColor = Colors.teal.shade700;
        headerIcon = Icons.shield_rounded;
        title = 'Mode Observation & Prudence';
        subtitle = 'FertiliteApp applique une marge de sécurité accrue pour différer naturellement :';
        points = [
          {
            'title': 'Zone de précaution active',
            'desc': 'Alerte visuelle claire et sans ambiguïté dès que la fenêtre fertile est susceptible d\'être ouverte.',
          },
          {
            'title': 'Statut de sécurité validé',
            'desc': 'Distingue nettement les phases de risque de fécondation des périodes d\'infertilité confirmées.',
          },
          {
            'title': 'Suivi de la glaire cervicale',
            'desc': 'Incitation quotidienne à observer les sécrétions pour détecter l\'ouverture précoce du col.',
          },
        ];
        break;

      case 'comprendre_corps':
        cardColor = const Color(0xFFF5F3FF);
        accentColor = Colors.purple.shade700;
        headerIcon = Icons.auto_awesome_rounded;
        title = 'Mode Saisons Hormonales & Vitalité';
        subtitle = 'FertiliteApp décrypte l\'impact de vos hormones sur votre bien-être :';
        points = [
          {
            'title': 'Les 4 saisons du cycle',
            'desc': 'Suivi pas à pas des phases Menstruelle (reset), Folliculaire (essor), Ovulatoire (éclat) et Lutéale (calme).',
          },
          {
            'title': 'Humeur, énergie & SPM',
            'desc': 'Explications bienveillantes reliant votre forme physique et mentale aux niveaux d\'œstrogènes et de progestérone.',
          },
          {
            'title': 'Rythme holistique',
            'desc': 'Conseils en alimentation, créativité et repos adaptés à la saison physiologique que vous traversez.',
          },
        ];
        break;

      case 'suivi_cycle':
      case 'suivre_cycle':
      default:
        cardColor = const Color(0xFFF8FAFC);
        accentColor = AppTheme.primary;
        headerIcon = Icons.calendar_today_rounded;
        title = 'Mode Prévision & Suivi de Cycle';
        subtitle = 'FertiliteApp vous apporte sérénité et clarté sur vos repères :';
        points = [
          {
            'title': 'Compte à rebours des règles',
            'desc': 'Prévision précise de l\'arrivée des prochaines menstruations et alerte douce en cas de retard.',
          },
          {
            'title': 'Anticipation du SPM',
            'desc': 'Conseils préventifs quelques jours avant les règles pour apaiser les crampes et l\'inconfort.',
          },
          {
            'title': 'Historique & régularité',
            'desc': 'Statistiques complètes sur la durée de vos cycles pour mieux connaître votre corps au fil des mois.',
          },
        ];
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(headerIcon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textDark, height: 1.3),
                        children: [
                          TextSpan(
                            text: '${p['title']} : ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: p['desc'],
                            style: const TextStyle(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
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
