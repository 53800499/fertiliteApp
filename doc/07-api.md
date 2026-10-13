# 07 — Couche Réseau & Client API Mobile (Dio)
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

### Informations documentaires
- **Projet** : FertiliteApp (Client Mobile Flutter)
- **Client HTTP** : **Dio** 5.x
- **Sérialisation** : `json_serializable` / `freezed`
- **Date** : 24 septembre 2026

---

## 1. Configuration du Client Dio (`lib/core/network/`)

```dart
// lib/core/network/api_client.dart
import 'package:dio/dio.dart';
import '../security/secure_storage_helper.dart';

class ApiClient {
  static Dio createDioClient(SecureStorageHelper storage) {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.fertiliteapp.com/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Injection des intercepteurs de sécurité et d'authentification
    dio.interceptors.addAll([
      AuthInterceptor(storage: storage, dio: dio),
      CleanLoggingInterceptor(),
    ]);

    return dio;
  }
}
```

---

## 2. Gestion Automatique du Refresh Token

L'intercepteur `AuthInterceptor` gère silencieusement le rafraîchissement des jetons expirés :

```dart
class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageHelper storage;
  final Dio dio;

  AuthInterceptor({required this.storage, required this.dio});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Si le token est expiré (401 Unauthorized)
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken = await storage.getRefreshToken();
        if (refreshToken != null) {
          // Requête isolée pour obtenir un nouveau token
          final response = await dio.post('/auth/refresh', data: {
            'refreshToken': refreshToken,
          });

          final newAccessToken = response.data['accessToken'];
          await storage.saveAccessToken(newAccessToken);

          // Rejouer la requête d'origine avec le nouveau jeton
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        }
      } catch (e) {
        // En cas d'échec du refresh, déconnexion forcée de l'utilisatrice
        await storage.clearAllTokens();
      }
    }
    return handler.next(err);
  }
}
```
