import 'package:dio/dio.dart';

/// Exception levée lors d'erreurs réseau ou HTTP avec le backend
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException({
    required this.message,
    this.statusCode,
    this.details,
  });

  factory ApiException.fromDioError(DioException error) {
    int? statusCode = error.response?.statusCode;
    String message = 'Une erreur est survenue lors de la communication avec le serveur.';
    dynamic details;

    if (error.response?.data != null) {
      final data = error.response!.data;
      if (data is Map<String, dynamic>) {
        details = data;
        final rawMessage = data['message'];
        if (rawMessage is List && rawMessage.isNotEmpty) {
          // Validation pipes NestJS retournent souvent un tableau de messages
          message = rawMessage.join('\n');
        } else if (rawMessage is String && rawMessage.isNotEmpty) {
          message = rawMessage;
        } else if (data['error'] is String) {
          message = data['error'];
        }
      }
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Délai d\'attente dépassé. Veuillez vérifier votre connexion.';
          break;
        case DioExceptionType.connectionError:
          message = 'Impossible de contacter le serveur. Vérifiez votre connexion internet ou si le serveur est démarré.';
          break;
        case DioExceptionType.cancel:
          message = 'La requête a été annulée.';
          break;
        default:
          message = error.message ?? message;
          break;
      }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      details: details,
    );
  }

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}
