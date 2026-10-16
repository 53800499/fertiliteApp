import 'package:equatable/equatable.dart';
import '../../data/models/cycle_models.dart';

abstract class CycleState extends Equatable {
  const CycleState();

  @override
  List<Object?> get props => [];
}

class CycleInitialState extends CycleState {}

class CycleLoadingState extends CycleState {}

class CyclesLoadedState extends CycleState {
  final CycleModel? activeCycle;
  final List<CycleModel> cycles;
  final DateTime selectedDate;
  final CycleStatsModel? stats;

  const CyclesLoadedState({
    required this.activeCycle,
    required this.cycles,
    required this.selectedDate,
    this.stats,
  });

  @override
  List<Object?> get props => [activeCycle, cycles, selectedDate, stats];

  CyclesLoadedState copyWith({
    CycleModel? activeCycle,
    List<CycleModel>? cycles,
    DateTime? selectedDate,
    CycleStatsModel? stats,
  }) {
    return CyclesLoadedState(
      activeCycle: activeCycle ?? this.activeCycle,
      cycles: cycles ?? this.cycles,
      selectedDate: selectedDate ?? this.selectedDate,
      stats: stats ?? this.stats,
    );
  }

  /// Trouve un jour de règles pour une date donnée
  JourReglesModel? getJourReglesForDate(DateTime date) {
    final dateStr =
        "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    if (activeCycle != null) {
      for (final jour in activeCycle!.joursRegles) {
        final jDate = jour.date.length >= 10 ? jour.date.substring(0, 10) : jour.date;
        if (jDate == dateStr) {
          return jour;
        }
      }
    }

    for (final cycle in cycles) {
      for (final jour in cycle.joursRegles) {
        final jDate = jour.date.length >= 10 ? jour.date.substring(0, 10) : jour.date;
        if (jDate == dateStr) {
          return jour;
        }
      }
    }
    return null;
  }
}

class CycleFailureState extends CycleState {
  final String message;

  const CycleFailureState(this.message);

  @override
  List<Object?> get props => [message];
}
