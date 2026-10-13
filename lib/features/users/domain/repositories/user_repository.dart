import '../../data/models/user_profile_model.dart';

abstract class IUserRepository {
  Future<FullUserProfileModel> getProfile();
  Future<FullUserProfileModel> updateProfile(UpdateProfileRequestModel request);
  Future<void> requestAccountDeletion({required String password, String? reason});
}
