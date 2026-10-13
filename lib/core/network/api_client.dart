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
