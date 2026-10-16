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

  ObservationBloc({required this.observationRepository})
      : super(ObservationInitialState()) {
    on<LoadSymptomCatalogEvent>(_onLoadSymptomCatalog);
    on<LoadDayObservationsEvent>(_onLoadDayObservations);
    on<SaveDayObservationEvent>(_onSaveDayObservation);
    on<DeleteTemperatureEvent>(_onDeleteTemperature);
    on<DeleteCervicalMucusEvent>(_onDeleteCervicalMucus);
    on<DeleteLhTestEvent>(_onDeleteLhTest);
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
}
