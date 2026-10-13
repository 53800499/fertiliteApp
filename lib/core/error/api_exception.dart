import 'package:dio/dio.dart';

/// Exception unifiée et compréhensible pour l'utilisateur lors d'échanges réseau / API
class ApiException implements Exception {
  /// Titre court et explicite de l'erreur (ex: "Identifiants incorrects")
  final String title;

  /// Message clair, bienveillant et compréhensible par une personne non-technique
  final String userFriendlyMessage;

  /// Message technique ou brut retourné par le serveur
  final String rawMessage;

  /// Suggestion d'action immédiate pour l'utilisatrice (ex: "Vérifiez vos identifiants ou cliquez sur...")
  final String actionSuggestion;

  /// Code machine standardisé pour les aiguillages d'interface
  final String errorCode;

  /// Erreurs de validation ciblées par champ (ex: {"email": "Format invalide"})
  final Map<String, String> fieldErrors;

  /// Code de statut HTTP si applicable
  final int? statusCode;

  /// Indique si l'erreur provient très probablement de la mise en veille du serveur gratuit (Render cold-start)
  final bool isServerWakingUp;

  /// Détails bruts
  final dynamic details;

  const ApiException({
    String? message,
    String? title,
    String? userFriendlyMessage,
    String? rawMessage,
    String? actionSuggestion,
    String? errorCode,
    this.fieldErrors = const {},
    this.statusCode,
    this.isServerWakingUp = false,
    this.details,
  })  : title = title ?? 'Une erreur est survenue',
        userFriendlyMessage = userFriendlyMessage ??
            message ??
            'Une erreur est survenue lors de l\'opération.',
        rawMessage = rawMessage ?? message ?? '',
        actionSuggestion = actionSuggestion ?? '',
        errorCode = errorCode ?? 'UNKNOWN_ERROR';

  /// Compatibilité ascendante : accesseur .message renvoyant le message compréhensible
  String get message => userFriendlyMessage;

  /// Construit une ApiException enrichie à partir d'une erreur Dio
  factory ApiException.fromDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    // 1. Extraction des données brutes
    String raw = '';
    Map<String, String> extractedFieldErrors = {};

    if (responseData != null) {
      if (responseData is Map<String, dynamic>) {
        final rawMsg = responseData['message'];
        if (rawMsg is List && rawMsg.isNotEmpty) {
          raw = rawMsg.map((e) => e.toString()).join(', ');
          for (final item in rawMsg) {
            _parseAndMapFieldError(item.toString(), extractedFieldErrors);
          }
        } else if (rawMsg is String) {
          raw = rawMsg;
        } else if (responseData['error'] is String) {
          raw = responseData['error'];
        }
      } else if (responseData is String) {
        raw = responseData;
      }
    }

    // 2. Détection du cas spécifique Render Cold Start / Inactivité
    final isTimeout = error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout;

    final isBadGateway = statusCode == 502 || statusCode == 503 || statusCode == 504;

    if (isBadGateway || (isTimeout && raw.isEmpty)) {
      return ApiException(
        title: 'Serveur en cours de réveil',
        userFriendlyMessage:
            'Le serveur en ligne (Render) redémarre après une courte période d\'inactivité. Cela prend généralement entre 30 et 50 secondes.',
        rawMessage: raw.isNotEmpty ? raw : 'Cold start / Timeout',
        actionSuggestion: 'Veuillez patienter une trentaine de secondes puis réessayez.',
        errorCode: 'SERVER_WAKING_UP',
        statusCode: statusCode,
        isServerWakingUp: true,
        details: responseData,
      );
    }

    // 3. Détection des erreurs réseau (hors ligne)
    if (error.type == DioExceptionType.connectionError) {
      return ApiException(
        title: 'Connexion impossible',
        userFriendlyMessage:
            'Impossible de contacter le serveur. Vérifiez votre connexion Internet ou la disponibilité du réseau.',
        rawMessage: error.message ?? 'Connexion refusée',
        actionSuggestion: 'Assurez-vous que votre Wi-Fi ou vos données mobiles sont activés.',
        errorCode: 'NETWORK_OFFLINE',
        statusCode: statusCode,
        details: responseData,
      );
    }

