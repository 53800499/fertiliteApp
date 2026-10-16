import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/di/service_locator.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/navigation/main_navigation_screen.dart';

import 'features/cycles/presentation/bloc/cycle_bloc.dart';
import 'features/observations/presentation/bloc/observation_bloc.dart';
import 'features/fertility/presentation/bloc/fertility_bloc.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'core/network/network_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation du conteneur de services & client API avec pré-résolution de session
  await ServiceLocator.init();
  ServiceLocator.networkCubit.checkConnectivity(silent: true);

  runApp(const FertiliteApp());
}

class FertiliteApp extends StatelessWidget {
  const FertiliteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: ServiceLocator.authBloc),
        BlocProvider<CycleBloc>.value(value: ServiceLocator.cycleBloc),
        BlocProvider<ObservationBloc>.value(value: ServiceLocator.observationBloc),
        BlocProvider<FertilityBloc>.value(value: ServiceLocator.fertilityBloc),
        BlocProvider<NotificationBloc>.value(value: ServiceLocator.notificationBloc),
        BlocProvider<NetworkCubit>.value(value: ServiceLocator.networkCubit),
      ],
      child: MaterialApp(
        title: 'FertiliteApp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthenticatedState) {
          return const MainNavigationScreen();
        } else if (state is UnauthenticatedState || state is AuthFailureState) {
          return const OnboardingScreen();
        }
        // Écran de transition soigné aux couleurs FertiliteApp
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.spa_rounded,
                      size: 40,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'FertiliteApp',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Santé Féminine & Fertilité',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
