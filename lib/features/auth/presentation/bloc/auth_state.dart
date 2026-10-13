import 'package:equatable/equatable.dart';
import '../../../../core/error/api_exception.dart';
import '../../data/models/auth_models.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthenticatedState extends AuthState {
  final AuthUserModel user;

  const AuthenticatedState(this.user);

  @override
  List<Object?> get props => [user];
}

class UnauthenticatedState extends AuthState {}

class AuthFailureState extends AuthState {
  final String errorMessage;
  final String? title;
  final String? actionSuggestion;
  final String? errorCode;
  final Map<String, String>? fieldErrors;
  final bool isServerWakingUp;
  final ApiException? exception;

  const AuthFailureState(
    this.errorMessage, {
    this.title,
    this.actionSuggestion,
    this.errorCode,
    this.fieldErrors,
    this.isServerWakingUp = false,
    this.exception,
  });

  @override
  List<Object?> get props => [
        errorMessage,
        title,
        actionSuggestion,
        errorCode,
        fieldErrors,
        isServerWakingUp,
        exception,
      ];
}

class ForgotPasswordSuccessState extends AuthState {
  final String message;

  const ForgotPasswordSuccessState(this.message);

  @override
  List<Object?> get props => [message];
}
