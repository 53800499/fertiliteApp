import '../../data/models/fertility_models.dart';

abstract class FertilityState {
  const FertilityState();
}

class FertilityInitialState extends FertilityState {
  const FertilityInitialState();
}

class FertilityLoadingState extends FertilityState {
  const FertilityLoadingState();
}

class FertilityLoadedState extends FertilityState {
  final PredictionModel currentPrediction;
  final CalendarMonthModel? monthCalendar;

  const FertilityLoadedState({
    required this.currentPrediction,
    this.monthCalendar,
  });

  FertilityLoadedState copyWith({
    PredictionModel? currentPrediction,
    CalendarMonthModel? monthCalendar,
  }) {
    return FertilityLoadedState(
      currentPrediction: currentPrediction ?? this.currentPrediction,
      monthCalendar: monthCalendar ?? this.monthCalendar,
    );
  }
}

class FertilityFailureState extends FertilityState {
  final String message;

  const FertilityFailureState({required this.message});
}
