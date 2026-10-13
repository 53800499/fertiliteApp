import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../security/secure_storage_helper.dart';

class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageHelper storage;
  final Dio dio;
  final void Function()? onSessionExpired;

  AuthInterceptor({
    required this.storage,
    required this.dio,
    this.onSessionExpired,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Si l'appel concerne déjà l'authentification publique, on ne passe pas de Bearer
    final isAuthPublic = options.path.contains(ApiConstants.authLogin) ||
        options.path.contains(ApiConstants.authRegister) ||
        options.path.contains(ApiConstants.authRefresh) ||
        options.path.contains(ApiConstants.authForgotPassword);

    if (!isAuthPublic) {
      final token = await storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Gestion du token expiré (401)
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains(ApiConstants.authRefresh) &&
        !err.requestOptions.path.contains(ApiConstants.authLogin)) {
      try {
        final refreshToken = await storage.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          // Requête dédiée avec une instance Dio isolée sans intercepteur pour éviter une boucle infinie
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: dio.options.baseUrl,
              connectTimeout: ApiConstants.connectTimeout,
              receiveTimeout: ApiConstants.receiveTimeout,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

          final response = await refreshDio.post(
            ApiConstants.authRefresh,
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200 && response.data != null) {
            final data = response.data;
            final tokens = data['tokens'] ?? data;
            final newAccessToken = tokens['accessToken'];
            final newRefreshToken = tokens['refreshToken'];

            if (newAccessToken != null) {
              await storage.saveAccessToken(newAccessToken);
              if (newRefreshToken != null) {
                await storage.saveRefreshToken(newRefreshToken);
              }

              // Rejouer la requête d'origine avec le nouveau jeton
              final options = err.requestOptions;
              options.headers['Authorization'] = 'Bearer $newAccessToken';

              final retryResponse = await dio.fetch(options);
              return handler.resolve(retryResponse);
            }
          }
        }
      } catch (e) {
        // En cas d'échec du refresh (ex: refresh token révoqué ou expiré)
        await storage.clearAllTokens();
        onSessionExpired?.call();
      }
    }

    return handler.next(err);
  }
}
