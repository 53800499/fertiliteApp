import '../../data/models/fertility_models.dart';

abstract class IFertilityRepository {
  Future<PredictionModel> getCurrentPrediction();
  Future<PredictionModel?> getCachedCurrentPrediction();
  Future<PredictionModel> recalculateFertility({String? evaluationDate});
  Future<List<FactorExplanationModel>> getCurrentFactors();
  Future<CalendarMonthModel> getMonthCalendar({int? year, int? month});
  Future<CalendarMonthModel?> getCachedMonthCalendar({int? year, int? month});
  Future<List<PredictionModel>> getPredictionHistory({int limit = 10});
}
