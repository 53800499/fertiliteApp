import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/api_exception.dart';
import '../models/user_profile_model.dart';

abstract class IUserRemoteDataSource {
  Future<FullUserProfileModel> getProfile();
  Future<FullUserProfileModel> updateProfile(UpdateProfileRequestModel request);
  Future<void> requestAccountDeletion({required String password, String? reason});
}

class UserRemoteDataSourceImpl implements IUserRemoteDataSource {
  final Dio dio;

  UserRemoteDataSourceImpl({required this.dio});

  @override
  Future<FullUserProfileModel> getProfile() async {
    try {
      final response = await dio.get(ApiConstants.userProfile);
      return FullUserProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<FullUserProfileModel> updateProfile(UpdateProfileRequestModel request) async {
    try {
      final response = await dio.put(
        ApiConstants.userProfile,
        data: request.toJson(),
      );
      // Le backend renvoie le profil mis à jour
      if (response.data is Map<String, dynamic>) {
        return FullUserProfileModel.fromJson(response.data as Map<String, dynamic>);
      }
      return getProfile();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> requestAccountDeletion({required String password, String? reason}) async {
    try {
      final payload = <String, dynamic>{'motDePasse': password};
      if (reason != null) payload['motif'] = reason;
      await dio.post(
        ApiConstants.userDeleteRequest,
        data: payload,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
