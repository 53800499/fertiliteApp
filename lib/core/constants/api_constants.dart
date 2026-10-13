import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  /// URL du serveur de production en ligne (Render)
  static const String productionBaseUrl = 'https://fertilitebackend.onrender.com/api/v1';

  /// URL pour le développement local (Docker ou Node.js local)
  static String get localBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        // Alias de localhost pour l'émulateur Android
        return 'http://10.0.2.2:3000/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:3000/api/v1';
  }

  /// URL de base utilisée par défaut par l'application :
  /// 1. Variable d'environnement si passée via --dart-define=API_URL=...
  /// 2. Serveur de production en ligne (Render) par défaut
  static String get defaultBaseUrl {
    const customUrl = String.fromEnvironment('API_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    return productionBaseUrl;
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

