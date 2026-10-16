import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/service_locator.dart';
import '../../core/network/network_cubit.dart';
import '../../core/network/network_state.dart';
import '../../core/network/widgets/offline_banner.dart';
import '../../core/theme/app_theme.dart';
import '../cycles/presentation/bloc/cycle_bloc.dart';
import '../cycles/presentation/bloc/cycle_event.dart';
import '../observations/presentation/bloc/observation_bloc.dart';
import '../fertility/presentation/bloc/fertility_bloc.dart';
import '../notifications/presentation/bloc/notification_bloc.dart';
import '../notifications/presentation/bloc/notification_event.dart';
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
        BlocProvider<NetworkCubit>.value(value: ServiceLocator.networkCubit),
      ],
      child: BlocListener<NetworkCubit, NetworkState>(
        listenWhen: (prev, curr) => curr.wasOffline,
        listener: (context, state) {
          // Synchronisation automatique des données lors de la reconnexion
          context.read<CycleBloc>().add(LoadCyclesEvent());
        },
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
