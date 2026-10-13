import '../../data/models/fertility_models.dart';

abstract class IFertilityRepository {
  Future<PredictionModel> getCurrentPrediction();
  Future<PredictionModel> recalculateFertility({String? evaluationDate});
  Future<List<FactorExplanationModel>> getCurrentFactors();
  Future<CalendarMonthModel> getMonthCalendar({int? year, int? month});
  Future<List<PredictionModel>> getPredictionHistory({int limit = 10});
}
