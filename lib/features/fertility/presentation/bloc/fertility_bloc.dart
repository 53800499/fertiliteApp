import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/fertility_repository.dart';
import 'fertility_event.dart';
import 'fertility_state.dart';

export 'fertility_event.dart';
export 'fertility_state.dart';

class FertilityBloc extends Bloc<FertilityEvent, FertilityState> {
  final IFertilityRepository fertilityRepository;

  FertilityBloc({required this.fertilityRepository}) : super(const FertilityInitialState()) {
    on<LoadCurrentFertilityEvent>(_onLoadCurrentFertility);
    on<RecalculateFertilityEvent>(_onRecalculateFertility);
    on<LoadMonthCalendarEvent>(_onLoadMonthCalendar);
  }

  Future<void> _onLoadCurrentFertility(
    LoadCurrentFertilityEvent event,
    Emitter<FertilityState> emit,
  ) async {
    emit(const FertilityLoadingState());
    try {
      final prediction = await fertilityRepository.getCurrentPrediction();
      emit(FertilityLoadedState(currentPrediction: prediction));
    } catch (e) {
      emit(FertilityFailureState(message: e.toString()));
    }
  }

  Future<void> _onRecalculateFertility(
    RecalculateFertilityEvent event,
    Emitter<FertilityState> emit,
  ) async {
    final previousState = state;
    emit(const FertilityLoadingState());
    try {
      final prediction = await fertilityRepository.recalculateFertility(
        evaluationDate: event.evaluationDate,
      );
      if (previousState is FertilityLoadedState) {
        emit(previousState.copyWith(currentPrediction: prediction));
      } else {
        emit(FertilityLoadedState(currentPrediction: prediction));
      }
    } catch (e) {
      emit(FertilityFailureState(message: e.toString()));
    }
  }

  Future<void> _onLoadMonthCalendar(
    LoadMonthCalendarEvent event,
    Emitter<FertilityState> emit,
  ) async {
    try {
      final calendar = await fertilityRepository.getMonthCalendar(
        year: event.year,
        month: event.month,
      );
      if (state is FertilityLoadedState) {
        emit((state as FertilityLoadedState).copyWith(monthCalendar: calendar));
      } else {
        final prediction = await fertilityRepository.getCurrentPrediction();
        emit(FertilityLoadedState(
          currentPrediction: prediction,
          monthCalendar: calendar,
        ));
      }
    } catch (e) {
      if (state is! FertilityLoadedState) {
        emit(FertilityFailureState(message: e.toString()));
      }
    }
  }
}
