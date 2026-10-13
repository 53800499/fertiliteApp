import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/cycles/data/models/cycle_models.dart';
import 'package:frontend/features/cycles/domain/repositories/cycle_repository.dart';
import 'package:frontend/features/cycles/presentation/bloc/cycle_bloc.dart';
import 'package:frontend/features/cycles/presentation/bloc/cycle_event.dart';
import 'package:frontend/features/cycles/presentation/bloc/cycle_state.dart';

class FakeCycleRepository implements ICycleRepository {
  List<CycleModel> storedCycles = [
    const CycleModel(
      id: 'c-1',
      dateDebut: '2026-09-01',
      statut: 'en_cours',
      joursRegles: [
        JourReglesModel(
          id: 'j-1',
          cycleId: 'c-1',
          date: '2026-09-01',
          intensiteFlux: 'moyen',
        ),
      ],
    ),
  ];

  @override
  Future<List<CycleModel>> getCycles() async => List<CycleModel>.from(storedCycles);

  @override
  Future<CycleModel?> getActiveCycle() async =>
      storedCycles.isNotEmpty && storedCycles.first.isEnCours ? storedCycles.first : null;

  @override
  Future<CycleModel> getCycleById(String id) async =>
      storedCycles.firstWhere((c) => c.id == id);

  @override
  Future<CycleModel> startCycle(StartCycleRequestModel request) async {
    final newCycle = CycleModel(
      id: 'c-new',
      dateDebut: request.dateDebut,
      statut: 'en_cours',
    );
    storedCycles.insert(0, newCycle);
    return newCycle;
  }

  @override
  Future<JourReglesModel> logDayFlow(LogFlowRequestModel request) async {
    return JourReglesModel(
      id: 'j-new',
      cycleId: 'c-1',
      date: request.date,
      intensiteFlux: request.intensiteFlux,
    );
  }

  @override
  Future<CycleModel> updateCycle(String id, UpdateCycleRequestModel request) async {
    final idx = storedCycles.indexWhere((c) => c.id == id);
    final updated = CycleModel(
      id: id,
      dateDebut: request.dateDebut ?? storedCycles[idx].dateDebut,
      dateFin: request.dateFin ?? storedCycles[idx].dateFin,
      statut: request.statut ?? storedCycles[idx].statut,
    );
    storedCycles[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteCycle(String id) async {
    storedCycles.removeWhere((c) => c.id == id);
  }

  @override
  Future<CycleStatsModel> getCycleStats() async {
    return const CycleStatsModel(
      totalCycles: 1,
      completedCycles: 0,
      averageDuration: 28.0,
      minDuration: 28,
      maxDuration: 28,
      standardDeviation: 0.0,
      regularity: 'indetermine',
      averagePeriodDuration: 5.0,
      history: [],
    );
  }
}

void main() {
  group('CycleBloc Tests (Module 2)', () {
    late FakeCycleRepository fakeRepo;
    late CycleBloc bloc;

    setUp(() {
      fakeRepo = FakeCycleRepository();
      bloc = CycleBloc(cycleRepository: fakeRepo);
    });

    tearDown(() {
      bloc.close();
    });

    test('Initial state is CycleInitialState', () {
      expect(bloc.state, isA<CycleInitialState>());
    });

    test('LoadCyclesEvent emits CycleLoadingState then CyclesLoadedState', () async {
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CycleLoadingState>(),
          isA<CyclesLoadedState>().having(
            (s) => s.cycles.length,
            'cycles count',
            1,
          ),
        ]),
      );

      bloc.add(LoadCyclesEvent());
    });

    test('StartNewCycleEvent adds new cycle and emits loaded state', () async {
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CycleLoadingState>(),
          isA<CyclesLoadedState>().having(
            (s) => s.cycles.length,
            'cycles count',
            2,
          ),
        ]),
      );

      bloc.add(const StartNewCycleEvent(StartCycleRequestModel(dateDebut: '2026-09-24')));
    });

    test('DeleteCycleEvent removes cycle and updates state', () async {
      final loadedFuture = expectLater(
        bloc.stream,
        emitsThrough(isA<CyclesLoadedState>()),
      );
      bloc.add(LoadCyclesEvent());
      await loadedFuture;

      final deleteFuture = expectLater(
        bloc.stream,
        emitsThrough(
          isA<CyclesLoadedState>().having(
            (s) => s.cycles.isEmpty,
            'cycles empty',
            isTrue,
          ),
        ),
      );
      bloc.add(const DeleteCycleEvent('c-1'));
      await deleteFuture;
    });
  });
}
