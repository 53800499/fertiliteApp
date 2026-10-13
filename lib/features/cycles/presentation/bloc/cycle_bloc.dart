import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/api_exception.dart';
import '../../data/models/cycle_models.dart';
import '../../domain/repositories/cycle_repository.dart';
import 'cycle_event.dart';
import 'cycle_state.dart';

class CycleBloc extends Bloc<CycleEvent, CycleState> {
  final ICycleRepository cycleRepository;

  CycleBloc({required this.cycleRepository}) : super(CycleInitialState()) {
    on<LoadCyclesEvent>(_onLoadCycles);
    on<StartNewCycleEvent>(_onStartNewCycle);
    on<LogDayFlowEvent>(_onLogDayFlow);
    on<SelectDateEvent>(_onSelectDate);
    on<UpdateCycleEvent>(_onUpdateCycle);
    on<DeleteCycleEvent>(_onDeleteCycle);
    on<LoadCycleStatsEvent>(_onLoadCycleStats);
  }

  Future<void> _onLoadCycles(
    LoadCyclesEvent event,
    Emitter<CycleState> emit,
  ) async {
    emit(CycleLoadingState());
    try {
      final active = await cycleRepository.getActiveCycle();
      final all = await cycleRepository.getCycles();
      CycleStatsModel? stats;
      try {
        stats = await cycleRepository.getCycleStats();
      } catch (_) {}

      emit(
        CyclesLoadedState(
          activeCycle: active,
          cycles: all,
          selectedDate: DateTime.now(),
          stats: stats,
        ),
      );
    } on ApiException catch (e) {
      emit(CycleFailureState(e.message));
    } catch (e) {
      emit(CycleFailureState('Erreur lors du chargement des cycles: $e'));
    }
  }

  Future<void> _onStartNewCycle(
    StartNewCycleEvent event,
    Emitter<CycleState> emit,
  ) async {
    final currentState = state;
    emit(CycleLoadingState());
    try {
      await cycleRepository.startCycle(event.request);
      final active = await cycleRepository.getActiveCycle();
      final all = await cycleRepository.getCycles();
      CycleStatsModel? stats;
      try {
        stats = await cycleRepository.getCycleStats();
      } catch (_) {}

      emit(
        CyclesLoadedState(
          activeCycle: active,
          cycles: all,
          selectedDate: DateTime.parse(event.request.dateDebut),
          stats: stats,
        ),
      );
    } on ApiException catch (e) {
      emit(CycleFailureState(e.message));
      if (currentState is CyclesLoadedState) emit(currentState);
    } catch (e) {
      emit(CycleFailureState('Impossible de démarrer le cycle: $e'));
      if (currentState is CyclesLoadedState) emit(currentState);
    }
  }

  Future<void> _onLogDayFlow(
    LogDayFlowEvent event,
    Emitter<CycleState> emit,
  ) async {
    try {
      await cycleRepository.logDayFlow(event.request);
      final active = await cycleRepository.getActiveCycle();
      final all = await cycleRepository.getCycles();
      CycleStatsModel? stats;
      try {
        stats = await cycleRepository.getCycleStats();
      } catch (_) {}

      DateTime targetDate = DateTime.now();
      try {
        targetDate = DateTime.parse(event.request.date);
      } catch (_) {}

      emit(
        CyclesLoadedState(
          activeCycle: active,
          cycles: all,
          selectedDate: targetDate,
          stats: stats,
        ),
      );
    } on ApiException catch (e) {
      emit(CycleFailureState(e.message));
    } catch (e) {
      emit(CycleFailureState('Impossible d\'enregistrer le flux: $e'));
    }
  }

  void _onSelectDate(
    SelectDateEvent event,
    Emitter<CycleState> emit,
  ) {
    if (state is CyclesLoadedState) {
      final current = state as CyclesLoadedState;
      emit(current.copyWith(selectedDate: event.selectedDate));
    }
  }

  Future<void> _onUpdateCycle(
    UpdateCycleEvent event,
    Emitter<CycleState> emit,
  ) async {
    try {
      await cycleRepository.updateCycle(event.cycleId, event.request);
      final active = await cycleRepository.getActiveCycle();
      final all = await cycleRepository.getCycles();
      CycleStatsModel? stats;
      try {
        stats = await cycleRepository.getCycleStats();
      } catch (_) {}

      if (state is CyclesLoadedState) {
        final current = state as CyclesLoadedState;
        emit(current.copyWith(activeCycle: active, cycles: List<CycleModel>.from(all), stats: stats));
      } else {
        emit(CyclesLoadedState(activeCycle: active, cycles: List<CycleModel>.from(all), selectedDate: DateTime.now(), stats: stats));
      }
    } on ApiException catch (e) {
      emit(CycleFailureState(e.message));
    } catch (e) {
      emit(CycleFailureState('Impossible de modifier le cycle: $e'));
    }
  }

  Future<void> _onDeleteCycle(
    DeleteCycleEvent event,
    Emitter<CycleState> emit,
  ) async {
    try {
      await cycleRepository.deleteCycle(event.cycleId);
      final active = await cycleRepository.getActiveCycle();
      final all = await cycleRepository.getCycles();
      CycleStatsModel? stats;
      try {
        stats = await cycleRepository.getCycleStats();
      } catch (_) {}

      if (state is CyclesLoadedState) {
        final current = state as CyclesLoadedState;
        emit(current.copyWith(activeCycle: active, cycles: List<CycleModel>.from(all), stats: stats));
      } else {
        emit(CyclesLoadedState(activeCycle: active, cycles: List<CycleModel>.from(all), selectedDate: DateTime.now(), stats: stats));
      }
    } on ApiException catch (e) {
      emit(CycleFailureState(e.message));
    } catch (e) {
      emit(CycleFailureState('Impossible de supprimer le cycle: $e'));
    }
  }

  Future<void> _onLoadCycleStats(
    LoadCycleStatsEvent event,
    Emitter<CycleState> emit,
  ) async {
    try {
      final stats = await cycleRepository.getCycleStats();
      if (state is CyclesLoadedState) {
        final current = state as CyclesLoadedState;
        emit(current.copyWith(stats: stats));
      }
    } catch (_) {}
  }
}

