import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../cycles/presentation/bloc/cycle_bloc.dart';
import '../observations/presentation/bloc/observation_bloc.dart';
import '../cycles/presentation/screens/calendar_screen.dart';
import '../cycles/presentation/screens/cycle_history_screen.dart';
import '../cycles/presentation/screens/cycle_stats_screen.dart';
import '../users/presentation/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    CalendarScreen(),
    CycleHistoryScreen(),
    CycleStatsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CycleBloc>.value(value: ServiceLocator.cycleBloc),
        BlocProvider<ObservationBloc>.value(value: ServiceLocator.observationBloc),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: AppTheme.borderLight, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
            backgroundColor: Colors.white,
            indicatorColor: AppTheme.primaryLight,
            elevation: 0,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined, color: AppTheme.textMuted),
                selectedIcon: Icon(Icons.calendar_month_rounded, color: AppTheme.primary),
                label: 'Calendrier',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined, color: AppTheme.textMuted),
                selectedIcon: Icon(Icons.history_rounded, color: AppTheme.primary),
                label: 'Historique',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_graph_outlined, color: AppTheme.textMuted),
                selectedIcon: Icon(Icons.auto_graph_rounded, color: AppTheme.primary),
                label: 'Statistiques',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, color: AppTheme.textMuted),
                selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primary),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

