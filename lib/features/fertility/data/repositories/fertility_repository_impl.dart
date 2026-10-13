import '../../domain/repositories/fertility_repository.dart';
import '../datasources/fertility_remote_data_source.dart';
import '../models/fertility_models.dart';

class FertilityRepositoryImpl implements IFertilityRepository {
  final IFertilityRemoteDataSource remoteDataSource;

  const FertilityRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PredictionModel> getCurrentPrediction() {
    return remoteDataSource.getCurrentPrediction();
  }

  @override
  Future<PredictionModel> recalculateFertility({String? evaluationDate}) {
    return remoteDataSource.recalculateFertility(evaluationDate: evaluationDate);
  }

  @override
  Future<List<FactorExplanationModel>> getCurrentFactors() {
    return remoteDataSource.getCurrentFactors();
  }

  @override
  Future<CalendarMonthModel> getMonthCalendar({int? year, int? month}) {
    return remoteDataSource.getMonthCalendar(year: year, month: month);
  }

  @override
  Future<List<PredictionModel>> getPredictionHistory({int limit = 10}) {
    return remoteDataSource.getPredictionHistory(limit: limit);
  }
}
