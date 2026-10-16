import 'package:equatable/equatable.dart';
import '../../data/models/observation_models.dart';

abstract class ObservationState extends Equatable {
  const ObservationState();

  @override
  List<Object?> get props => [];
}

class ObservationInitialState extends ObservationState {}

class ObservationLoadingState extends ObservationState {}

class DayObservationsLoadedState extends ObservationState {
  final DayObservationsModel observations;
  final List<TypeSymptomeModel> catalog;

  const DayObservationsLoadedState({
    required this.observations,
    this.catalog = const [],
  });

  DayObservationsLoadedState copyWith({
    DayObservationsModel? observations,
    List<TypeSymptomeModel>? catalog,
  }) {
    return DayObservationsLoadedState(
      observations: observations ?? this.observations,
      catalog: catalog ?? this.catalog,
    );
  }

  @override
  List<Object?> get props => [observations, catalog];
}

class ObservationSuccessState extends ObservationState {
  final String message;
  final DayObservationsModel? updatedObservations;

  const ObservationSuccessState({
    required this.message,
    this.updatedObservations,
  });

  @override
  List<Object?> get props => [message, updatedObservations];
}

class ObservationFailureState extends ObservationState {
  final String message;

  const ObservationFailureState(this.message);

  @override
  List<Object?> get props => [message];
}

/// État chargé pour la courbe de température basale (BBT)
class BbtAnalysisLoadedState extends ObservationState {
  final BbtAnalysisModel analysis;
  final bool isRefreshing;

  const BbtAnalysisLoadedState({
    required this.analysis,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [analysis, isRefreshing];
}

/// État de synchronisation hors-ligne en cours (Option C)
class ObservationsSyncInProgressState extends ObservationState {
  final int pendingCount;

  const ObservationsSyncInProgressState({required this.pendingCount});

  @override
  List<Object?> get props => [pendingCount];
}

/// État de succès de synchronisation (Option C)
class ObservationsSyncSuccessState extends ObservationState {
  final ObservationSyncReport report;

  const ObservationsSyncSuccessState({required this.report});

  @override
  List<Object?> get props => [report];
}

