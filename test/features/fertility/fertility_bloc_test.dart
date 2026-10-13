import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/fertility/data/models/fertility_models.dart';
import 'package:frontend/features/fertility/domain/repositories/fertility_repository.dart';
import 'package:frontend/features/fertility/presentation/bloc/fertility_bloc.dart';

class FakeFertilityRepository implements IFertilityRepository {
  final PredictionModel mockPrediction = const PredictionModel(
    predictionId: 'mock-pred-1',
    generationDate: '2026-10-13T10:00:00Z',
    estimatedOvulationDate: '2026-10-15',
    uncertaintyMarginDays: 1,
    fertileWindow: FertileWindowModel(
      startDate: '2026-10-09',
      endDate: '2026-10-17',
    ),
    fertilityCategory: 'elevee',
    fertilityScoreValue: 80.0,
    confidenceLevel: 'eleve',
    method: 'calendrier_statistique',
    algorithm: 'calendar_v1',
    modelVersion: 'v1.0-calendrier',
    factors: [
      FactorExplanationModel(
        type: 'historique_cycles',
        description: 'Cycles réguliers',
        weight: 0.45,
        direction: 'renforce',
        displayOrder: 1,
      ),
    ],
  );

  @override
  Future<PredictionModel> getCurrentPrediction() async => mockPrediction;

  @override
  Future<PredictionModel> recalculateFertility({String? evaluationDate}) async =>
      mockPrediction;

  @override
  Future<List<FactorExplanationModel>> getCurrentFactors() async =>
      mockPrediction.factors;

  @override
  Future<CalendarMonthModel> getMonthCalendar({int? year, int? month}) async {
    return CalendarMonthModel(
      year: year ?? 2026,
      month: month ?? 10,
      estimatedOvulationDate: '2026-10-15',
      days: const [],
    );
  }

  @override
  Future<List<PredictionModel>> getPredictionHistory({int limit = 10}) async =>
      [mockPrediction];
}

void main() {
  group('FertilityBloc Tests (Module 4 - M4)', () {
    late FakeFertilityRepository repo;
    late FertilityBloc bloc;

  setUp(() {
    repo = FakeFertilityRepository();
    bloc = FertilityBloc(fertilityRepository: repo);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is FertilityInitialState', () {
    expect(bloc.state, isA<FertilityInitialState>());
  });

  test('LoadCurrentFertilityEvent emits [Loading, Loaded]', () async {
    final expectedStates = [
      isA<FertilityLoadingState>(),
      isA<FertilityLoadedState>().having(
        (s) => s.currentPrediction.fertilityScoreValue,
        'fertilityScoreValue',
        80.0,
      ),
    ];

    expectLater(bloc.stream, emitsInOrder(expectedStates));
    bloc.add(const LoadCurrentFertilityEvent());
  });

  test('RecalculateFertilityEvent recalculates and updates state', () async {
    final expectedStates = [
      isA<FertilityLoadingState>(),
      isA<FertilityLoadedState>().having(
        (s) => s.currentPrediction.estimatedOvulationDate,
        'estimatedOvulationDate',
        '2026-10-15',
      ),
    ];

    expectLater(bloc.stream, emitsInOrder(expectedStates));
    bloc.add(const RecalculateFertilityEvent());
  });
  });
}
