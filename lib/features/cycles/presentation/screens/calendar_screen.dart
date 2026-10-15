import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/cycle_models.dart';
import '../bloc/cycle_bloc.dart';
import '../bloc/cycle_event.dart';
import '../bloc/cycle_state.dart';
import '../widgets/log_flow_bottom_sheet.dart';
import '../../../observations/data/models/observation_models.dart';
import '../../../observations/presentation/bloc/observation_bloc.dart';
import '../../../observations/presentation/bloc/observation_event.dart';
import '../../../observations/presentation/bloc/observation_state.dart';
import '../../../observations/presentation/widgets/day_observations_card.dart';
import '../../../fertility/presentation/bloc/fertility_bloc.dart';
import '../../../fertility/presentation/widgets/fertility_explanation_bottom_sheet.dart';
import '../../../../core/network/network_cubit.dart';
import '../../../../core/widgets/offline_state_view.dart';
import '../../../../core/widgets/modern_app_header.dart';
import '../../../../core/widgets/natural_wellness_card.dart';
import '../../../../core/widgets/atmospheric_background.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/glass_skeleton_loader.dart';
import '../../../../core/error/error_feedback.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<CycleBloc>().add(LoadCyclesEvent());
    context.read<FertilityBloc>().add(const LoadCurrentFertilityEvent());
    context.read<FertilityBloc>().add(LoadMonthCalendarEvent(
          year: _currentMonth.year,
          month: _currentMonth.month,
        ));
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    context.read<ObservationBloc>().add(LoadDayObservationsEvent(dateStr));
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    context.read<FertilityBloc>().add(LoadMonthCalendarEvent(
          year: _currentMonth.year,
          month: _currentMonth.month,
        ));
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    context.read<FertilityBloc>().add(LoadMonthCalendarEvent(
          year: _currentMonth.year,
          month: _currentMonth.month,
        ));
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
        transparent: true,
        subtitle: "Aujourd'hui",
        title: 'Calendrier & Fertilité',
        onRefresh: () => context.read<CycleBloc>().add(LoadCyclesEvent()),
      ),
      body: AtmosphericBackground(
        imagePath: 'assets/images/woman_wellness_natural.jpg',
        child: BlocBuilder<CycleBloc, CycleState>(
          builder: (context, state) {
            if (state is CycleLoadingState) {
              return const CalendarSkeletonView();
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

          final loadedState = state is CyclesLoadedState ? state : null;
          final activeCycle = loadedState?.activeCycle;
          final currentDay = activeCycle?.currentCycleDay ?? 1;

          // Détection du jour de règles pour la date sélectionnée
          final selectedJour = loadedState?.getJourReglesForDate(_selectedDate);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Card : Statut Physiologique du Jour
                _buildHeroStatusCard(activeCycle, currentDay),
                const SizedBox(height: 16),

                // 2. Carte Bien-être au naturel & Illustration bienveillante
                _buildWellnessInsightCard(activeCycle, currentDay),
                const SizedBox(height: 18),

                // 3. Grille Calendaire Mensuelle
                _buildCalendarCard(loadedState),
                const SizedBox(height: 18),

                // 3. Détail du Jour Sélectionné
                _buildSelectedDayDetailCard(selectedJour, activeCycle),
                const SizedBox(height: 16),

                // 4. Biomarqueurs & Symptômes (Module 3)
                BlocBuilder<ObservationBloc, ObservationState>(
                  builder: (context, obsState) {
                    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                    DayObservationsModel? dayObs;
                    List<TypeSymptomeModel> catalog = [];
                    if (obsState is DayObservationsLoadedState && obsState.observations.date == dateStr) {
                      dayObs = obsState.observations;
                      catalog = obsState.catalog;
                    }
                    return DayObservationsCard(
                      date: _selectedDate,
                      observations: dayObs,
                      catalog: catalog,
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          elevation: 0,
          highlightElevation: 0,
          backgroundColor: Colors.transparent,
          onPressed: () {
            HapticFeedback.selectionClick();
            LogFlowBottomSheet.show(
              context,
              date: _selectedDate,
              existingJour: context.read<CycleBloc>().state is CyclesLoadedState
                  ? (context.read<CycleBloc>().state as CyclesLoadedState).getJourReglesForDate(_selectedDate)
                  : null,
            );
          },
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          label: const Text(
            'Saisie du jour',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStatusCard(CycleModel? cycle, int currentDay) {
    return BlocBuilder<FertilityBloc, FertilityState>(
      builder: (context, fertState) {
        String phaseLabel = 'Phase folliculaire';
        Color phaseColor = AppTheme.primary;
        String fertilityText = 'Probabilité faible';
        String confidenceText = '';

        if (fertState is FertilityLoadedState) {
          final pred = fertState.currentPrediction;
          if (pred.fertilityCategory == 'elevee') {
            fertilityText = 'Élevée (${pred.fertilityScoreValue.round()}%)';
            phaseColor = AppTheme.accentRose;
          } else if (pred.fertilityCategory == 'moyenne') {
            fertilityText = 'Moyenne (${pred.fertilityScoreValue.round()}%)';
            phaseColor = Colors.orange;
          } else {
            fertilityText = 'Faible (${pred.fertilityScoreValue.round()}%)';
            phaseColor = Colors.teal;
          }

          if (currentDay >= 1 && currentDay <= (cycle?.dureeReglesJours ?? 5)) {
            phaseLabel = 'Règles en cours';
            phaseColor = AppTheme.periodColor;
          } else if (pred.estimatedOvulationDate != null) {
            final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
            if (nowStr == pred.estimatedOvulationDate) {
              phaseLabel = 'Jour d’ovulation';
              phaseColor = AppTheme.accentRose;
            } else if (nowStr.compareTo(pred.fertileWindow.startDate) >= 0 &&
                nowStr.compareTo(pred.fertileWindow.endDate) <= 0) {
              phaseLabel = 'Fenêtre fertile';
              phaseColor = AppTheme.accentRose;
            } else if (currentDay > 16) {
              phaseLabel = 'Phase lutéale';
              phaseColor = Colors.teal;
            }
          }
          confidenceText = 'Confiance : ${pred.confidenceLevel}';
        } else {
          // Fallback initial
          if (currentDay >= 1 && currentDay <= (cycle?.dureeReglesJours ?? 5)) {
            phaseLabel = 'Règles en cours';
            phaseColor = AppTheme.periodColor;
            fertilityText = 'Très faible';
          } else if (currentDay >= 10 && currentDay <= 16) {
            phaseLabel = 'Fenêtre fertile';
            phaseColor = AppTheme.accentRose;
            fertilityText = currentDay == 14 ? 'Ovulation estimée' : 'Élevée';
          } else if (currentDay > 16) {
            phaseLabel = 'Phase lutéale';
            phaseColor = Colors.teal;
            fertilityText = 'Faible';
          }
        }

        String wellnessTip = "Énergie équilibrée & vitalité naturelle ✨";
        IconData wellnessIcon = Icons.auto_awesome_rounded;
        if (phaseLabel.contains('Règles')) {
          wellnessTip = "Prenez soin de vous : hydratation, repos & tisane 🍵";
          wellnessIcon = Icons.spa_rounded;
        } else if (phaseLabel.contains('ovulation') || phaseLabel.contains('fertile')) {
          wellnessTip = "Pic de fertilité & d'éclat : votre corps est au sommet 🌸";
          wellnessIcon = Icons.favorite_rounded;
        } else if (phaseLabel.contains('lutéale')) {
          wellnessTip = "Phase d'apaisement : sommeil réparateur & sérénité 🌙";
          wellnessIcon = Icons.nightlight_round;
        } else {
          wellnessTip = "Vitalité en hausse : idéal pour créer et bouger ⚡";
          wellnessIcon = Icons.bolt_rounded;
        }

        return GlassCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          gradient: AppTheme.softHeroGradient,
          customBorder: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
          customShadow: AppTheme.floatingShadow,
          onTap: () => FertilityExplanationBottomSheet.show(context),
          child: Column(
                children: [
                  Row(
                    children: [
                      // Jauge circulaire avec jour du cycle
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.15),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'JOUR',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                cycle != null ? '$currentDay' : '--',
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),

                      // Informations de fertilité
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: phaseColor.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                phaseLabel,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Fertilité estimée :',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              fertilityText,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            if (confidenceText.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  confidenceText,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Bannière bien-être et conseil du jour interactive
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      children: [
                        Icon(wellnessIcon, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            wellnessTip,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white70),
                      ],
                    ),
                  ),
                ],
              ),
        );
      },
    );
  }

  Widget _buildWellnessInsightCard(CycleModel? cycle, int currentDay) {
    String imagePath = 'assets/images/woman_wellness_natural.jpg';
    String title = "Écoute du corps & Sérénité";
    String message = "Chaque cycle est unique. Prenez ce temps pour vous reconnecter à votre rythme naturel.";
    String badge = "Bien-être au naturel";

    final dureeRegles = cycle?.dureeReglesJours ?? 5;
    if (currentDay >= 1 && currentDay <= dureeRegles) {
      imagePath = 'assets/images/woman_wellness_natural.jpg';
      title = "Ralentir & s’apaiser";
      message = "Votre corps se régénère : privilégiez la douceur, le repos et une hydratation bienfaisante.";
      badge = "Phase Menstruelle";
    } else if (currentDay >= 10 && currentDay <= 16) {
      imagePath = 'assets/images/woman_wellness_natural.jpg';
      title = "Énergie & éclat naturel";
      message = "Période d'ouverture et d'énergie : observez vos signaux corporels avec clarté et bienveillance.";
      badge = "Fenêtre Fertile";
    } else if (currentDay > 16) {
      imagePath = 'assets/images/woman_serenity_journal.jpg';
      title = "Harmonie & recentrage";
      message = "Phase d'apaisement : accordez-vous un moment de calme, un sommeil réparateur et de la douceur.";
      badge = "Phase Lutéale";
    } else {
      imagePath = 'assets/images/woman_serenity_journal.jpg';
      title = "Vitalité en essor";
      message = "L'énergie s'éveille progressivement : un moment propice pour vos projets et vos ressentis.";
      badge = "Phase Folliculaire";
    }

    return NaturalWellnessCard(
      imagePath: imagePath,
      title: title,
      message: message,
      badgeText: badge,
      onTap: () => FertilityExplanationBottomSheet.show(context),
    );
  }

  Widget _buildCalendarCard(CyclesLoadedState? state) {
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Lundi, 7 = Dimanche

    final monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      child: Column(
        children: [
          // En-tête mois / navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppTheme.textDark),
                onPressed: _previousMonth,
              ),
              Text(
                '${monthNames[month - 1]} $year',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 28, color: AppTheme.textDark),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // En-tête jours de la semaine
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('L', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
              Text('M', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
              Text('M', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
              Text('J', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
              Text('V', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
              Text('S', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
              Text('D', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
            ],
          ),
          const Divider(height: 20, color: AppTheme.borderLight),

          // Grille des jours
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42, // 6 semaines x 7 jours
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - (startingWeekday - 2);

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final cellDate = DateTime(year, month, dayNumber);
              final isToday = _isSameDay(cellDate, DateTime.now());
              final isSelected = _isSameDay(cellDate, _selectedDate);

              // Vérification si ce jour a des règles enregistrées
              final jourRegles = state?.getJourReglesForDate(cellDate);
              final hasFlow = jourRegles != null && jourRegles.intensiteFlux != 'absent';

              // Estimation visuelle : fenêtre fertile (ex: J10 à J16 du cycle en cours)
              final isFertileEstimated = _isFertileDay(cellDate, state?.activeCycle);
              final isOvulationEstimated = _isOvulationDay(cellDate, state?.activeCycle);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDate = cellDate);
                  context.read<CycleBloc>().add(SelectDateEvent(cellDate));
                  final dateStr = DateFormat('yyyy-MM-dd').format(cellDate);
                  context.read<ObservationBloc>().add(LoadDayObservationsEvent(dateStr));
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: isSelected
                        ? null
                        : hasFlow
                            ? AppTheme.periodColor.withValues(alpha: 0.25)
                            : isOvulationEstimated
                                ? AppTheme.accentRose.withValues(alpha: 0.25)
                                : isFertileEstimated
                                    ? AppTheme.primaryLight
                                    : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                    border: Border.all(
                      color: isToday && !isSelected
                          ? AppTheme.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                      if (hasFlow && !isSelected)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppTheme.periodColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      if (isOvulationEstimated && !isSelected)
                        const Positioned(
                          top: 2,
                          right: 2,
                          child: Icon(Icons.star_rounded, size: 8, color: AppTheme.accentRose),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Légende des couleurs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(AppTheme.periodColor, 'Règles'),
              _buildLegendItem(AppTheme.primaryLight, 'Fenêtre fertile'),
              _buildLegendItem(AppTheme.accentRose, 'Ovulation'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayDetailCard(JourReglesModel? jour, CycleModel? cycle) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Détail du ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.textDark),
              ),
              TextButton.icon(
                onPressed: () {
                  LogFlowBottomSheet.show(context, date: _selectedDate, existingJour: jour);
                },
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: Text(jour != null ? 'Modifier' : 'Ajouter', style: const TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
          const Divider(height: 16),
          if (jour != null) ...[
            _buildDetailRow(
              Icons.water_drop_rounded,
              'Flux menstruel',
              jour.intensiteFlux.toUpperCase(),
              AppTheme.periodColor,
            ),
            if (jour.douleurNiveau != null)
              _buildDetailRow(
                Icons.healing_rounded,
                'Niveau de douleur',
                '${jour.douleurNiveau}/10',
                Colors.amber.shade800,
              ),
            if (jour.notes != null && jour.notes!.isNotEmpty)
              _buildDetailRow(
                Icons.notes_rounded,
                'Notes',
                jour.notes!,
                AppTheme.textDark,
              ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Journée non renseignée',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Enregistrez vos flux ou ressentis pour affiner vos prédictions.',
                          style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                        ),
                      ],
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

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isFertileDay(DateTime date, CycleModel? cycle) {
    try {
      final fertState = context.read<FertilityBloc>().state;
      if (fertState is FertilityLoadedState) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final monthCal = fertState.monthCalendar;
        if (monthCal != null) {
          for (final d in monthCal.days) {
            if (d.date == dateStr) return d.isFertileDay;
          }
        }
        final start = fertState.currentPrediction.fertileWindow.startDate;
        final end = fertState.currentPrediction.fertileWindow.endDate;
        if (start.isNotEmpty && end.isNotEmpty) {
          return dateStr.compareTo(start) >= 0 && dateStr.compareTo(end) <= 0;
        }
      }
    } catch (_) {}

    if (cycle == null) return false;
    try {
      final start = DateTime.parse(cycle.dateDebut);
      final diff = date.difference(start).inDays + 1;
      return diff >= 10 && diff <= 16;
    } catch (_) {
      return false;
    }
  }

  bool _isOvulationDay(DateTime date, CycleModel? cycle) {
    try {
      final fertState = context.read<FertilityBloc>().state;
      if (fertState is FertilityLoadedState) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final monthCal = fertState.monthCalendar;
        if (monthCal != null) {
          for (final d in monthCal.days) {
            if (d.date == dateStr) return d.isOvulationDay;
          }
        }
        final ovulation = fertState.currentPrediction.estimatedOvulationDate;
        if (ovulation != null && ovulation.isNotEmpty) {
          return dateStr == ovulation;
        }
      }
    } catch (_) {}

    if (cycle == null) return false;
    try {
      final start = DateTime.parse(cycle.dateDebut);
      final diff = date.difference(start).inDays + 1;
      return diff == 14;
    } catch (_) {
      return false;
    }
  }
}
