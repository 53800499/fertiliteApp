import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/service_locator.dart';
import '../../core/network/network_cubit.dart';
import '../../core/network/network_state.dart';
import '../../core/network/widgets/offline_banner.dart';
import '../../core/theme/app_theme.dart';
import '../cycles/presentation/bloc/cycle_bloc.dart';
import '../cycles/presentation/bloc/cycle_event.dart';
import '../cycles/presentation/bloc/cycle_state.dart';
import '../observations/presentation/bloc/observation_bloc.dart';
import '../observations/presentation/bloc/observation_event.dart';
import '../fertility/presentation/bloc/fertility_bloc.dart';
import '../notifications/presentation/bloc/notification_bloc.dart';
import '../notifications/presentation/bloc/notification_event.dart';
import '../notifications/presentation/bloc/notification_state.dart';
import '../notifications/presentation/screens/notification_inbox_screen.dart';
import '../notifications/services/local_notification_service.dart';
import '../subscriptions/presentation/bloc/subscription_bloc.dart';
import '../subscriptions/presentation/bloc/subscription_event.dart';
import '../subscriptions/presentation/bloc/subscription_state.dart';
import '../subscriptions/presentation/screens/subscription_screen.dart';
import '../cycles/presentation/screens/calendar_screen.dart';
import '../cycles/presentation/screens/cycle_history_screen.dart';
import '../cycles/presentation/screens/cycle_stats_screen.dart';
import '../users/presentation/screens/profile_screen.dart';
import 'widgets/modern_floating_nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final Set<int> _loadedTabs = {0};
  bool _hasEvaluatedInitialGate = false;
  bool _isEvaluatingInitialGate = false;

  final List<Widget> _tabs = const [
    CalendarScreen(),
    CycleHistoryScreen(),
    CycleStatsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Chargement initial silencieux des notifications & évaluation des rappels
    ServiceLocator.notificationBloc.add(const LoadNotificationsEvent(silent: true));
    ServiceLocator.notificationBloc.add(EvaluateRemindersEvent());
    ServiceLocator.subscriptionBloc.add(const LoadSubscriptionEvent(silent: true));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _evaluateInitialSubscriptionGate(ServiceLocator.subscriptionBloc.state);
      final launchPayload =
          await LocalNotificationService.instance.consumeLaunchPayload();
      if (mounted && launchPayload != null && launchPayload.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationInboxScreen()),
        );
      }
    });
  }

  /// Programme les alertes locales hors-ligne pour la fenêtre fertile et les prochaines règles.
  void _syncLocalPredictionNotifications() {
    final notifState = ServiceLocator.notificationBloc.state;
    if (notifState is! NotificationLoadedState) return;

    DateTime? fertileStart;
    final fertilityState = ServiceLocator.fertilityBloc.state;
    if (fertilityState is FertilityLoadedState) {
      fertileStart =
          DateTime.tryParse(fertilityState.currentPrediction.fertileWindow.startDate);
    }

    DateTime? nextPeriodDate;
    final cycleState = ServiceLocator.cycleBloc.state;
    if (cycleState is CyclesLoadedState && cycleState.activeCycle != null) {
      final active = cycleState.activeCycle!;
      final start = DateTime.tryParse(active.dateDebut);
      if (start != null) {
        nextPeriodDate =
            start.add(Duration(days: active.dureeCycleJours ?? 28));
      }
    }

    LocalNotificationService.instance.syncPredictionSchedules(
      prefs: notifState.preferences,
      fertileStart: fertileStart,
      nextPeriodDate: nextPeriodDate,
    );
  }

  /// Affiche l'écran d'abonnement obligatoire à l'installation initiale
  /// si le super-administrateur a activé cette exigence dans la politique globale.
  Future<void> _evaluateInitialSubscriptionGate(SubscriptionState state) async {
    if (_hasEvaluatedInitialGate || _isEvaluatingInitialGate) return;
    if (state is! SubscriptionLoadedState) return;

    _isEvaluatingInitialGate = true;
    try {
      if (state.subscription.isPremium) {
        await ServiceLocator.storage.markInitialSubscriptionGateCompleted();
        _hasEvaluatedInitialGate = true;
        return;
      }

      if (!state.policy.exigenceAbonnementInitiale) {
        _hasEvaluatedInitialGate = true;
        return;
      }

      final alreadyDone = await ServiceLocator.storage.hasCompletedInitialSubscriptionGate();
      if (!mounted || alreadyDone) {
        _hasEvaluatedInitialGate = true;
        return;
      }

      _hasEvaluatedInitialGate = true;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const SubscriptionScreen(isInitialMandatoryGate: true),
        ),
      );
    } finally {
      _isEvaluatingInitialGate = false;
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _loadedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CycleBloc>.value(value: ServiceLocator.cycleBloc),
        BlocProvider<ObservationBloc>.value(value: ServiceLocator.observationBloc),
        BlocProvider<FertilityBloc>.value(value: ServiceLocator.fertilityBloc),
        BlocProvider<NotificationBloc>.value(value: ServiceLocator.notificationBloc),
        BlocProvider<SubscriptionBloc>.value(value: ServiceLocator.subscriptionBloc),
        BlocProvider<NetworkCubit>.value(value: ServiceLocator.networkCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<NetworkCubit, NetworkState>(
            listenWhen: (prev, curr) => curr.isOnline && (!prev.isOnline || curr.wasOffline),
            listener: (context, state) {
              // Synchronisation automatique silencieuse de toutes les données lors de la reconnexion
              context.read<CycleBloc>().add(LoadCyclesEvent());
              context.read<FertilityBloc>().add(const LoadCurrentFertilityEvent());
              context.read<ObservationBloc>().add(const SyncPendingObservationsEvent(isAutomatic: true));
              context.read<NotificationBloc>().add(const LoadNotificationsEvent(silent: true));
              context.read<NotificationBloc>().add(EvaluateRemindersEvent());
              context.read<SubscriptionBloc>().add(const LoadSubscriptionEvent(silent: true));
              ServiceLocator.userRepository.getProfile().catchError((_) => null);
            },
          ),
          BlocListener<SubscriptionBloc, SubscriptionState>(
            listener: (context, subState) =>
                _evaluateInitialSubscriptionGate(subState),
          ),
          BlocListener<NotificationBloc, NotificationState>(
            listenWhen: (_, curr) => curr is NotificationLoadedState,
            listener: (_, _) => _syncLocalPredictionNotifications(),
          ),
          BlocListener<FertilityBloc, FertilityState>(
            listenWhen: (_, curr) => curr is FertilityLoadedState,
            listener: (_, _) => _syncLocalPredictionNotifications(),
          ),
          BlocListener<CycleBloc, CycleState>(
            listenWhen: (_, curr) => curr is CyclesLoadedState,
            listener: (_, _) => _syncLocalPredictionNotifications(),
          ),
        ],
        child: Scaffold(
          backgroundColor: AppTheme.background,
          extendBody: false,
          body: Stack(
            children: [
              IndexedStack(
                index: _currentIndex,
                children: List.generate(
                  _tabs.length,
                  (index) => _loadedTabs.contains(index)
                      ? _tabs[index]
                      : const SizedBox.shrink(),
                ),
              ),
              // Bandeau flottant contextuel sans décalage de layout
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: GlobalOfflineBanner(),
              ),
            ],
          ),
          bottomNavigationBar: BlocBuilder<NetworkCubit, NetworkState>(
            builder: (context, netState) {
              return ModernFloatingNavBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                isOffline: !netState.isOnline,
                items: const [
                  ModernNavItem(
                    icon: Icons.calendar_month_outlined,
                    selectedIcon: Icons.calendar_month_rounded,
                    label: 'Calendrier',
                  ),
                  ModernNavItem(
                    icon: Icons.history_outlined,
                    selectedIcon: Icons.history_rounded,
                    label: 'Historique',
                  ),
                  ModernNavItem(
                    icon: Icons.auto_graph_outlined,
                    selectedIcon: Icons.auto_graph_rounded,
                    label: 'Statistiques',
                  ),
                  ModernNavItem(
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: 'Profil',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
