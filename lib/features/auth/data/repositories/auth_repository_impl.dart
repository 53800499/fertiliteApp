import '../../../../core/security/secure_storage_helper.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_models.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final IAuthRemoteDataSource remoteDataSource;
  final SecureStorageHelper storage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storage,
  });

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) {
    return remoteDataSource.login(request);
  }

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) {
    return remoteDataSource.register(request);
  }

  @override
  Future<void> logout() {
    return remoteDataSource.logout();
  }

  @override
  Future<String> forgotPassword(String email) {
    return remoteDataSource.forgotPassword(email);
  }

  @override
  Future<bool> isAuthenticated() {
    return storage.hasAccessToken();
  }

  @override
  Future<String?> getCurrentUserId() {
    return storage.getUserId();
  }
}
