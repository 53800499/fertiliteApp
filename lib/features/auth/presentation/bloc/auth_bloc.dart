import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/api_exception.dart';
import '../../data/models/auth_models.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitialState()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginRequestedEvent>(_onLoginRequested);
    on<RegisterRequestedEvent>(_onRegisterRequested);
    on<ForgotPasswordRequestedEvent>(_onForgotPasswordRequested);
    on<LogoutRequestedEvent>(_onLogoutRequested);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isAuth = await authRepository.isAuthenticated();
      if (isAuth) {
        final userId = await authRepository.getCurrentUserId();
        emit(
          AuthenticatedState(
            AuthUserModel(
              id: userId ?? '',
              email: '',
              emailVerified: true,
            ),
          ),
        );
      } else {
        emit(UnauthenticatedState());
      }
    } catch (_) {
      emit(UnauthenticatedState());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final response = await authRepository.login(
        LoginRequestModel(
          email: event.email,
          password: event.password,
        ),
      );
      emit(AuthenticatedState(response.user));
    } on ApiException catch (e) {
      emit(AuthFailureState(e.message));
    } catch (e) {
      emit(AuthFailureState('Erreur de connexion inattendue: $e'));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final response = await authRepository.register(event.request);
      emit(AuthenticatedState(response.user));
    } on ApiException catch (e) {
      emit(AuthFailureState(e.message));
    } catch (e) {
      emit(AuthFailureState('Erreur lors de l\'inscription: $e'));
    }
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final message = await authRepository.forgotPassword(event.email);
      emit(ForgotPasswordSuccessState(message));
    } on ApiException catch (e) {
      emit(AuthFailureState(e.message));
    } catch (e) {
      emit(AuthFailureState('Impossible d\'envoyer le lien: $e'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    await authRepository.logout();
    emit(UnauthenticatedState());
  }
}
