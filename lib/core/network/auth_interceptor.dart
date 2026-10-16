import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../security/secure_storage_helper.dart';

class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageHelper storage;
  final Dio dio;
  final void Function()? onSessionExpired;

  // Mutex de déduplication pour éviter les collisions sur la rotation des Refresh Tokens
  Future<String?>? _refreshFuture;

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

  Future<String?> _performTokenRefresh() async {
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await storage.clearAllTokens();
      onSessionExpired?.call();
      return null;
    }

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    try {
      final response = await refreshDio.post(
        ApiConstants.authRefresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final tokens = data['tokens'] ?? data;
        final newAccessToken = tokens['accessToken'] as String?;
        final newRefreshToken = tokens['refreshToken'] as String?;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await storage.saveAccessToken(newAccessToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await storage.saveRefreshToken(newRefreshToken);
          }
          return newAccessToken;
        }
      }
      throw Exception('Format de jeton invalide lors du renouvellement');
    } catch (e) {
      await storage.clearAllTokens();
      onSessionExpired?.call();
      rethrow;
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final isAuthEndpoint = path.contains(ApiConstants.authRefresh) ||
        path.contains(ApiConstants.authLogin) ||
        path.contains(ApiConstants.authRegister) ||
        path.contains(ApiConstants.authLogout);

    // Gestion centralisée et thread-safe du token expiré (401)
    if (err.response?.statusCode == 401 && !isAuthEndpoint) {
      try {
        _refreshFuture ??= _performTokenRefresh();
        final newAccessToken = await _refreshFuture;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          // Rejouer la requête d'origine avec le nouveau jeton
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          final retryResponse = await dio.fetch(options);
          return handler.resolve(retryResponse);
        }
      } catch (e) {
        // En cas d'échec du refresh, la session est déjà purgée dans _performTokenRefresh
        return handler.next(err);
      } finally {
        _refreshFuture = null;
      }
    }

    return handler.next(err);
  }
}
