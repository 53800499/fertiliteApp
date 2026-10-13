import '../../domain/repositories/cycle_repository.dart';
import '../../data/datasources/cycle_remote_data_source.dart';
import '../../data/models/cycle_models.dart';

class CycleRepositoryImpl implements ICycleRepository {
  final ICycleRemoteDataSource remoteDataSource;

  CycleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<CycleModel> startCycle(StartCycleRequestModel request) {
    return remoteDataSource.startCycle(request);
  }

  @override
  Future<JourReglesModel> logDayFlow(LogFlowRequestModel request) {
    return remoteDataSource.logDayFlow(request);
  }

  @override
  Future<List<CycleModel>> getCycles() {
    return remoteDataSource.getCycles();
  }

  @override
  Future<CycleModel?> getActiveCycle() {
    return remoteDataSource.getActiveCycle();
  }

  @override
  Future<CycleModel> getCycleById(String id) {
    return remoteDataSource.getCycleById(id);
  }

  @override
  Future<CycleModel> updateCycle(String id, UpdateCycleRequestModel request) {
    return remoteDataSource.updateCycle(id, request);
  }

  @override
  Future<void> deleteCycle(String id) {
    return remoteDataSource.deleteCycle(id);
  }

  @override
  Future<CycleStatsModel> getCycleStats() {
    return remoteDataSource.getCycleStats();
  }
}

