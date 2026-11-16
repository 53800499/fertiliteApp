import 'dart:convert';
import '../../../../core/security/secure_storage_helper.dart';
import '../../domain/repositories/fertility_repository.dart';
import '../datasources/fertility_remote_data_source.dart';
import '../models/fertility_models.dart';

class FertilityRepositoryImpl implements IFertilityRepository {
  final IFertilityRemoteDataSource remoteDataSource;
  final SecureStorageHelper? storage;

  const FertilityRepositoryImpl({
    required this.remoteDataSource,
    this.storage,
  });

  @override
  Future<PredictionModel?> getCachedCurrentPrediction() async {
    if (storage == null) return null;
    try {
      final cached = await storage!.getCache('cached_current_prediction');
      if (cached != null && cached.isNotEmpty) {
        return PredictionModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<PredictionModel> getCurrentPrediction() async {
    try {
      final prediction = await remoteDataSource.getCurrentPrediction();
      if (storage != null) {
        await storage!.saveCache('cached_current_prediction', jsonEncode(prediction.toJson()));
      }
      return prediction;
    } catch (e) {
      final cached = await getCachedCurrentPrediction();
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<PredictionModel> recalculateFertility({String? evaluationDate}) async {
    final prediction = await remoteDataSource.recalculateFertility(evaluationDate: evaluationDate);
    if (storage != null) {
      await storage!.saveCache('cached_current_prediction', jsonEncode(prediction.toJson()));
    }
    return prediction;
  }

  @override
  Future<List<FactorExplanationModel>> getCurrentFactors() {
    return remoteDataSource.getCurrentFactors();
  }

  String _calendarCacheKey(int year, int month) => 'cached_month_calendar_${year}_$month';

  @override
  Future<CalendarMonthModel?> getCachedMonthCalendar({int? year, int? month}) async {
    if (storage == null) return null;
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;
    try {
      final cached = await storage!.getCache(_calendarCacheKey(y, m));
      if (cached != null && cached.isNotEmpty) {
        return CalendarMonthModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<CalendarMonthModel> getMonthCalendar({int? year, int? month}) async {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;
    try {
      final calendar = await remoteDataSource.getMonthCalendar(year: y, month: m);
      if (storage != null) {
        await storage!.saveCache(_calendarCacheKey(y, m), jsonEncode(calendar.toJson()));
      }
      return calendar;
    } catch (e) {
      final cached = await getCachedMonthCalendar(year: y, month: m);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<PredictionModel>> getPredictionHistory({int limit = 10}) {
    return remoteDataSource.getPredictionHistory(limit: limit);
  }
}
