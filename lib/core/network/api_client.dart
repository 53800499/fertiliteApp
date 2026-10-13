import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../security/secure_storage_helper.dart';
import 'auth_interceptor.dart';

class ApiClient {
  final Dio dio;
  final SecureStorageHelper storage;

  ApiClient._({required this.dio, required this.storage});

  factory ApiClient({
    String? baseUrl,
    SecureStorageHelper? storage,
    void Function()? onSessionExpired,
    void Function()? onOnline,
    void Function()? onOffline,
  }) {
    final effectiveStorage = storage ?? SecureStorageHelper();
    final effectiveBaseUrl = baseUrl ?? ApiConstants.defaultBaseUrl;

    final dio = Dio(
      BaseOptions(
        baseUrl: effectiveBaseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Intercepteur de détection de connectivité en direct
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          onOnline?.call();
          return handler.next(response);
        },
        onError: (err, handler) {
          final isNetworkError = err.type == DioExceptionType.connectionError ||
              (err.message != null && err.message!.toLowerCase().contains('socketexception')) ||
              (err.message != null && err.message!.toLowerCase().contains('failed host lookup'));
          if (isNetworkError) {
            onOffline?.call();
          }
          return handler.next(err);
        },
      ),
    );

    // Ajout de l'intercepteur d'authentification
    dio.interceptors.add(
      AuthInterceptor(
        storage: effectiveStorage,
        dio: dio,
        onSessionExpired: onSessionExpired,
      ),
    );

    // Logging en mode debug
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }

    return ApiClient._(dio: dio, storage: effectiveStorage);
  }
}
