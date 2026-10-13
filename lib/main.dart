import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/di/service_locator.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/onboarding_screen.dart';
import 'features/navigation/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation du conteneur de services & client API
  ServiceLocator.init();

  // Vérification de la session active existante
  ServiceLocator.authBloc.add(CheckAuthStatusEvent());

  runApp(const FertiliteApp());
}

class FertiliteApp extends StatelessWidget {
  const FertiliteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: ServiceLocator.authBloc,
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
        // Splash / Chargement initial
        return const Scaffold(
          backgroundColor: Color(0xFFFAF7F9),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF8E24AA)),
                SizedBox(height: 16),
                Text(
                  'FertiliteApp',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF37474F),
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
