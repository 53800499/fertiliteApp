import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/api_exception.dart';
import '../../../users/data/models/user_profile_model.dart';
import '../models/privacy_models.dart';

abstract class IPrivacyRemoteDataSource {
  Future<UserPrivacySettingsModel> getSettings();
  Future<UserPrivacySettingsModel> updateSettings(UserPrivacySettingsModel settings);
  Future<List<ConsentementModel>> getConsents();
  Future<void> recordConsent({
    required String typeConsentement,
    required String versionDocument,
    required bool accepte,
  });
  Future<List<ActiveSessionModel>> getActiveSessions();
  Future<void> revokeSession(String sessionId);
}

class PrivacyRemoteDataSourceImpl implements IPrivacyRemoteDataSource {
  final Dio dio;

  PrivacyRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserPrivacySettingsModel> getSettings() async {
    try {
      final response = await dio.get(ApiConstants.privacySettings);
      return UserPrivacySettingsModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<UserPrivacySettingsModel> updateSettings(UserPrivacySettingsModel settings) async {
    try {
      final response = await dio.patch(
        ApiConstants.privacySettings,
        data: settings.toJson(),
      );
      return UserPrivacySettingsModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<ConsentementModel>> getConsents() async {
    try {
      final response = await dio.get(ApiConstants.privacyConsents);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => ConsentementModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> recordConsent({
    required String typeConsentement,
    required String versionDocument,
    required bool accepte,
  }) async {
    try {
      await dio.post(
        ApiConstants.privacyConsents,
        data: {
          'typeConsentement': typeConsentement,
          'versionDocument': versionDocument,
          'accepte': accepte,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<ActiveSessionModel>> getActiveSessions() async {
    try {
      final response = await dio.get(ApiConstants.privacySessions);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((e) => ActiveSessionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    try {
      await dio.delete(ApiConstants.privacyRevokeSession(sessionId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
