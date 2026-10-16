import '../../domain/repositories/observation_repository.dart';
import '../datasources/observation_remote_data_source.dart';
import '../datasources/observation_sync_manager.dart';
import '../models/observation_models.dart';

class ObservationRepositoryImpl implements IObservationRepository {
  final IObservationRemoteDataSource remoteDataSource;
  final ObservationSyncManager? syncManager;

  ObservationRepositoryImpl({
    required this.remoteDataSource,
    this.syncManager,
  });

  @override
  Future<List<TypeSymptomeModel>> getSymptomCatalog() async {
    try {
      final catalog = await remoteDataSource.getSymptomCatalog();
      if (syncManager != null) {
        await syncManager!.cacheSymptomCatalog(catalog);
      }
      return catalog;
    } catch (_) {
      if (syncManager != null) {
        final cached = await syncManager!.getCachedSymptomCatalog();
        if (cached.isNotEmpty) return cached;
      }
      rethrow;
    }
  }

  @override
  Future<DayObservationsModel> getDayObservations(String date) async {
    try {
      final remoteDay = await remoteDataSource.getDayObservations(date);
      if (syncManager != null) {
        final isPending = await syncManager!.isDatePending(date);
        final dayWithPending = remoteDay.copyWith(isPendingSync: isPending);
        await syncManager!.cacheDayObservations(dayWithPending);
        return dayWithPending;
      }
      return remoteDay;
    } catch (_) {
      if (syncManager != null) {
        final cached = await syncManager!.getCachedDayObservations(date);
        if (cached != null) return cached;
      }
      // Si aucun cache ni réseau, renvoyer une coquille vide pour ce jour sans crasher
      return DayObservationsModel(date: date);
    }
  }

  @override
  Future<DayObservationsModel> saveDayObservation(SaveDayObservationRequest request) async {
    try {
      final saved = await remoteDataSource.saveDayObservation(request);
      if (syncManager != null) {
        final isPending = await syncManager!.isDatePending(request.date);
        final dayWithStatus = saved.copyWith(isPendingSync: isPending);
        await syncManager!.cacheDayObservations(dayWithStatus);
        return dayWithStatus;
      }
      return saved;
    } catch (_) {
      if (syncManager != null) {
        // Enregistrement optimiste en file d'attente hors-ligne
        return await syncManager!.applyOptimisticSave(request);
      }
      rethrow;
    }
  }

  @override
  Future<TemperatureBasaleModel> logTemperature(TemperatureBasaleModel temp) {
    return remoteDataSource.logTemperature(temp);
  }

  @override
  Future<GlaireCervicaleModel> logCervicalMucus(GlaireCervicaleModel mucus) {
    return remoteDataSource.logCervicalMucus(mucus);
  }

  @override
  Future<TestOvulationModel> logLhTest(TestOvulationModel test) {
    return remoteDataSource.logLhTest(test);
  }

  @override
  Future<void> deleteTemperature(String date) async {
    try {
      await remoteDataSource.deleteTemperature(date);
      if (syncManager != null) {
        final day = await syncManager!.getCachedDayObservations(date);
        if (day != null) {
          await syncManager!.cacheDayObservations(day.copyWith(clearTemperature: true));
        }
      }
    } catch (_) {
      if (syncManager != null) {
        await syncManager!.applyOptimisticDeleteTemperature(date);
        return;
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteCervicalMucus(String date) async {
    try {
      await remoteDataSource.deleteCervicalMucus(date);
      if (syncManager != null) {
        final day = await syncManager!.getCachedDayObservations(date);
        if (day != null) {
          await syncManager!.cacheDayObservations(day.copyWith(clearGlaire: true));
        }
      }
    } catch (_) {
      if (syncManager != null) {
        await syncManager!.applyOptimisticDeleteMucus(date);
        return;
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteLhTest(String id) async {
    try {
      await remoteDataSource.deleteLhTest(id);
    } catch (_) {
      // Si la suppression distante échoue hors ligne
      if (syncManager != null) {
        final nowStr = DateTime.now().toIso8601String().substring(0, 10);
        await syncManager!.applyOptimisticDeleteLh(nowStr, id);
        return;
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteSymptom(String id) async {
    try {
      await remoteDataSource.deleteSymptom(id);
    } catch (_) {
      if (syncManager != null) {
        final nowStr = DateTime.now().toIso8601String().substring(0, 10);
        await syncManager!.applyOptimisticDeleteSymptom(nowStr, id);
        return;
      }
      rethrow;
    }
  }

  @override
  Future<RapportSexuelModel> logIntercourse(RapportSexuelModel intercourse) {
    return remoteDataSource.logIntercourse(intercourse);
  }

  @override
  Future<void> deleteIntercourse(String date) async {
    try {
      await remoteDataSource.deleteIntercourse(date);
      if (syncManager != null) {
        final day = await syncManager!.getCachedDayObservations(date);
        if (day != null) {
          await syncManager!.cacheDayObservations(day.copyWith(clearRapport: true));
        }
      }
    } catch (_) {
      if (syncManager != null) {
        await syncManager!.applyOptimisticDeleteIntercourse(date);
        return;
      }
      rethrow;
    }
  }

  @override
  Future<BbtAnalysisModel> getBbtAnalysis({String? startDate, String? endDate}) async {
    try {
      final analysis = await remoteDataSource.getBbtAnalysis(startDate: startDate, endDate: endDate);
      if (syncManager != null) {
        await syncManager!.cacheBbtAnalysis(analysis);
      }
      return analysis;
    } catch (_) {
      if (syncManager != null) {
        final cached = await syncManager!.getCachedBbtAnalysis();
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  @override
  Future<ObservationSyncReport> syncPendingObservations() async {
    if (syncManager == null) {
      return ObservationSyncReport(
        syncedCount: 0,
        failedCount: 0,
        remainingCount: 0,
        syncedAt: DateTime.now(),
        message: 'Gestionnaire de synchronisation non initialisé.',
      );
    }
    return syncManager!.flushQueue(remoteDataSource);
  }

  @override
  Future<int> getPendingSyncCount() async {
    if (syncManager == null) return 0;
    return syncManager!.getPendingCount();
  }
}

