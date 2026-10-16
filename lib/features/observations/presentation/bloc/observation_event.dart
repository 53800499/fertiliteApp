import 'package:equatable/equatable.dart';
import '../../data/models/observation_models.dart';

abstract class ObservationEvent extends Equatable {
  const ObservationEvent();

  @override
  List<Object?> get props => [];
}

/// Charger le catalogue des symptômes
class LoadSymptomCatalogEvent extends ObservationEvent {}

/// Charger les observations d'un jour spécifique
class LoadDayObservationsEvent extends ObservationEvent {
  final String date;

  const LoadDayObservationsEvent(this.date);

  @override
  List<Object?> get props => [date];
}

/// Enregistrer / mettre à jour l'ensemble des observations du jour
class SaveDayObservationEvent extends ObservationEvent {
  final SaveDayObservationRequest request;

  const SaveDayObservationEvent(this.request);

  @override
  List<Object?> get props => [request];
}

/// Supprimer la température du jour
class DeleteTemperatureEvent extends ObservationEvent {
  final String date;

  const DeleteTemperatureEvent(this.date);

  @override
  List<Object?> get props => [date];
}

/// Supprimer la glaire du jour
class DeleteCervicalMucusEvent extends ObservationEvent {
  final String date;

  const DeleteCervicalMucusEvent(this.date);

  @override
  List<Object?> get props => [date];
}

/// Supprimer un test LH
class DeleteLhTestEvent extends ObservationEvent {
  final String id;
  final String date;

  const DeleteLhTestEvent({required this.id, required this.date});

  @override
  List<Object?> get props => [id, date];
}

/// Supprimer un rapport intime (UC-24)
class DeleteIntercourseEvent extends ObservationEvent {
  final String date;

  const DeleteIntercourseEvent(this.date);

  @override
  List<Object?> get props => [date];
}

/// Charger l'analyse thermique continue et le décalage biphasique (UC-16 DataViz BBT)
class LoadBbtAnalysisEvent extends ObservationEvent {
  final String? startDate;
  final String? endDate;

  const LoadBbtAnalysisEvent({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Déclencher la synchronisation de la file d'attente hors-ligne (Option C)
class SyncPendingObservationsEvent extends ObservationEvent {
  final bool isAutomatic;

  const SyncPendingObservationsEvent({this.isAutomatic = false});

  @override
  List<Object?> get props => [isAutomatic];
}

/// Rafraîchir le compteur des mutations en attente
class CheckPendingSyncCountEvent extends ObservationEvent {}

