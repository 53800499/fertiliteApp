import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  /// URL de base automatique selon la plateforme d'exécution
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    try {
      if (Platform.isAndroid) {
        // Alias de localhost pour l'émulateur Android
        return 'http://10.0.2.2:3000';
      }
    } catch (_) {}
    return 'http://localhost:3000';
  }

  // Timeouts réseau
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  // --- Endpoints Auth (Module 1) ---
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';

  // --- Endpoints Users & Profil (Module 1) ---
  static const String userProfile = '/users/profile';
  static const String userDeleteRequest = '/users/delete-request';

  // --- Endpoints Privacy & Consentements (Module 1) ---
  static const String privacySettings = '/privacy/settings';
  static const String privacyConsents = '/privacy/consents';
  static const String privacySessions = '/privacy/sessions';
  static String privacyRevokeSession(String id) => '/privacy/sessions/$id';

  // --- Endpoints Cycles & Règles (Module 2) ---
  static const String cyclesStart = '/cycles/start';
  static const String cyclesDays = '/cycles/days';
  static const String cyclesList = '/cycles';
  static const String cyclesActive = '/cycles/active';
  static const String cyclesStats = '/cycles/stats';
  static String cycleById(String id) => '/cycles/$id';

  // --- Endpoints Observations & Symptômes (Module 3) ---
  static const String observationsCatalog = '/observations/symptoms/catalog';
  static const String observationsTemperature = '/observations/temperature';
  static const String observationsMucus = '/observations/cervical-mucus';
  static const String observationsLh = '/observations/lh-test';
  static const String observationsSymptoms = '/observations/symptoms';
  static const String observationsDay = '/observations/day';
  static String observationsForDay(String date) => '/observations/days/$date';
  static const String observationsHistory = '/observations/history';
}

