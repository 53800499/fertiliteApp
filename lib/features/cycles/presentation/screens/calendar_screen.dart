import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../users/data/models/user_profile_model.dart';
import '../../../users/presentation/screens/profile_setup_screen.dart';
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
import '../../../observations/presentation/widgets/observation_entry_bottom_sheet.dart';
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
import '../../../notifications/presentation/bloc/notification_bloc.dart';
import '../../../notifications/presentation/bloc/notification_state.dart';
import '../../../notifications/presentation/screens/notification_inbox_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();
  final Map<String, JourReglesModel> _localSavedJours = {};
  FullUserProfileModel? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    context.read<CycleBloc>().add(LoadCyclesEvent());
    context.read<FertilityBloc>().add(const LoadCurrentFertilityEvent());
    context.read<FertilityBloc>().add(LoadMonthCalendarEvent(
          year: _currentMonth.year,
          month: _currentMonth.month,
        ));
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    context.read<ObservationBloc>().add(LoadDayObservationsEvent(dateStr));
  }

  Future<void> _loadUserProfile() async {
    try {
      final p = await ServiceLocator.userRepository.getProfile();
      if (mounted) setState(() => _userProfile = p);
    } catch (_) {}
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

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    _loadUserProfile();
    context.read<CycleBloc>().add(LoadCyclesEvent());
    context.read<FertilityBloc>().add(const LoadCurrentFertilityEvent());
    context.read<FertilityBloc>().add(LoadMonthCalendarEvent(
          year: _currentMonth.year,
          month: _currentMonth.month,
        ));
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    context.read<ObservationBloc>().add(LoadDayObservationsEvent(dateStr));
    await Future.delayed(const Duration(milliseconds: 700));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: ModernAppHeader(
        transparent: true,
        subtitle: "Aujourd'hui",
        title: 'Calendrier & Fertilité',
        onRefresh: _handleRefresh,
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, notifState) {
              final unreadCount = notifState is NotificationLoadedState
                  ? notifState.unreadCount
                  : 0;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.textDark,
                      size: 24,
                    ),
                    tooltip: 'Notifications & Alertes',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationInboxScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: AtmosphericBackground(
        imagePath: 'assets/images/woman_wellness_natural.jpg',
        child: BlocConsumer<CycleBloc, CycleState>(
          listener: (context, state) {
            if (state is CycleFailureState) {
              AppFeedback.showError(
                context,
                error: state.message,
                customTitle: 'Synchronisation du cycle',
              );
            }
          },
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
              return RefreshIndicator(
                color: AppTheme.primary,
                backgroundColor: Colors.white,
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: OfflineStateView(
                    onRetry: _handleRefresh,
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: Colors.white,
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: AppErrorEmptyView(
                  error: state.message,
                  onRetry: _handleRefresh,
                ),
              ),
            );
          }

          final loadedState = state is CyclesLoadedState ? state : null;
          final activeCycle = loadedState?.activeCycle;
          final currentDay = activeCycle?.currentCycleDay ?? 1;

          // Détection du jour de règles pour la date sélectionnée
          final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
          final selectedJour = _localSavedJours[dateStr] ?? loadedState?.getJourReglesForDate(_selectedDate);

          return RefreshIndicator(
            color: AppTheme.primary,
            backgroundColor: Colors.white,
            displacement: 40,
            strokeWidth: 2.5,
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
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

                  // 3. Détail du Jour Sélectionné & Biomarqueurs
                  BlocBuilder<ObservationBloc, ObservationState>(
                    builder: (context, obsState) {
                      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                      DayObservationsModel? dayObs;
                      List<TypeSymptomeModel> catalog = [];
                      if (obsState is DayObservationsLoadedState) {
                        final obsDate = obsState.observations.date.length >= 10
                            ? obsState.observations.date.substring(0, 10)
                            : obsState.observations.date;
                        if (obsDate == dateStr) {
                          dayObs = obsState.observations;
                          catalog = obsState.catalog;
                        }
                      } else if (obsState is ObservationSuccessState && obsState.updatedObservations != null) {
                        final obsDate = obsState.updatedObservations!.date.length >= 10
                            ? obsState.updatedObservations!.date.substring(0, 10)
                            : obsState.updatedObservations!.date;
                        if (obsDate == dateStr) {
                          dayObs = obsState.updatedObservations;
                          catalog = context.read<ObservationBloc>().cachedCatalog;
                        }
                      }
                      final obsBloc = context.read<ObservationBloc>();
                      dayObs ??= obsBloc.cachedDays[dateStr];
                      if (catalog.isEmpty) {
                        catalog = obsBloc.cachedCatalog;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSelectedDayDetailCard(selectedJour, activeCycle),
                          const SizedBox(height: 16),
                          DayObservationsCard(
                            date: _selectedDate,
                            observations: dayObs,
                            catalog: catalog,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
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
            final cycleState = context.read<CycleBloc>().state;
            final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
            final jour = _localSavedJours[dateStr] ??
                (cycleState is CyclesLoadedState
                    ? cycleState.getJourReglesForDate(_selectedDate)
                    : null);
            final obsBloc = context.read<ObservationBloc>();
            final dayObs = obsBloc.cachedDays[dateStr];
            final catalog = obsBloc.cachedCatalog;
            _showAddEntryOptionSheet(
              context,
              jour: jour,
              dayObs: dayObs,
              catalog: catalog,
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
        final profile = _userProfile?.profil;
        final objective = profile?.objectifPrincipal ?? 'suivi_cycle';
        final cycleDuration = profile?.dureeMoyenneCycle ?? 28;
        final periodDuration = profile?.dureeMoyenneRegles ?? (cycle?.dureeReglesJours ?? 5);
        final isIrregular = profile?.irregulariteDeclaree ?? false;
        final theoreticalOvulation = cycleDuration - 14;

        int effectiveDay = currentDay;
        final lastKnown = profile?.dateDernieresReglesConnues;
        if (cycle == null && lastKnown != null && lastKnown.isNotEmpty) {
          try {
            final start = DateTime.parse(lastKnown);
            final diff = DateTime.now().difference(start).inDays + 1;
            if (diff > 0 && diff <= 120) {
              effectiveDay = diff;
            }
          } catch (_) {}
        }

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

          if (effectiveDay >= 1 && effectiveDay <= periodDuration) {
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
            } else if (effectiveDay > theoreticalOvulation + 1) {
              phaseLabel = 'Phase lutéale';
              phaseColor = Colors.teal;
            }
          }
          confidenceText = 'Algorithme : ${pred.confidenceLevel.toUpperCase()}';
        } else {
          // Fallback personnalisé selon les paramètres déclarés dans l'assistant
          if (effectiveDay >= 1 && effectiveDay <= periodDuration) {
            phaseLabel = 'Règles en cours';
            phaseColor = AppTheme.periodColor;
            fertilityText = 'Très faible';
          } else if (effectiveDay >= (theoreticalOvulation - (isIrregular ? 6 : 5)) &&
              effectiveDay <= (theoreticalOvulation + (isIrregular ? 2 : 1))) {
            phaseLabel = effectiveDay == theoreticalOvulation ? 'Ovulation estimée' : 'Fenêtre fertile';
            phaseColor = AppTheme.accentRose;
            fertilityText = effectiveDay == theoreticalOvulation ? 'Maximale' : 'Élevée';
          } else if (effectiveDay > theoreticalOvulation + 1) {
            phaseLabel = 'Phase lutéale';
            phaseColor = Colors.teal;
            fertilityText = 'Faible';
          }
        }

        // Adaptation métrique & affichage selon l'objectif du cycle
        String metricSubtitle = 'Fertilité estimée :';
        String metricValue = fertilityText;
        String objectiveBadgeLabel = 'SUIVI DU CYCLE';
        IconData objectiveIcon = Icons.calendar_today_rounded;

        switch (objective) {
          case 'planifier_grossesse':
          case 'concevoir':
            objectiveBadgeLabel = 'PROJET CONCEPTION';
            objectiveIcon = Icons.child_care_rounded;
            metricSubtitle = 'Chances de conception :';
            if (phaseLabel.contains('ovulation')) {
              metricValue = 'Maximale (${fertState is FertilityLoadedState ? fertState.currentPrediction.fertilityScoreValue.round() : 95}%) 🔥';
            } else if (phaseLabel.contains('fertile')) {
              metricValue = 'Très favorable (${fertState is FertilityLoadedState ? fertState.currentPrediction.fertilityScoreValue.round() : 75}%) 🌸';
            } else if (phaseLabel.contains('Règles')) {
              metricValue = 'Période de repos';
            } else {
              metricValue = 'Faible (${fertState is FertilityLoadedState ? fertState.currentPrediction.fertilityScoreValue.round() : 15}%)';
            }
            break;

          case 'eviter_grossesse':
          case 'contraception_naturelle':
            objectiveBadgeLabel = 'MÉTHODE NATURELLE';
            objectiveIcon = Icons.shield_outlined;
            metricSubtitle = 'Statut de précaution :';
            if (phaseLabel.contains('ovulation') || phaseLabel.contains('fertile')) {
              metricValue = 'Phase fertile (Protection requise) ⚠️';
            } else if (phaseLabel.contains('Règles')) {
              metricValue = 'Infertilité physiologique 🛡️';
            } else {
              metricValue = 'Zone sécurisée 🛡️';
            }
            break;

          case 'comprendre_corps':
            objectiveBadgeLabel = 'ÉCOUTE DU CORPS';
            objectiveIcon = Icons.psychology_rounded;
            metricSubtitle = 'Biorhythme hormonal :';
            if (phaseLabel.contains('Règles')) {
              metricValue = 'Repérage & Reset 🍵';
            } else if (phaseLabel.contains('folliculaire')) {
              metricValue = 'Montée d’œstrogènes ⚡';
            } else if (phaseLabel.contains('ovulation') || phaseLabel.contains('fertile')) {
              metricValue = 'Pic d’œstrogènes & LH 🌸';
            } else {
              metricValue = 'Progestérone dominante 🌙';
            }
            break;

          case 'suivi_cycle':
          case 'suivre_cycle':
          default:
            objectiveBadgeLabel = 'SUIVI DU CYCLE';
            objectiveIcon = Icons.calendar_today_rounded;
            metricSubtitle = 'Repère de règles :';
            final daysToNext = cycleDuration - effectiveDay;
            if (phaseLabel.contains('Règles')) {
              metricValue = 'Règles en cours';
            } else if (daysToNext > 0) {
              metricValue = 'Prévues dans $daysToNext j';
            } else if (daysToNext == 0) {
              metricValue = 'Règles attendues aujourd’hui';
            } else {
              metricValue = 'Retard de ${-daysToNext} j';
            }
            break;
        }

        String wellnessTip = "Énergie équilibrée & vitalité naturelle ✨";
        IconData wellnessIcon = Icons.auto_awesome_rounded;

        if (objective == 'planifier_grossesse' || objective == 'concevoir') {
          if (phaseLabel.contains('ovulation') || phaseLabel.contains('fertile')) {
            wellnessTip = "Période clé : rapports favorables entre J-2 et le jour d'ovulation 🌸";
            wellnessIcon = Icons.favorite_rounded;
          } else if (phaseLabel.contains('Règles')) {
            wellnessTip = "Préparation du nid : privilégiez le fer, le zinc et les folates 🍵";
            wellnessIcon = Icons.spa_rounded;
          } else {
            wellnessTip = "Sérénité d'esprit : le stress diminue, restez à l'écoute de votre corps 🌿";
            wellnessIcon = Icons.self_improvement_rounded;
          }
        } else if (objective == 'eviter_grossesse' || objective == 'contraception_naturelle') {
          if (phaseLabel.contains('ovulation') || phaseLabel.contains('fertile')) {
            wellnessTip = "Marge de sécurité active : protection barrière indispensable 🛡️";
            wellnessIcon = Icons.warning_amber_rounded;
          } else {
            wellnessTip = "Période infertile physiologique : risque de fécondation négligeable ✨";
            wellnessIcon = Icons.verified_user_rounded;
          }
        } else if (objective == 'comprendre_corps') {
          if (phaseLabel.contains('Règles')) {
            wellnessTip = "Baisse hormonale : accordez-vous du calme et de l'introspection 🍵";
            wellnessIcon = Icons.spa_rounded;
          } else if (phaseLabel.contains('folliculaire')) {
            wellnessTip = "Pic d'œstrogènes : créativité, tonus musculaire et sociabilité en hausse ⚡";
            wellnessIcon = Icons.bolt_rounded;
          } else if (phaseLabel.contains('ovulation') || phaseLabel.contains('fertile')) {
            wellnessTip = "Pic hormonal : éclat de peau, libido et communication au zénith 🌸";
            wellnessIcon = Icons.auto_awesome_rounded;
          } else {
            wellnessTip = "Climat progestatif : privilégiez le sommeil régulier et la douceur 🌙";
            wellnessIcon = Icons.nightlight_round;
          }
        } else {
          if (phaseLabel.contains('Règles')) {
            wellnessTip = "Hydratation et réconfort : tisanes de framboisier et repos 🍵";
            wellnessIcon = Icons.spa_rounded;
          } else if (effectiveDay >= cycleDuration - 4) {
            wellnessTip = "Période prémenstruelle : magnésium et étirements pour soulager le SPM 🌙";
            wellnessIcon = Icons.self_improvement_rounded;
          } else {
            wellnessTip = "Rythme stable : vitalité et sérénité au quotidien ✨";
            wellnessIcon = Icons.bolt_rounded;
          }
        }

        final displayDay = effectiveDay > 0
            ? '$effectiveDay'
            : (cycle != null ? '$currentDay' : '--');

        return GlassCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          gradient: AppTheme.softHeroGradient,
          customBorder: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
          customShadow: AppTheme.floatingShadow,
          onTap: () => FertilityExplanationBottomSheet.show(context),
          child: Column(
            children: [
              // Badge d'objectif actif adapté
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(objectiveIcon, size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          objectiveBadgeLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Cycle : ${cycleDuration}j',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

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
                            displayDay,
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

                  // Informations adaptées à l'objectif
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
                        Text(
                          metricSubtitle,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          metricValue,
                          style: const TextStyle(
                            fontSize: 16.5,
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
                                fontSize: 10.5,
                                color: Colors.white60,
                                fontWeight: FontWeight.w600,
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
    final profile = _userProfile?.profil;
    final objective = profile?.objectifPrincipal ?? 'suivi_cycle';
    final dureeRegles = profile?.dureeMoyenneRegles ?? (cycle?.dureeReglesJours ?? 5);
    final dureeCycle = profile?.dureeMoyenneCycle ?? 28;
    final theoreticalOvulation = dureeCycle - 14;

    int effectiveDay = currentDay;
    final lastKnown = profile?.dateDernieresReglesConnues;
    if (cycle == null && lastKnown != null && lastKnown.isNotEmpty) {
      try {
        final start = DateTime.parse(lastKnown);
        final diff = DateTime.now().difference(start).inDays + 1;
        if (diff > 0 && diff <= 120) effectiveDay = diff;
      } catch (_) {}
    }

    String imagePath = 'assets/images/woman_wellness_natural.jpg';
    String title = "Écoute du corps & Sérénité";
    String message = "Chaque cycle est unique. Vos paramètres FertiliteApp adaptent vos repères jour après jour.";
    String badge = "Bien-être au naturel";

    if (effectiveDay >= 1 && effectiveDay <= dureeRegles) {
      imagePath = 'assets/images/woman_wellness_natural.jpg';
      title = "Ralentir & s’apaiser";
      message = "Votre corps se régénère : privilégiez la douceur, le repos et une hydratation bienfaisante.";
      badge = "Phase Menstruelle (J$effectiveDay)";
    } else if (effectiveDay >= theoreticalOvulation - 5 && effectiveDay <= theoreticalOvulation + 1) {
      imagePath = 'assets/images/woman_wellness_natural.jpg';
      if (objective == 'planifier_grossesse') {
        title = "Chances optimales de conception";
        message = "La réceptivité biologique est à son pic. Restez détendue, favorisez l'harmonie et l'écoute mutuelle.";
        badge = "Objectif Conception 🌸";
      } else if (objective == 'eviter_grossesse') {
        title = "Marge de précaution active";
        message = "Période à haute probabilité : observez vos signaux de glaire cervicale et appliquez vos règles de protection.";
        badge = "Méthode Naturelle 🛡️";
      } else {
        title = "Énergie & éclat naturel";
        message = "Période d'ouverture et d'énergie : observez vos signaux corporels avec clarté et bienveillance.";
        badge = "Fenêtre Fertile";
      }
    } else if (effectiveDay > theoreticalOvulation + 1) {
      imagePath = 'assets/images/woman_serenity_journal.jpg';
      title = "Harmonie & recentrage";
      message = "Phase d'apaisement : accordez-vous un moment de calme, un sommeil réparateur et de la douceur.";
      badge = "Phase Lutéale (J$effectiveDay)";
    } else {
      imagePath = 'assets/images/woman_serenity_journal.jpg';
      title = "Vitalité en essor";
      message = "L'énergie s'éveille progressivement : un moment propice pour vos projets et vos ressentis.";
      badge = "Phase Folliculaire (J$effectiveDay)";
    }

    return NaturalWellnessCard(
      imagePath: imagePath,
      title: title,
      message: message,
      badgeText: badge,
      onTap: () => FertilityExplanationBottomSheet.show(context),
    );
  }

  IconData _getObjectiveIcon(String? obj) {
    switch (obj) {
      case 'planifier_grossesse':
      case 'concevoir':
        return Icons.child_care_rounded;
      case 'eviter_grossesse':
      case 'contraception_naturelle':
        return Icons.shield_outlined;
      case 'comprendre_corps':
        return Icons.psychology_rounded;
      case 'suivi_cycle':
      case 'suivre_cycle':
      default:
        return Icons.calendar_today_rounded;
    }
  }

  String _getObjectiveTitle(String? obj) {
    switch (obj) {
      case 'planifier_grossesse':
      case 'concevoir':
        return 'Conception';
      case 'eviter_grossesse':
      case 'contraception_naturelle':
        return 'Méthode naturelle';
      case 'comprendre_corps':
        return 'Écoute hormonale';
      case 'suivi_cycle':
      case 'suivre_cycle':
      default:
        return 'Suivi du cycle';
    }
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
          // Badge adaptatif des repères de cycle déclarés
          if (_userProfile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileSetupScreen(
                        onCompleted: () => Navigator.pop(context),
                      ),
                    ),
                  );
                  _handleRefresh();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getObjectiveIcon(_userProfile?.profil.objectifPrincipal),
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getObjectiveTitle(_userProfile?.profil.objectifPrincipal),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '(${_userProfile?.profil.dureeMoyenneCycle ?? 28}j)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_outlined, size: 12, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ),

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
              final cellDateStr =
                  "${cellDate.year.toString().padLeft(4, '0')}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}";
              final jourRegles = _localSavedJours[cellDateStr] ?? state?.getJourReglesForDate(cellDate);
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
                      if (!isSelected &&
                          context.read<ObservationBloc>().cachedDays[cellDateStr]?.rapport != null)
                        const Positioned(
                          top: 2,
                          left: 2,
                          child: Icon(Icons.favorite_rounded, size: 7, color: Color(0xFFE91E63)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Légende des couleurs adaptée
          Builder(
            builder: (context) {
              final obj = _userProfile?.profil.objectifPrincipal;
              String fertileLegend = 'Fenêtre fertile';
              if (obj == 'planifier_grossesse' || obj == 'concevoir') {
                fertileLegend = 'Fertilité optimale';
              } else if (obj == 'eviter_grossesse' || obj == 'contraception_naturelle') {
                fertileLegend = 'Prudence requise';
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem(AppTheme.periodColor, 'Règles'),
                  _buildLegendItem(AppTheme.primaryLight, fertileLegend),
                  _buildLegendItem(AppTheme.accentRose, 'Ovulation'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddEntryOptionSheet(
    BuildContext context, {
    JourReglesModel? jour,
    DayObservationsModel? dayObs,
    List<TypeSymptomeModel> catalog = const [],
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Saisie du ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choisissez le type d\'informations à renseigner pour cette date :',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            // Option 1 : Flux & Règles
            InkWell(
              onTap: () async {
                Navigator.pop(modalCtx);
                final res = await LogFlowBottomSheet.show(
                  context,
                  date: _selectedDate,
                  existingJour: jour,
                );
                if (res != null && mounted) {
                  final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
                  setState(() {
                    _localSavedJours[dateKey] = res;
                  });
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accentRoseLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.periodColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.periodColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.water_drop_rounded, color: AppTheme.periodColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Flux menstruel & Règles',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            jour != null
                                ? 'Modifier : flux ${_formatIntensityLabel(jour.intensiteFlux)}, douleur ${jour.douleurNiveau ?? 0}/10'
                                : 'Enregistrer le flux, les douleurs ou début de cycle',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Option 2 : Biomarqueurs & Symptômes
            InkWell(
              onTap: () async {
                Navigator.pop(modalCtx);
                final res = await ObservationEntryBottomSheet.show(
                  context,
                  date: _selectedDate,
                  existingObservations: dayObs,
                  catalog: catalog,
                );
                if (res == true && mounted) setState(() {});
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.biotech_rounded, color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Biomarqueurs & Symptômes',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (dayObs != null && dayObs.hasObservations)
                                ? 'Modifier : T°, glaire, test LH, rapports ou symptômes'
                                : 'Température basale, glaire, test LH, intimité (chiffrée), ressentis',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDayDetailCard(
    JourReglesModel? jour,
    CycleModel? cycle,
  ) {
    final hasFlow = jour != null;
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Diagnostic & Réaction adaptative de FertiliteApp pour la date sélectionnée
          _buildDayObjectiveInsightBanner(cycle, hasFlow && jour.intensiteFlux != 'absent'),
          const SizedBox(height: 14),

          // 2. Flux menstruel & Règles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (hasFlow && jour.intensiteFlux != 'absent')
                            ? AppTheme.periodColor.withValues(alpha: 0.12)
                            : AppTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.water_drop_rounded,
                        color: (hasFlow && jour.intensiteFlux != 'absent')
                            ? AppTheme.periodColor
                            : AppTheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Flux menstruel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.periodColor.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  HapticFeedback.selectionClick();
                  final result = await LogFlowBottomSheet.show(
                    context,
                    date: _selectedDate,
                    existingJour: jour,
                  );
                  if (result != null && mounted) {
                    setState(() {
                      _localSavedJours[dateKey] = result;
                    });
                  }
                },
                icon: Icon(
                  hasFlow ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                  size: 15,
                  color: AppTheme.periodColor,
                ),
                label: Text(
                  hasFlow ? 'Modifier' : 'Ajouter',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.periodColor,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 22, color: AppTheme.borderLight),
          if (hasFlow) ...[
            // 1. Intensité du flux avec gouttes visuelles
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.water_drop_rounded,
                    size: 18,
                    color: _getIntensityColor(jour.intensiteFlux),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Intensité du flux',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_getIntensityDrops(jour.intensiteFlux) > 0) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(4, (i) {
                        final active = i < _getIntensityDrops(jour.intensiteFlux);
                        return Icon(
                          Icons.water_drop_rounded,
                          size: 12,
                          color: active
                              ? _getIntensityColor(jour.intensiteFlux)
                              : Colors.grey.shade300,
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _formatIntensityLabel(jour.intensiteFlux),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: _getIntensityColor(jour.intensiteFlux),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Niveau de douleur et crampes
            if (jour.douleurNiveau != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.healing_rounded,
                      size: 18,
                      color: _getPainColor(jour.douleurNiveau!),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Crampes & douleur',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPainColor(jour.douleurNiveau!).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${jour.douleurNiveau}/10 • ${_getPainLabel(jour.douleurNiveau!)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _getPainColor(jour.douleurNiveau!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 3. Notes éventuelles
            if (jour.notes != null && jour.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_rounded, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        jour.notes!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textDark,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 4. Cycle rattaché
            if (cycle != null) ...[
              const SizedBox(height: 6),
              _buildDetailRow(
                Icons.calendar_today_rounded,
                'Cycle rattaché',
                cycle.isEnCours
                    ? 'Cycle en cours (J${cycle.currentCycleDay})'
                    : 'Cycle clôturé',
                AppTheme.primary,
              ),
            ],
          ] else ...[
            // État vide bienveillant incitant à l'action
            InkWell(
              onTap: () async {
                HapticFeedback.selectionClick();
                final result = await LogFlowBottomSheet.show(
                  context,
                  date: _selectedDate,
                  existingJour: null,
                );
                if (result != null && mounted) {
                  setState(() {
                    _localSavedJours[dateKey] = result;
                  });
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.periodColor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.periodColor.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.periodColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.water_drop_outlined, color: AppTheme.periodColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Aucun flux menstruel enregistré',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Touchez pour consigner vos règles, du spotting ou vos crampes du jour.',
                            style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.periodColor),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatIntensityLabel(String? intensity) {
    switch (intensity) {
      case 'absent':
        return 'Aucun flux';
      case 'spotting':
        return 'Spotting';
      case 'leger':
        return 'Flux léger';
      case 'moyen':
        return 'Flux moyen';
      case 'abondant':
        return 'Flux abondant';
      default:
        return intensity != null && intensity.isNotEmpty ? intensity : 'Non renseigné';
    }
  }

  Color _getIntensityColor(String? intensity) {
    switch (intensity) {
      case 'absent':
        return Colors.grey.shade600;
      case 'spotting':
        return const Color(0xFFFF8A65);
      case 'leger':
        return const Color(0xFFEF5350);
      case 'moyen':
        return const Color(0xFFE53935);
      case 'abondant':
        return const Color(0xFFC62828);
      default:
        return AppTheme.periodColor;
    }
  }

  int _getIntensityDrops(String? intensity) {
    switch (intensity) {
      case 'spotting':
        return 1;
      case 'leger':
        return 2;
      case 'moyen':
        return 3;
      case 'abondant':
        return 4;
      default:
        return 0;
    }
  }

  String _getPainLabel(int score) {
    if (score == 0) return 'Aucune douleur';
    if (score <= 3) return 'Douleur légère';
    if (score <= 6) return 'Douleur modérée';
    if (score <= 8) return 'Douleur vive';
    return 'Douleur très intense';
  }

  Color _getPainColor(int score) {
    if (score == 0) return Colors.teal;
    if (score <= 3) return Colors.lightGreen.shade700;
    if (score <= 6) return Colors.amber.shade800;
    return Colors.red.shade700;
  }

  Widget _buildDayObjectiveInsightBanner(CycleModel? cycle, bool isFlowDay) {
    final isFertile = _isFertileDay(_selectedDate, cycle);
    final isOvulation = _isOvulationDay(_selectedDate, cycle);
    final profile = _userProfile?.profil;
    final objective = profile?.objectifPrincipal ?? 'suivi_cycle';
    final cycleDuration = profile?.dureeMoyenneCycle ?? 28;
    final periodDuration = profile?.dureeMoyenneRegles ?? (cycle?.dureeReglesJours ?? 5);
    final theoreticalOvulation = cycleDuration - 14;

    int? dayInCycle;
    final startStr = cycle?.dateDebut ?? profile?.dateDernieresReglesConnues;
    if (startStr != null && startStr.isNotEmpty) {
      try {
        final start = DateTime.parse(startStr);
        final diff = _selectedDate.difference(start).inDays + 1;
        if (diff > 0 && diff <= 120) {
          dayInCycle = diff;
        }
      } catch (_) {}
    }

    String badge;
    Color badgeColor;
    IconData badgeIcon;
    String title;
    String message;
    String actionLabel;
    IconData actionIcon;

    switch (objective) {
      case 'planifier_grossesse':
      case 'concevoir':
        if (isOvulation) {
          badge = 'PIC DE FERTILITÉ';
          badgeColor = AppTheme.accentRose;
          badgeIcon = Icons.star_rounded;
          title = 'Jour optimal pour concevoir';
          message = 'L\'ovocyte est libéré et viable de 12 à 24 heures. Un rapport intime aujourd\'hui maximise vos probabilités de conception.';
          actionLabel = '🌸 Cible prioritaire • Glaire blanc d\'œuf ou test LH +';
          actionIcon = Icons.favorite_rounded;
        } else if (isFertile) {
          badge = 'FENÊTRE FERTILE FAVORABLE';
          badgeColor = const Color(0xFFE91E63);
          badgeIcon = Icons.auto_awesome_rounded;
          title = 'Chances de fécondation élevées';
          message = 'Les spermatozoïdes peuvent survivre jusqu\'à 5 jours dans la glaire cervicale fertile pour attendre l\'ovulation.';
          actionLabel = '✨ Rapports recommandés tous les 1 à 2 jours';
          actionIcon = Icons.favorite_border_rounded;
        } else if (isFlowDay || (dayInCycle != null && dayInCycle <= periodDuration && dayInCycle > 0)) {
          badge = 'DÉBUT DE CYCLE • RÈGLES';
          badgeColor = AppTheme.periodColor;
          badgeIcon = Icons.water_drop_rounded;
          title = 'Régénération & Préparation du corps';
          message = 'Votre muqueuse se renouvelle en vue du prochain cycle. Privilégiez le repos, le fer, le magnésium et une bonne hydratation.';
          actionLabel = '🍵 Repos bienfaisant & alimentation ressourçante';
          actionIcon = Icons.spa_rounded;
        } else if (dayInCycle != null && dayInCycle > theoreticalOvulation + 1) {
          badge = 'PHASE LUTÉALE • NIDATION';
          badgeColor = Colors.teal.shade700;
          badgeIcon = Icons.nightlight_round;
          title = 'Période d\'attente sereine';
          message = 'L\'utérus est sous climat progestatif favorable. En cas de fécondation, la nidation survient 6 à 10 jours après l\'ovulation.';
          actionLabel = '🌿 Sérénité d\'esprit & rythme calme';
          actionIcon = Icons.self_improvement_rounded;
        } else {
          badge = 'PHASE FOLLICULAIRE';
          badgeColor = AppTheme.primary;
          badgeIcon = Icons.bolt_rounded;
          title = 'Maturation folliculaire';
          message = 'Vos ovaires préparent un ovocyte mature. Votre fenêtre fertile s\'ouvrira dans quelques jours.';
          actionLabel = '⚡ Vitalité en montée progressive';
          actionIcon = Icons.trending_up_rounded;
        }
        break;

      case 'eviter_grossesse':
      case 'contraception_naturelle':
        if (isOvulation || isFertile) {
          badge = 'ZONE DE PRUDENCE ACTIVE';
          badgeColor = Colors.deepOrange.shade800;
          badgeIcon = Icons.warning_rounded;
          title = 'Probabilité de fécondation élevée';
          message = 'Fertilité biologique active : risque de conception très important en cas de rapport non protégé. Méthode barrière ou abstinence requise.';
          actionLabel = '🛡️ Préservatif ou abstinence obligatoire';
          actionIcon = Icons.shield_rounded;
        } else if (isFlowDay || (dayInCycle != null && dayInCycle <= periodDuration && dayInCycle > 0)) {
          badge = 'RÈGLES • INFERTILITÉ';
          badgeColor = AppTheme.periodColor;
          badgeIcon = Icons.water_drop_rounded;
          title = 'Probabilité de conception très faible';
          message = 'Période d\'infertilité relative due à l\'évacuation menstruelle (prudence si vos cycles sont habituellement courts).';
          actionLabel = '🛡️ Période de faible risque';
          actionIcon = Icons.verified_user_rounded;
        } else if (dayInCycle != null && dayInCycle > theoreticalOvulation + 2) {
          badge = 'ZONE SÉCURISÉE • INFERTILE';
          badgeColor = Colors.teal.shade700;
          badgeIcon = Icons.verified_rounded;
          title = 'Infertilité post-ovulatoire';
          message = "L'ovule n'est plus fécondable (durée de vie 24h révolue). Risque de conception négligeable jusqu'au retour des règles.";
          actionLabel = '✅ Période sécurisée pour les rapports';
          actionIcon = Icons.check_circle_outline_rounded;
        } else {
          badge = 'PRÉ-OVULATION • VIGILANCE';
          badgeColor = Colors.amber.shade900;
          badgeIcon = Icons.search_rounded;
          title = 'Surveillance quotidienne de la glaire';
          message = 'Dès les premières sensations d\'humidité ou de glaire filante, la zone de fertilité commence. Restez vigilante.';
          actionLabel = '💧 Observez la texture de vos sécrétions';
          actionIcon = Icons.remove_red_eye_rounded;
        }
        break;

      case 'comprendre_corps':
        if (isFlowDay || (dayInCycle != null && dayInCycle <= periodDuration && dayInCycle > 0)) {
          badge = 'HIVER • MENSTRUATION';
          badgeColor = AppTheme.periodColor;
          badgeIcon = Icons.spa_rounded;
          title = 'Reset complet & Introspection';
          message = 'Œstrogènes et progestérone sont au repos. Baisse naturelle d\'énergie : offrez-vous du calme et du sommeil réparateur.';
          actionLabel = '🌙 Ralentissez & écoutez votre fatigue';
          actionIcon = Icons.nightlight_round;
        } else if (isOvulation || isFertile) {
          badge = 'ÉTÉ • OVULATION';
          badgeColor = AppTheme.accentRose;
          badgeIcon = Icons.auto_awesome_rounded;
          title = 'Pic d\'Œstrogènes & de Testostérone';
          message = 'Rayonnement maximal de votre cycle : clarté mentale, sociabilité, confiance, libido accrue et tonus au sommet !';
          actionLabel = '🌸 Énergie rayonnante & communication';
          actionIcon = Icons.favorite_rounded;
        } else if (dayInCycle != null && dayInCycle > theoreticalOvulation + 1) {
          badge = 'AUTOMNE • PHASE LUTÉALE';
          badgeColor = Colors.purple.shade700;
          badgeIcon = Icons.psychology_rounded;
          title = 'Climat de Progestérone dominante';
          message = 'Votre rythme se tourne vers l\'intérieur. Si la progestérone baisse, le SPM peut émerger : privilégiez le magnésium et la douceur.';
          actionLabel = '🍫 Douceur, magnésium & écoute de soi';
          actionIcon = Icons.self_improvement_rounded;
        } else {
          badge = 'PRINTEMPS • FOLLICULAIRE';
          badgeColor = Colors.teal.shade700;
          badgeIcon = Icons.bolt_rounded;
          title = 'Montée progressive des Œstrogènes';
          message = 'Renouveau de dynamisme : cerveau vif, motivation spontanée et endurance. Période idéale pour entreprendre et bouger.';
          actionLabel = '⚡ Créativité, projets & vitalité';
          actionIcon = Icons.trending_up_rounded;
        }
        break;

      case 'suivi_cycle':
      case 'suivre_cycle':
      default:
        if (isFlowDay) {
          badge = 'RÈGLES EN COURS';
          badgeColor = AppTheme.periodColor;
          badgeIcon = Icons.water_drop_rounded;
          title = 'Journée de flux menstruel';
          message = 'Consignez votre flux et vos crampes pour que FertiliteApp ajuste la durée réelle de vos règles et vos repères futurs.';
          actionLabel = '💧 Enregistrez vos flux & douleurs';
          actionIcon = Icons.edit_note_rounded;
        } else if (dayInCycle != null && dayInCycle >= cycleDuration - 4 && dayInCycle <= cycleDuration) {
          final diff = cycleDuration - dayInCycle;
          badge = 'RÈGLES IMMINENTES';
          badgeColor = Colors.amber.shade900;
          badgeIcon = Icons.access_time_rounded;
          title = 'Phase prémenstruelle (SPM)';
          message = diff == 0
              ? 'Vos règles sont prévues pour aujourd\'hui. Préparez vos protections.'
              : 'Vos prochaines règles sont attendues dans $diff jours. Prévoyez vos protections et hydratez-vous.';
          actionLabel = '🌙 Période prémenstruelle sous repères';
          actionIcon = Icons.calendar_today_rounded;
        } else if (dayInCycle != null && dayInCycle > cycleDuration) {
          final retard = dayInCycle - cycleDuration;
          badge = 'RETARD ($retard j)';
          badgeColor = Colors.deepOrange.shade800;
          badgeIcon = Icons.warning_amber_rounded;
          title = 'Cycle plus long qu\'habituellement';
          message = 'Vous comptez $retard jours au-delà de votre durée habituelle ($cycleDuration jours). Un test de grossesse peut être envisagé.';
          actionLabel = '⏱️ Surveillance du cycle en cours';
          actionIcon = Icons.timelapse_rounded;
        } else if (isOvulation || isFertile) {
          badge = 'MILIEU DE CYCLE • OVULATION';
          badgeColor = AppTheme.accentRose;
          badgeIcon = Icons.star_border_rounded;
          title = 'Période ovulatoire estimée';
          message = 'Vous êtes au cœur de votre cycle (J${dayInCycle ?? '--'}). Des sécrétions plus fluides ou de légers tiraillements sont courants.';
          actionLabel = '🌸 Équilibre du milieu de cycle';
          actionIcon = Icons.calendar_today_rounded;
        } else {
          badge = 'SUIVI DU CYCLE • J${dayInCycle ?? '--'}';
          badgeColor = AppTheme.primary;
          badgeIcon = Icons.calendar_today_rounded;
          title = 'Progression régulière du cycle';
          message = 'Tout suit son cours naturel. Touchez le bouton pour consigner tout changement, flux ou observation.';
          actionLabel = '✨ Repères physiologiques stables';
          actionIcon = Icons.check_circle_outline_rounded;
        }
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.28), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 12, color: badgeColor),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            badge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (dayInCycle != null && dayInCycle > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Text(
                    'Jour $dayInCycle',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(actionIcon, size: 13, color: badgeColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
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
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
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

    final startStr = cycle?.dateDebut ?? _userProfile?.profil.dateDernieresReglesConnues;
    if (startStr == null) return false;
    try {
      final start = DateTime.parse(startStr);
      final diff = date.difference(start).inDays + 1;
      final cycleDuration = _userProfile?.profil.dureeMoyenneCycle ?? 28;
      final isIrregular = _userProfile?.profil.irregulariteDeclaree ?? false;
      final theoreticalOvulation = cycleDuration - 14;
      final windowBefore = isIrregular ? 6 : 5;
      final windowAfter = isIrregular ? 2 : 1;
      return diff >= (theoreticalOvulation - windowBefore) && diff <= (theoreticalOvulation + windowAfter);
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

    final startStr = cycle?.dateDebut ?? _userProfile?.profil.dateDernieresReglesConnues;
    if (startStr == null) return false;
    try {
      final start = DateTime.parse(startStr);
      final diff = date.difference(start).inDays + 1;
      final cycleDuration = _userProfile?.profil.dureeMoyenneCycle ?? 28;
      final theoreticalOvulation = cycleDuration - 14;
      return diff == theoreticalOvulation;
    } catch (_) {
      return false;
    }
  }
}
