import 'package:dio/dio.dart';
import '../models/fertility_models.dart';
import '../../../../core/error/api_exception.dart';

abstract class IFertilityRemoteDataSource {
  Future<PredictionModel> getCurrentPrediction();
  Future<PredictionModel> recalculateFertility({String? evaluationDate});
  Future<List<FactorExplanationModel>> getCurrentFactors();
  Future<CalendarMonthModel> getMonthCalendar({int? year, int? month});
  Future<List<PredictionModel>> getPredictionHistory({int limit = 10});
}

class FertilityRemoteDataSourceImpl implements IFertilityRemoteDataSource {
  final Dio dio;

  const FertilityRemoteDataSourceImpl({required this.dio});

  @override
  Future<PredictionModel> getCurrentPrediction() async {
    try {
      final response = await dio.get('/fertility/current');
      return PredictionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<PredictionModel> recalculateFertility({String? evaluationDate}) async {
    try {
      final response = await dio.post(
        '/fertility/recalculate',
        data: evaluationDate != null ? {'evaluationDate': evaluationDate} : {},
      );
      return PredictionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<FactorExplanationModel>> getCurrentFactors() async {
    try {
      final response = await dio.get('/fertility/current/factors');
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((f) => FactorExplanationModel.fromJson(f as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<CalendarMonthModel> getMonthCalendar({int? year, int? month}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (year != null) queryParams['year'] = year;
      if (month != null) queryParams['month'] = month;

      final response = await dio.get('/calendar/month', queryParameters: queryParams);
      return CalendarMonthModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<PredictionModel>> getPredictionHistory({int limit = 10}) async {
    try {
      final response = await dio.get(
        '/fertility/history',
        queryParameters: {'limit': limit},
      );
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map((p) => PredictionModel.fromJson(p as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
