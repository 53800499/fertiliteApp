import '../../data/models/user_profile_model.dart';

abstract class IUserRepository {
  FullUserProfileModel? get currentProfile;
  Stream<FullUserProfileModel> get profileStream;
  Future<FullUserProfileModel> getProfile();
  Future<FullUserProfileModel?> getCachedProfile();
  Future<FullUserProfileModel> updateProfile(UpdateProfileRequestModel request);
  Future<void> requestAccountDeletion({required String password, String? reason});
}
