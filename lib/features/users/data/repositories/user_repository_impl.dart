import 'dart:convert';
import '../../../../core/security/secure_storage_helper.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_data_source.dart';
import '../models/user_profile_model.dart';

class UserRepositoryImpl implements IUserRepository {
  final IUserRemoteDataSource remoteDataSource;
  final SecureStorageHelper? storage;

  UserRepositoryImpl({
    required this.remoteDataSource,
    this.storage,
  });

  @override
  Future<FullUserProfileModel> getProfile() async {
    try {
      final profile = await remoteDataSource.getProfile();
      if (storage != null) {
        await storage!.saveCache('cached_user_profile', jsonEncode(profile.toJson()));
      }
      return profile;
    } catch (e) {
      if (storage != null) {
        final cached = await storage!.getCache('cached_user_profile');
        if (cached != null && cached.isNotEmpty) {
          return FullUserProfileModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        }
      }
      rethrow;
    }
  }

  @override
  Future<FullUserProfileModel> updateProfile(UpdateProfileRequestModel request) async {
    final updated = await remoteDataSource.updateProfile(request);
    if (storage != null) {
      await storage!.saveCache('cached_user_profile', jsonEncode(updated.toJson()));
    }
    return updated;
  }

  @override
  Future<void> requestAccountDeletion({required String password, String? reason}) {
    return remoteDataSource.requestAccountDeletion(password: password, reason: reason);
  }
}
