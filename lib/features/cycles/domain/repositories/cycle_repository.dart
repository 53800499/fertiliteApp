import '../../data/models/cycle_models.dart';

abstract class ICycleRepository {
  Future<CycleModel> startCycle(StartCycleRequestModel request);
  Future<JourReglesModel> logDayFlow(LogFlowRequestModel request);
  Future<List<CycleModel>> getCycles();
  Future<CycleModel?> getActiveCycle();
  Future<CycleModel> getCycleById(String id);
  Future<CycleModel> updateCycle(String id, UpdateCycleRequestModel request);
  Future<void> deleteCycle(String id);
  Future<CycleStatsModel> getCycleStats();
}

