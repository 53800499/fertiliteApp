abstract class FertilityEvent {
  const FertilityEvent();
}

class LoadCurrentFertilityEvent extends FertilityEvent {
  const LoadCurrentFertilityEvent();
}

class RecalculateFertilityEvent extends FertilityEvent {
  final String? evaluationDate;

  const RecalculateFertilityEvent({this.evaluationDate});
}

class LoadMonthCalendarEvent extends FertilityEvent {
  final int year;
  final int month;

  const LoadMonthCalendarEvent({required this.year, required this.month});
}
