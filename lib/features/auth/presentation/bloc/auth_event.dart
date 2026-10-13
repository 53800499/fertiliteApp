import 'package:equatable/equatable.dart';
import '../../data/models/auth_models.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Vérifie si une session active existe au démarrage
class CheckAuthStatusEvent extends AuthEvent {}

/// Demande de connexion
class LoginRequestedEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginRequestedEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Demande d'inscription
class RegisterRequestedEvent extends AuthEvent {
  final RegisterRequestModel request;

  const RegisterRequestedEvent(this.request);

  @override
  List<Object?> get props => [request];
}

/// Demande de mot de passe oublié
class ForgotPasswordRequestedEvent extends AuthEvent {
  final String email;

  const ForgotPasswordRequestedEvent(this.email);

  @override
  List<Object?> get props => [email];
}

/// Déconnexion
class LogoutRequestedEvent extends AuthEvent {}
