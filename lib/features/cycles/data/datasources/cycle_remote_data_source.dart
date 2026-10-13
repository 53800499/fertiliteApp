import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/api_exception.dart';
import '../models/cycle_models.dart';

abstract class ICycleRemoteDataSource {
  Future<CycleModel> startCycle(StartCycleRequestModel request);
  Future<JourReglesModel> logDayFlow(LogFlowRequestModel request);
  Future<List<CycleModel>> getCycles();
  Future<CycleModel?> getActiveCycle();
  Future<CycleModel> getCycleById(String id);
  Future<CycleModel> updateCycle(String id, UpdateCycleRequestModel request);
  Future<void> deleteCycle(String id);
  Future<CycleStatsModel> getCycleStats();
}

class CycleRemoteDataSourceImpl implements ICycleRemoteDataSource {
  final Dio dio;

  CycleRemoteDataSourceImpl({required this.dio});

  @override
  Future<CycleModel> startCycle(StartCycleRequestModel request) async {
    try {
      final response = await dio.post(
        ApiConstants.cyclesStart,
        data: request.toJson(),
      );
      return CycleModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<JourReglesModel> logDayFlow(LogFlowRequestModel request) async {
    try {
      final response = await dio.post(
        ApiConstants.cyclesDays,
        data: request.toJson(),
      );
      return JourReglesModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<CycleModel>> getCycles() async {
    try {
      final response = await dio.get(ApiConstants.cyclesList);
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((c) => CycleModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<CycleModel?> getActiveCycle() async {
    try {
      final response = await dio.get(ApiConstants.cyclesActive);
      if (response.data == null || (response.data is String && (response.data as String).isEmpty)) {
        return null;
      }
      return CycleModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<CycleModel> getCycleById(String id) async {
    try {
      final response = await dio.get(ApiConstants.cycleById(id));
      return CycleModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<CycleModel> updateCycle(String id, UpdateCycleRequestModel request) async {
    try {
      final response = await dio.put(
        ApiConstants.cycleById(id),
        data: request.toJson(),
      );
      return CycleModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteCycle(String id) async {
    try {
      await dio.delete(ApiConstants.cycleById(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<CycleStatsModel> getCycleStats() async {
    try {
      final response = await dio.get(ApiConstants.cyclesStats);
      return CycleStatsModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

