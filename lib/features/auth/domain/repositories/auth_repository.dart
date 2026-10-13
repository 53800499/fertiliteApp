import '../../data/models/auth_models.dart';

abstract class IAuthRepository {
  Future<AuthResponseModel> login(LoginRequestModel request);
  Future<AuthResponseModel> register(RegisterRequestModel request);
  Future<void> logout();
  Future<String> forgotPassword(String email);
  Future<bool> isAuthenticated();
  Future<String?> getCurrentUserId();
}
