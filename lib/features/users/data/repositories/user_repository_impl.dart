import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_data_source.dart';
import '../models/user_profile_model.dart';

class UserRepositoryImpl implements IUserRepository {
  final IUserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});

  @override
  Future<FullUserProfileModel> getProfile() {
    return remoteDataSource.getProfile();
  }

  @override
  Future<FullUserProfileModel> updateProfile(UpdateProfileRequestModel request) {
    return remoteDataSource.updateProfile(request);
  }

  @override
  Future<void> requestAccountDeletion({required String password, String? reason}) {
    return remoteDataSource.requestAccountDeletion(password: password, reason: reason);
  }
}
