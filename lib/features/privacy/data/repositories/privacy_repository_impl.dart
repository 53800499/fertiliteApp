import '../../../users/data/models/user_profile_model.dart';
import '../../domain/repositories/privacy_repository.dart';
import '../datasources/privacy_remote_data_source.dart';
import '../models/privacy_models.dart';

class PrivacyRepositoryImpl implements IPrivacyRepository {
  final IPrivacyRemoteDataSource remoteDataSource;

  PrivacyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserPrivacySettingsModel> getSettings() {
    return remoteDataSource.getSettings();
  }

  @override
  Future<UserPrivacySettingsModel> updateSettings(UserPrivacySettingsModel settings) {
    return remoteDataSource.updateSettings(settings);
  }

  @override
  Future<List<ConsentementModel>> getConsents() {
    return remoteDataSource.getConsents();
  }

  @override
  Future<void> recordConsent({
    required String typeConsentement,
    required String versionDocument,
    required bool accepte,
  }) {
    return remoteDataSource.recordConsent(
      typeConsentement: typeConsentement,
      versionDocument: versionDocument,
      accepte: accepte,
    );
  }

  @override
  Future<List<ActiveSessionModel>> getActiveSessions() {
    return remoteDataSource.getActiveSessions();
  }

  @override
  Future<void> revokeSession(String sessionId) {
    return remoteDataSource.revokeSession(sessionId);
  }
}