    // 4. Traitement précis par code HTTP
    switch (statusCode) {
      case 400:
        // Validation ou règle métier (ex: Âge ou Consentements)
        if (raw.toLowerCase().contains('12 ans') || raw.toLowerCase().contains('age') || raw.toLowerCase().contains('âge')) {
          extractedFieldErrors['birthDate'] = 'Âge minimum requis : 12 ans';
          return ApiException(
            title: 'Âge minimum requis',
            userFriendlyMessage:
                'L\'application est réservée aux personnes âgées d\'au moins 12 ans, conformément aux règles de protection des données de santé.',
            rawMessage: raw,
            actionSuggestion: 'Vérifiez l\'année de votre date de naissance.',
            errorCode: 'AUTH_UNDERAGE',
            fieldErrors: extractedFieldErrors,
            statusCode: 400,
            details: responseData,
          );
        }

        if (raw.toLowerCase().contains('l\'acceptation des cgu') ||
            raw.toLowerCase().contains('cgu et de la politique') ||
            (raw.toLowerCase().contains('cgu') && raw.toLowerCase().contains('obligatoire'))) {
          extractedFieldErrors['consents'] = 'Consentements requis';
          return ApiException(
            title: 'Consentements obligatoires',
            userFriendlyMessage:
                'Pour créer votre compte et protéger vos données de santé, l\'acceptation des CGU et de la politique de confidentialité est nécessaire.',
            rawMessage: raw,
            actionSuggestion: 'Veuillez cocher les cases obligatoires pour continuer.',
            errorCode: 'AUTH_CONSENTS_REQUIRED',
            fieldErrors: extractedFieldErrors,
            statusCode: 400,
            details: responseData,
          );
        }

        // Traduction humaine des messages class-validator courants
        final humanizedMessage = _humanizeValidationMessage(raw);

        return ApiException(
          title: 'Informations invalides',
          userFriendlyMessage: humanizedMessage,
          rawMessage: raw,
          actionSuggestion: 'Veuillez vérifier les champs signalés et réessayer.',
          errorCode: 'VALIDATION_FAILED',
          fieldErrors: extractedFieldErrors,
          statusCode: 400,
          details: responseData,
        );

      case 401:
        if (raw.toLowerCase().contains('suspendu')) {
          return ApiException(
            title: 'Compte suspendu',
            userFriendlyMessage: 'Ce compte utilisateur a été temporairement suspendu.',
            rawMessage: raw,
            actionSuggestion: 'Veuillez contacter le support pour réactiver votre accès.',
            errorCode: 'ACCOUNT_SUSPENDED',
            statusCode: 401,
            details: responseData,
          );
        }

        if (raw.toLowerCase().contains('session') || raw.toLowerCase().contains('token') || raw.toLowerCase().contains('expir')) {
          return ApiException(
            title: 'Session expirée',
            userFriendlyMessage:
                'Votre session a expiré par mesure de sécurité pour protéger vos données sensibles.',
            rawMessage: raw,
            actionSuggestion: 'Veuillez vous reconnecter pour poursuivre.',
            errorCode: 'AUTH_SESSION_EXPIRED',
            statusCode: 401,
            details: responseData,
          );
        }

        return ApiException(
          title: 'Identifiants incorrects',
          userFriendlyMessage: 'L\'adresse email ou le mot de passe saisi est incorrect.',
          rawMessage: raw.isNotEmpty ? raw : 'Identifiants invalides',
          actionSuggestion:
              'Vérifiez votre saisie ou utilisez l\'option "Mot de passe oublié" si vous ne vous en souvenez plus.',
          errorCode: 'INVALID_CREDENTIALS',
          statusCode: 401,
          details: responseData,
        );

      case 403:
        return ApiException(
          title: 'Accès non autorisé',
          userFriendlyMessage: 'Vous n\'avez pas la permission d\'effectuer cette opération.',
          rawMessage: raw,
          actionSuggestion: 'Vérifiez votre statut de connexion ou reconnectez-vous.',
          errorCode: 'FORBIDDEN',
          statusCode: 403,
          details: responseData,
        );

      case 404:
        return ApiException(
          title: 'Élément introuvable',
          userFriendlyMessage: 'Le profil ou la ressource demandée n\'existe pas.',
          rawMessage: raw,
          actionSuggestion: 'Actualisez votre page ou revenez à l\'écran précédent.',
          errorCode: 'NOT_FOUND',
          statusCode: 404,
          details: responseData,
        );

      case 409:
        extractedFieldErrors['email'] = 'Cet email est déjà utilisé';
        return ApiException(
          title: 'Compte déjà existant',
          userFriendlyMessage: 'Un compte est déjà associé à cette adresse email.',
          rawMessage: raw,
          actionSuggestion: 'Connectez-vous directement avec cet email ou réinitialisez votre mot de passe.',
          errorCode: 'EMAIL_ALREADY_EXISTS',
          fieldErrors: extractedFieldErrors,
          statusCode: 409,
          details: responseData,
        );

      case 429:
        return ApiException(
          title: 'Trop de tentatives',
          userFriendlyMessage:
              'Pour sécuriser votre compte, les tentatives répétées ont été temporairement restreintes.',
          rawMessage: raw,
          actionSuggestion: 'Veuillez patienter 1 à 2 minutes avant de réessayer.',
          errorCode: 'RATE_LIMITED',
          statusCode: 429,
          details: responseData,
        );

      case 500:
      default:
        return ApiException(
          title: 'Incident technique passager',
          userFriendlyMessage:
              'Un problème est survenu sur nos serveurs. Vos données déjà enregistrées restent en parfaite sécurité.',
          rawMessage: raw.isNotEmpty ? raw : (error.message ?? 'Erreur serveur inconnue'),
          actionSuggestion: 'Veuillez réessayer dans un instant.',
          errorCode: 'SERVER_ERROR',
          statusCode: statusCode,
          details: responseData,
        );
    }
  }

  /// Convertit n'importe quelle erreur en ApiException compréhensible
  factory ApiException.from(dynamic error) {
    if (error is ApiException) {
      return error;
    }
    if (error is DioException) {
      return ApiException.fromDioError(error);
    }

    final raw = error?.toString() ?? 'Erreur inattendue';
    return ApiException(
      title: 'Une erreur est survenue',
      userFriendlyMessage: raw.replaceAll('Exception:', '').trim(),
      rawMessage: raw,
      actionSuggestion: 'Veuillez réessayer l\'opération.',
      errorCode: 'UNKNOWN_ERROR',
    );
  }

  /// Retourne le message d'affichage le plus approprié pour un composant graphique
  static String getDisplayMessage(dynamic error) {
    if (error is ApiException) {
      return error.userFriendlyMessage;
    }
    if (error is DioException) {
      return ApiException.fromDioError(error).userFriendlyMessage;
    }
    if (error is String) {
      return error;
    }
    return 'Une erreur inattendue est survenue. Veuillez réessayer.';
  }

  /// Extrait et associe les erreurs aux champs du formulaire
  static void _parseAndMapFieldError(String rawMsg, Map<String, String> map) {
    final lower = rawMsg.toLowerCase();
    if (lower.contains('email')) {
      map['email'] = 'Adresse email invalide ou manquante';
    } else if (lower.contains('password') || lower.contains('mot de passe')) {
      map['password'] = 'Le mot de passe doit comporter au moins 8 caractères';
    } else if (lower.contains('birthdate') || lower.contains('naissance')) {
      map['birthDate'] = 'Date de naissance requise (min. 12 ans)';
    } else if (lower.contains('consent')) {
      map['consents'] = 'Consentements requis';
    }
  }

  /// Traduit en français clair les messages de validation techniques
  static String _humanizeValidationMessage(String raw) {
    if (raw.isEmpty) {
      return 'Veuillez vérifier les informations saisies.';
    }

    final lower = raw.toLowerCase();
    final List<String> friendlyParts = [];

    if (lower.contains('email must be an email') || lower.contains('email')) {
      friendlyParts.add('Le format de l\'adresse email n\'est pas valide.');
    }
    if (lower.contains('password must be longer') || lower.contains('8 characters')) {
      friendlyParts.add('Le mot de passe doit comporter au moins 8 caractères.');
    }
    if (lower.contains('birthdate')) {
      friendlyParts.add('La date de naissance est invalide.');
    }

    if (friendlyParts.isNotEmpty) {
      return friendlyParts.join(' ');
    }

    // Si le message d'origine est déjà en français propre, on le garde
    return raw;
  }

  @override
  String toString() =>
      'ApiException(errorCode: $errorCode, statusCode: $statusCode, title: $title, message: $userFriendlyMessage)';
}
