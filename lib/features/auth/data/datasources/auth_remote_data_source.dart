import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/security/secure_storage_helper.dart';
import '../models/auth_models.dart';

abstract class IAuthRemoteDataSource {
  Future<AuthResponseModel> login(LoginRequestModel request);
  Future<AuthResponseModel> register(RegisterRequestModel request);
  Future<void> logout();
  Future<String> forgotPassword(String email);
}

class AuthRemoteDataSourceImpl implements IAuthRemoteDataSource {
  final Dio dio;
  final SecureStorageHelper storage;

  AuthRemoteDataSourceImpl({
    required this.dio,
    required this.storage,
  });

  @override
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await dio.post(
        ApiConstants.authLogin,
        data: request.toJson(),
      );

      final model = AuthResponseModel.fromJson(response.data);

      // Sauvegarde des tokens et données locales
      await storage.saveAccessToken(model.tokens.accessToken);
      await storage.saveRefreshToken(model.tokens.refreshToken);
      await storage.saveUserData(userId: model.user.id, email: model.user.email);

      return model;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    try {
      final response = await dio.post(
        ApiConstants.authRegister,
        data: request.toJson(),
      );

      final model = AuthResponseModel.fromJson(response.data);

      // Sauvegarde des tokens et données locales
      await storage.saveAccessToken(model.tokens.accessToken);
      await storage.saveRefreshToken(model.tokens.refreshToken);
      await storage.saveUserData(userId: model.user.id, email: model.user.email);

      return model;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await storage.getRefreshToken();
      final data = <String, dynamic>{};
      if (refreshToken != null) data['refreshToken'] = refreshToken;
      await dio.post(
        ApiConstants.authLogout,
        data: data,
      );
    } catch (_) {
      // Ignorer l'erreur côté serveur lors de la déconnexion pour garantir la purge locale
    } finally {
      await storage.clearAllTokens();
    }
  }

  @override
  Future<String> forgotPassword(String email) async {
    try {
      final response = await dio.post(
        ApiConstants.authForgotPassword,
        data: {'email': email.trim().toLowerCase()},
      );
      return response.data['message'] as String? ??
          'Si cet email existe, un lien vous a été envoyé.';
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
