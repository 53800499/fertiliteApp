import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/api_exception.dart';
import '../../data/models/observation_models.dart';
import '../../domain/repositories/observation_repository.dart';
import 'observation_event.dart';
import 'observation_state.dart';

class ObservationBloc extends Bloc<ObservationEvent, ObservationState> {
  final IObservationRepository observationRepository;
  List<TypeSymptomeModel> cachedCatalog = [];
  final Map<String, DayObservationsModel> cachedDays = {};

  BbtAnalysisModel? cachedBbtAnalysis;
  int pendingSyncCount = 0;

  ObservationBloc({required this.observationRepository})
      : super(ObservationInitialState()) {
    on<LoadSymptomCatalogEvent>(_onLoadSymptomCatalog);
    on<LoadDayObservationsEvent>(_onLoadDayObservations);
    on<SaveDayObservationEvent>(_onSaveDayObservation);
    on<DeleteTemperatureEvent>(_onDeleteTemperature);
    on<DeleteCervicalMucusEvent>(_onDeleteCervicalMucus);
    on<DeleteLhTestEvent>(_onDeleteLhTest);
    on<DeleteIntercourseEvent>(_onDeleteIntercourse);
    on<LoadBbtAnalysisEvent>(_onLoadBbtAnalysis);
    on<SyncPendingObservationsEvent>(_onSyncPendingObservations);
    on<CheckPendingSyncCountEvent>(_onCheckPendingSyncCount);
  }

  Future<void> _onLoadSymptomCatalog(
    LoadSymptomCatalogEvent event,
    Emitter<ObservationState> emit,
  ) async {
    try {
      cachedCatalog = await observationRepository.getSymptomCatalog();
      if (state is DayObservationsLoadedState) {
        emit((state as DayObservationsLoadedState).copyWith(catalog: cachedCatalog));
      }
    } catch (_) {}
  }

  Future<void> _onLoadDayObservations(
    LoadDayObservationsEvent event,
    Emitter<ObservationState> emit,
  ) async {
    final normalizedDate = event.date.length >= 10 ? event.date.substring(0, 10) : event.date;
    if (cachedDays.containsKey(normalizedDate)) {
      emit(
        DayObservationsLoadedState(
          observations: cachedDays[normalizedDate]!,
          catalog: cachedCatalog,
        ),
      );
    } else {
      emit(ObservationLoadingState());
    }
    try {
      if (cachedCatalog.isEmpty) {
        try {
          cachedCatalog = await observationRepository.getSymptomCatalog();
        } catch (_) {}
      }

      final observations = await observationRepository.getDayObservations(normalizedDate);
      cachedDays[normalizedDate] = observations;
      emit(
        DayObservationsLoadedState(
          observations: observations,
          catalog: cachedCatalog,
        ),
      );
    } on ApiException catch (e) {
      if (!cachedDays.containsKey(normalizedDate)) {
        emit(ObservationFailureState(e.message));
      }
    } catch (e) {
      if (!cachedDays.containsKey(normalizedDate)) {
        emit(ObservationFailureState('Erreur lors du chargement des observations: $e'));
      }
    }
  }

  Future<void> _onSaveDayObservation(
    SaveDayObservationEvent event,
    Emitter<ObservationState> emit,
  ) async {
    try {
      final updated = await observationRepository.saveDayObservation(event.request);
      final normalizedDate = updated.date.length >= 10 ? updated.date.substring(0, 10) : updated.date;
      cachedDays[normalizedDate] = updated;
      emit(
        DayObservationsLoadedState(
          observations: updated,
          catalog: cachedCatalog,
        ),
      );
      if (event.request.temperature != null) {
        add(const LoadBbtAnalysisEvent());
      }
    } on ApiException catch (e) {
      emit(ObservationFailureState(e.message));
    } catch (e) {
      emit(ObservationFailureState("Erreur lors de l'enregistrement: $e"));
    }
  }

  Future<void> _onDeleteTemperature(
    DeleteTemperatureEvent event,
    Emitter<ObservationState> emit,
  ) async {
    try {
      await observationRepository.deleteTemperature(event.date);
      add(LoadDayObservationsEvent(event.date));
      add(const LoadBbtAnalysisEvent());
    } catch (e) {
      emit(ObservationFailureState('Erreur lors de la suppression: $e'));
    }
  }

  Future<void> _onDeleteCervicalMucus(
    DeleteCervicalMucusEvent event,
    Emitter<ObservationState> emit,
  ) async {
    try {
      await observationRepository.deleteCervicalMucus(event.date);
      add(LoadDayObservationsEvent(event.date));
    } catch (e) {
      emit(ObservationFailureState('Erreur lors de la suppression: $e'));
    }
  }

  Future<void> _onDeleteLhTest(
    DeleteLhTestEvent event,
    Emitter<ObservationState> emit,
  ) async {
    try {
      await observationRepository.deleteLhTest(event.id);
      add(LoadDayObservationsEvent(event.date));
    } catch (e) {
      emit(ObservationFailureState('Erreur lors de la suppression: $e'));
    }
  }

  Future<void> _onDeleteIntercourse(
    DeleteIntercourseEvent event,
    Emitter<ObservationState> emit,
  ) async {
    try {
      await observationRepository.deleteIntercourse(event.date);
      add(LoadDayObservationsEvent(event.date));
    } catch (e) {
      emit(ObservationFailureState('Erreur lors de la suppression: $e'));
    }
  }

  Future<void> _onLoadBbtAnalysis(
    LoadBbtAnalysisEvent event,
    Emitter<ObservationState> emit,
  ) async {
    if (cachedBbtAnalysis != null) {
      emit(BbtAnalysisLoadedState(analysis: cachedBbtAnalysis!, isRefreshing: true));
    } else {
      emit(ObservationLoadingState());
    }
    try {
      final analysis = await observationRepository.getBbtAnalysis(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      cachedBbtAnalysis = analysis;
      emit(BbtAnalysisLoadedState(analysis: analysis));
    } catch (e) {
      if (cachedBbtAnalysis != null) {
        emit(BbtAnalysisLoadedState(analysis: cachedBbtAnalysis!));
      } else {
        emit(ObservationFailureState(ApiException.getDisplayMessage(e)));
      }
    }
  }

  Future<void> _onCheckPendingSyncCount(
    CheckPendingSyncCountEvent event,
    Emitter<ObservationState> emit,
  ) async {
    try {
      pendingSyncCount = await observationRepository.getPendingSyncCount();
    } catch (_) {}
  }

  Future<void> _onSyncPendingObservations(
    SyncPendingObservationsEvent event,
    Emitter<ObservationState> emit,
  ) async {
    final count = await observationRepository.getPendingSyncCount();
    if (count == 0) return;

    if (!event.isAutomatic) {
      emit(ObservationsSyncInProgressState(pendingCount: count));
    }

    try {
      final report = await observationRepository.syncPendingObservations();
      pendingSyncCount = report.remainingCount;

      // Invalider le cache mémoire pour recharger depuis les données fraîches
      cachedDays.clear();

      emit(ObservationsSyncSuccessState(report: report));

      // Recharger l'analyse BBT et le catalogue
      add(const LoadBbtAnalysisEvent());
      add(LoadSymptomCatalogEvent());
    } catch (e) {
      pendingSyncCount = await observationRepository.getPendingSyncCount();
      if (!event.isAutomatic) {
        emit(ObservationFailureState('Échec de synchronisation : $e'));
      }
    }
  }
}
