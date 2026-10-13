import 'dart:convert';
import '../../../../core/security/secure_storage_helper.dart';
import '../../domain/repositories/cycle_repository.dart';
import '../../data/datasources/cycle_remote_data_source.dart';
import '../../data/models/cycle_models.dart';

class CycleRepositoryImpl implements ICycleRepository {
  final ICycleRemoteDataSource remoteDataSource;
  final SecureStorageHelper? storage;

  CycleRepositoryImpl({
    required this.remoteDataSource,
    this.storage,
  });

  @override
  Future<CycleModel> startCycle(StartCycleRequestModel request) {
    return remoteDataSource.startCycle(request);
  }

  @override
  Future<JourReglesModel> logDayFlow(LogFlowRequestModel request) {
    return remoteDataSource.logDayFlow(request);
  }

  @override
  Future<List<CycleModel>> getCycles() async {
    try {
      final cycles = await remoteDataSource.getCycles();
      if (storage != null) {
        final jsonStr = jsonEncode(cycles.map((c) => c.toJson()).toList());
        await storage!.saveCache('cached_cycles_list', jsonStr);
      }
      return cycles;
    } catch (e) {
      if (storage != null) {
        final cached = await storage!.getCache('cached_cycles_list');
        if (cached != null && cached.isNotEmpty) {
          final list = jsonDecode(cached) as List<dynamic>;
          return list
              .map((item) => CycleModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      rethrow;
    }
  }

  @override
  Future<CycleModel?> getActiveCycle() async {
    try {
      final active = await remoteDataSource.getActiveCycle();
      if (storage != null) {
        if (active != null) {
          await storage!.saveCache('cached_active_cycle', jsonEncode(active.toJson()));
        } else {
          await storage!.deleteCache('cached_active_cycle');
        }
      }
      return active;
    } catch (e) {
      if (storage != null) {
        final cached = await storage!.getCache('cached_active_cycle');
        if (cached != null && cached.isNotEmpty) {
          return CycleModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        }
      }
      rethrow;
    }
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
  Future<CycleStatsModel> getCycleStats() async {
    try {
      final stats = await remoteDataSource.getCycleStats();
      if (storage != null) {
        await storage!.saveCache('cached_cycle_stats', jsonEncode(stats.toJson()));
      }
      return stats;
    } catch (e) {
      if (storage != null) {
        final cached = await storage!.getCache('cached_cycle_stats');
        if (cached != null && cached.isNotEmpty) {
          return CycleStatsModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        }
      }
      rethrow;
    }
  }
}
