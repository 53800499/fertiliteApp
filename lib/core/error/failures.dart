import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;
  final String? title;
  final String? actionSuggestion;
  final String? errorCode;

  const Failure(
    this.message, [
    this.statusCode,
    this.title,
    this.actionSuggestion,
    this.errorCode,
  ]);

  @override
  List<Object?> get props => [message, statusCode, title, actionSuggestion, errorCode];
}

class ServerFailure extends Failure {
  const ServerFailure(
    super.message, [
    super.statusCode,
    super.title = 'Incident serveur passager',
    super.actionSuggestion = 'Veuillez patienter quelques instants et réessayer.',
    super.errorCode = 'SERVER_ERROR',
  ]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Aucune connexion internet détectée.',
    super.statusCode,
    super.title = 'Connexion indisponible',
    super.actionSuggestion = 'Vérifiez votre réseau Wi-Fi ou mobile et réessayez.',
    super.errorCode = 'NETWORK_OFFLINE',
  ]);
}

class AuthFailure extends Failure {
  const AuthFailure(
    super.message, [
    super.statusCode,
    super.title = 'Erreur d\'authentification',
    super.actionSuggestion = 'Vérifiez vos identifiants.',
    super.errorCode = 'AUTH_ERROR',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, [
    super.statusCode = 400,
    super.title = 'Informations incomplètes',
    super.actionSuggestion = 'Veuillez corriger les champs en erreur.',
    super.errorCode = 'VALIDATION_ERROR',
  ]);
}
