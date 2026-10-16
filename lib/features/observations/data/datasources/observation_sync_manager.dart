import 'dart:convert';
import 'dart:math';
import '../../../../core/security/secure_storage_helper.dart';
import '../models/observation_models.dart';
import 'observation_remote_data_source.dart';

/// Gestionnaire de la file d'attente hors-ligne et de la synchronisation bidirectionnelle (Option C)
class ObservationSyncManager {
  final SecureStorageHelper storage;

  ObservationSyncManager({required this.storage});

  static const String _keySyncQueue = 'obs_sync_queue';
  static const String _keySymptomCatalog = 'obs_symptom_catalog';
  static const String _keyBbtAnalysis = 'obs_bbt_analysis';
  static const String _keyHistory = 'obs_history';
  static const String _keyLastSync = 'obs_last_sync_timestamp';
  static const String _keyCachedDaysPrefix = 'obs_day_';

  /// Générateur de UUID v4 standard conforme RFC 4122
  static String generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 10xx
    return [
      bytes.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      bytes.sublist(4, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      bytes.sublist(6, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      bytes.sublist(8, 10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      bytes.sublist(10, 16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    ].join('-');
  }

  // ===========================================================================
  // 1. File d'attente hors-ligne persistante (Persistent Mutation Queue)
  // ===========================================================================

  /// Récupère la liste des mutations en attente
  Future<List<QueuedObservationMutation>> getQueue() async {
    try {
      final raw = await storage.getCache(_keySyncQueue);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => QueuedObservationMutation.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Sauvegarde la file d'attente
  Future<void> _saveQueue(List<QueuedObservationMutation> queue) async {
    try {
      final raw = jsonEncode(queue.map((m) => m.toJson()).toList());
      await storage.saveCache(_keySyncQueue, raw);
    } catch (_) {}
  }

  /// Ajoute une mutation à la file d'attente
  Future<void> enqueueMutation(QueuedObservationMutation mutation) async {
    final queue = await getQueue();
    // Éviter les doublons stricts pour la même action/date
    queue.removeWhere((item) => item.id == mutation.id);
    queue.add(mutation);
    await _saveQueue(queue);
  }

  /// Supprime une mutation traitée de la file d'attente
  Future<void> dequeueMutation(String id) async {
    final queue = await getQueue();
    queue.removeWhere((item) => item.id == id);
    await _saveQueue(queue);
  }

  /// Nombre de mutations actuellement en attente
  Future<int> getPendingCount() async {
    final queue = await getQueue();
    return queue.length;
  }

  /// Vérifie si une date précise a une mutation en attente
  Future<bool> isDatePending(String date) async {
    final queue = await getQueue();
    return queue.any((m) => m.date == date);
  }

  // ===========================================================================
  // 2. Cache Local Persistant (Local Caching)
  // ===========================================================================

  /// Met en cache les observations d'un jour précis
  Future<void> cacheDayObservations(DayObservationsModel day) async {
    try {
      final normalizedDate = day.date.length >= 10 ? day.date.substring(0, 10) : day.date;
      await storage.saveCache('$_keyCachedDaysPrefix$normalizedDate', jsonEncode(day.toJson()));
    } catch (_) {}
  }

  /// Récupère les observations d'un jour depuis le cache local
  Future<DayObservationsModel?> getCachedDayObservations(String date) async {
    try {
      final normalizedDate = date.length >= 10 ? date.substring(0, 10) : date;
      final raw = await storage.getCache('$_keyCachedDaysPrefix$normalizedDate');
      if (raw == null || raw.isEmpty) return null;
      return DayObservationsModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Met en cache le catalogue de symptômes
  Future<void> cacheSymptomCatalog(List<TypeSymptomeModel> catalog) async {
    try {
      final jsonStr = jsonEncode(catalog.map((c) => c.toJson()).toList());
      await storage.saveCache(_keySymptomCatalog, jsonStr);
    } catch (_) {}
  }

  /// Récupère le catalogue de symptômes mis en cache
  Future<List<TypeSymptomeModel>> getCachedSymptomCatalog() async {
    try {
      final raw = await storage.getCache(_keySymptomCatalog);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => TypeSymptomeModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Met en cache l'analyse thermique BBT
  Future<void> cacheBbtAnalysis(BbtAnalysisModel analysis) async {
    try {
      await storage.saveCache(_keyBbtAnalysis, jsonEncode(analysis.toJson()));
    } catch (_) {}
  }

  /// Récupère l'analyse thermique BBT depuis le cache
  Future<BbtAnalysisModel?> getCachedBbtAnalysis() async {
    try {
      final raw = await storage.getCache(_keyBbtAnalysis);
      if (raw == null || raw.isEmpty) return null;
      return BbtAnalysisModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Met en cache l'historique brut des observations
  Future<void> cacheHistory(Map<String, dynamic> history) async {
    try {
      await storage.saveCache(_keyHistory, jsonEncode(history));
    } catch (_) {}
  }

  /// Récupère l'historique brut des observations mis en cache
  Future<Map<String, dynamic>?> getCachedHistory() async {
    try {
      final raw = await storage.getCache(_keyHistory);
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // 3. Mutations Optimistes Hors-Ligne (Optimistic Local Updates)
  // ===========================================================================

  /// Applique immédiatement un enregistrement localement et l'empile dans la file
  Future<DayObservationsModel> applyOptimisticSave(SaveDayObservationRequest request) async {
    final dateStr = request.date.length >= 10 ? request.date.substring(0, 10) : request.date;
    final existing = await getCachedDayObservations(dateStr);

    final updatedSymptomes = <ObservationSymptomeModel>[];
    if (request.symptomes != null && request.symptomes!.isNotEmpty) {
      updatedSymptomes.addAll(request.symptomes!);
    } else if (existing != null) {
      updatedSymptomes.addAll(existing.symptomes);
    }

    final updatedTestsLh = <TestOvulationModel>[];
    if (request.testLh != null) {
      updatedTestsLh.add(request.testLh!);
    } else if (existing != null) {
      updatedTestsLh.addAll(existing.testsLh);
    }

    final optimisticDay = DayObservationsModel(
      date: dateStr,
      temperature: request.temperature ?? existing?.temperature,
      glaire: request.glaire ?? existing?.glaire,
      testsLh: updatedTestsLh,
      symptomes: updatedSymptomes,
      isPendingSync: true,
    );

    // 1. Sauvegarde dans le cache local
    await cacheDayObservations(optimisticDay);

    // 2. Empilage de la mutation dans la file d'attente
    final mutation = QueuedObservationMutation(
      id: generateUuidV4(),
      type: ObservationSyncMutationType.saveDayObservation,
      date: dateStr,
      request: request,
      clientTimestamp: DateTime.now(),
    );
    await enqueueMutation(mutation);

    return optimisticDay;
  }

  /// Applique immédiatement la suppression de température localement
  Future<DayObservationsModel> applyOptimisticDeleteTemperature(String date) async {
    final dateStr = date.length >= 10 ? date.substring(0, 10) : date;
    final existing = await getCachedDayObservations(dateStr);
    final updated = (existing ?? DayObservationsModel(date: dateStr)).copyWith(
      clearTemperature: true,
      isPendingSync: true,
    );
    await cacheDayObservations(updated);

    final mutation = QueuedObservationMutation(
      id: generateUuidV4(),
      type: ObservationSyncMutationType.deleteTemperature,
      date: dateStr,
      clientTimestamp: DateTime.now(),
    );
    await enqueueMutation(mutation);

    return updated;
  }

  /// Applique immédiatement la suppression de glaire cervicale localement
  Future<DayObservationsModel> applyOptimisticDeleteMucus(String date) async {
    final dateStr = date.length >= 10 ? date.substring(0, 10) : date;
    final existing = await getCachedDayObservations(dateStr);
    final updated = (existing ?? DayObservationsModel(date: dateStr)).copyWith(
      clearGlaire: true,
      isPendingSync: true,
    );
    await cacheDayObservations(updated);

    final mutation = QueuedObservationMutation(
      id: generateUuidV4(),
      type: ObservationSyncMutationType.deleteCervicalMucus,
      date: dateStr,
      clientTimestamp: DateTime.now(),
    );
    await enqueueMutation(mutation);

    return updated;
  }

  /// Applique immédiatement la suppression d'un test LH localement
  Future<DayObservationsModel> applyOptimisticDeleteLh(String date, String id) async {
    final dateStr = date.length >= 10 ? date.substring(0, 10) : date;
    final existing = await getCachedDayObservations(dateStr);
    final updatedTests = List<TestOvulationModel>.from(existing?.testsLh ?? [])
      ..removeWhere((t) => t.id == id);

    final updated = (existing ?? DayObservationsModel(date: dateStr)).copyWith(
      testsLh: updatedTests,
      isPendingSync: true,
    );
    await cacheDayObservations(updated);

    final mutation = QueuedObservationMutation(
      id: generateUuidV4(),
      type: ObservationSyncMutationType.deleteLhTest,
      date: dateStr,
      targetId: id,
      clientTimestamp: DateTime.now(),
    );
    await enqueueMutation(mutation);

    return updated;
  }

  /// Applique immédiatement la suppression d'un symptôme localement
  Future<DayObservationsModel> applyOptimisticDeleteSymptom(String date, String id) async {
    final dateStr = date.length >= 10 ? date.substring(0, 10) : date;
    final existing = await getCachedDayObservations(dateStr);
    final updatedSymptoms = List<ObservationSymptomeModel>.from(existing?.symptomes ?? [])
      ..removeWhere((s) => s.id == id || s.typeSymptomeId == id);

    final updated = (existing ?? DayObservationsModel(date: dateStr)).copyWith(
      symptomes: updatedSymptoms,
      isPendingSync: true,
    );
    await cacheDayObservations(updated);

    final mutation = QueuedObservationMutation(
      id: generateUuidV4(),
      type: ObservationSyncMutationType.deleteSymptom,
      date: dateStr,
      targetId: id,
      clientTimestamp: DateTime.now(),
    );
    await enqueueMutation(mutation);

    return updated;
  }

  /// Applique immédiatement la suppression d'un rapport intime localement (UC-24)
  Future<DayObservationsModel> applyOptimisticDeleteIntercourse(String date) async {
    final dateStr = date.length >= 10 ? date.substring(0, 10) : date;
    final existing = await getCachedDayObservations(dateStr);
    final updated = (existing ?? DayObservationsModel(date: dateStr)).copyWith(
      clearRapport: true,
      isPendingSync: true,
    );
    await cacheDayObservations(updated);

    final mutation = QueuedObservationMutation(
      id: generateUuidV4(),
      type: ObservationSyncMutationType.deleteIntercourse,
      date: dateStr,
      clientTimestamp: DateTime.now(),
    );
    await enqueueMutation(mutation);

    return updated;
  }

  // ===========================================================================
  // 4. Synchronisation Bidirectionnelle & Résorption de Conflits (LWW)
  // ===========================================================================

  /// Draine la file d'attente hors-ligne, envoie les modifications et récupère
  /// l'état serveur actualisé
  Future<ObservationSyncReport> flushQueue(IObservationRemoteDataSource remote) async {
    final queue = await getQueue();
    if (queue.isEmpty) {
      return ObservationSyncReport(
        syncedCount: 0,
        failedCount: 0,
        remainingCount: 0,
        syncedAt: DateTime.now(),
        message: 'Aucune mutation hors-ligne en attente.',
      );
    }

    final lastSyncRaw = await storage.getCache(_keyLastSync);

    // 1. Tenter la synchronisation par lot (Batch Sync)
    final saveRequests = <SaveDayObservationRequest>[];
    final deletions = <Map<String, dynamic>>[];

    for (final mut in queue) {
      if (mut.type == ObservationSyncMutationType.saveDayObservation && mut.request != null) {
        saveRequests.add(mut.request!);
      } else {
        String delType = 'temperature';
        if (mut.type == ObservationSyncMutationType.deleteCervicalMucus) {
          delType = 'cervical-mucus';
        } else if (mut.type == ObservationSyncMutationType.deleteLhTest) {
          delType = 'lh-test';
        } else if (mut.type == ObservationSyncMutationType.deleteSymptom) {
          delType = 'symptoms';
        } else if (mut.type == ObservationSyncMutationType.deleteIntercourse) {
          delType = 'intercourse';
        }
        deletions.add({
          'type': delType,
          'date': mut.date,
          if (mut.targetId != null) 'id': mut.targetId,
        });
      }
    }

    int syncedCount = 0;
    int failedCount = 0;
    final remainingMutations = <QueuedObservationMutation>[];

    try {
      final batchResult = await remote.syncBatchObservations(
        mutations: saveRequests,
        deletions: deletions,
        since: lastSyncRaw,
      );

      // Met à jour les jours confirmés par le serveur dans le cache local
      final syncedDays = (batchResult['syncedDays'] as List<dynamic>?) ?? [];
      for (final rawDay in syncedDays) {
        if (rawDay is Map<String, dynamic>) {
          final serverDay = DayObservationsModel.fromJson(rawDay).copyWith(isPendingSync: false);
          await cacheDayObservations(serverDay);
        }
      }

      // Si le lot a réussi, on vide entièrement la file
      syncedCount = queue.length;
      await _saveQueue([]);
      await storage.saveCache(_keyLastSync, DateTime.now().toIso8601String());

      return ObservationSyncReport(
        syncedCount: syncedCount,
        failedCount: 0,
        remainingCount: 0,
        syncedAt: DateTime.now(),
        message: '$syncedCount observation(s) synchronisée(s) avec succès.',
      );
    } catch (_) {
      // 2. Repli unitaire (Fallback) : traiter les mutations une par une
      for (final mut in queue) {
        try {
          switch (mut.type) {
            case ObservationSyncMutationType.saveDayObservation:
              if (mut.request != null) {
                final serverDay = await remote.saveDayObservation(mut.request!);
                await cacheDayObservations(serverDay.copyWith(isPendingSync: false));
              }
              break;
            case ObservationSyncMutationType.deleteTemperature:
              await remote.deleteTemperature(mut.date);
              final day = await getCachedDayObservations(mut.date);
              if (day != null) {
                await cacheDayObservations(day.copyWith(clearTemperature: true, isPendingSync: false));
              }
              break;
            case ObservationSyncMutationType.deleteCervicalMucus:
              await remote.deleteCervicalMucus(mut.date);
              final day = await getCachedDayObservations(mut.date);
              if (day != null) {
                await cacheDayObservations(day.copyWith(clearGlaire: true, isPendingSync: false));
              }
              break;
            case ObservationSyncMutationType.deleteLhTest:
              if (mut.targetId != null) {
                await remote.deleteLhTest(mut.targetId!);
                final day = await getCachedDayObservations(mut.date);
                if (day != null) {
                  final filtered = day.testsLh.where((t) => t.id != mut.targetId).toList();
                  await cacheDayObservations(day.copyWith(testsLh: filtered, isPendingSync: false));
                }
              }
              break;
            case ObservationSyncMutationType.deleteSymptom:
              if (mut.targetId != null) {
                await remote.deleteSymptom(mut.targetId!);
                final day = await getCachedDayObservations(mut.date);
                if (day != null) {
                  final filtered = day.symptomes.where((s) => s.id != mut.targetId).toList();
                  await cacheDayObservations(day.copyWith(symptomes: filtered, isPendingSync: false));
                }
              }
              break;
            case ObservationSyncMutationType.deleteIntercourse:
              await remote.deleteIntercourse(mut.date);
              final day = await getCachedDayObservations(mut.date);
              if (day != null) {
                await cacheDayObservations(day.copyWith(clearRapport: true, isPendingSync: false));
              }
              break;
          }
          syncedCount++;
        } catch (e) {
          failedCount++;
          remainingMutations.add(mut.copyWithIncrementedRetry());
        }
      }

      await _saveQueue(remainingMutations);
      await storage.saveCache(_keyLastSync, DateTime.now().toIso8601String());

      return ObservationSyncReport(
        syncedCount: syncedCount,
        failedCount: failedCount,
        remainingCount: remainingMutations.length,
        syncedAt: DateTime.now(),
        message: syncedCount > 0
            ? '$syncedCount observation(s) synchronisée(s), ${remainingMutations.length} en attente.'
            : 'Échec de synchronisation. Réessai ultérieur.',
      );
    }
  }
}
