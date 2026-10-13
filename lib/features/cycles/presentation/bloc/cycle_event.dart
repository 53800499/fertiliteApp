import 'package:equatable/equatable.dart';
import '../../data/models/cycle_models.dart';

abstract class CycleEvent extends Equatable {
  const CycleEvent();

  @override
  List<Object?> get props => [];
}

class LoadCyclesEvent extends CycleEvent {}

class StartNewCycleEvent extends CycleEvent {
  final StartCycleRequestModel request;

  const StartNewCycleEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class LogDayFlowEvent extends CycleEvent {
  final LogFlowRequestModel request;

  const LogDayFlowEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class SelectDateEvent extends CycleEvent {
  final DateTime selectedDate;

  const SelectDateEvent(this.selectedDate);

  @override
  List<Object?> get props => [selectedDate];
}

class UpdateCycleEvent extends CycleEvent {
  final String cycleId;
  final UpdateCycleRequestModel request;

  const UpdateCycleEvent({required this.cycleId, required this.request});

  @override
  List<Object?> get props => [cycleId, request];
}

class DeleteCycleEvent extends CycleEvent {
  final String cycleId;

  const DeleteCycleEvent(this.cycleId);

  @override
  List<Object?> get props => [cycleId];
}

class LoadCycleStatsEvent extends CycleEvent {}

