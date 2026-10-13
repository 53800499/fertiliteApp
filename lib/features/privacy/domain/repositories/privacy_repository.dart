import '../../../users/data/models/user_profile_model.dart';
import '../../data/models/privacy_models.dart';

abstract class IPrivacyRepository {
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
