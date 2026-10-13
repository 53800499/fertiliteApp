import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/cycles/data/models/cycle_models.dart';
import 'package:frontend/features/cycles/domain/repositories/cycle_repository.dart';
import 'package:frontend/features/cycles/presentation/bloc/cycle_bloc.dart';
import 'package:frontend/features/cycles/presentation/screens/calendar_screen.dart';
import 'package:frontend/features/cycles/presentation/screens/cycle_stats_screen.dart';
import 'package:frontend/features/observations/presentation/bloc/observation_bloc.dart';
import '../observations/observation_bloc_test.dart';

class MockCycleRepository implements ICycleRepository {
  @override
  Future<List<CycleModel>> getCycles() async => [
        const CycleModel(
          id: 'cycle-1',
          dateDebut: '2026-09-01',
          dureeReglesJours: 5,
          statut: 'en_cours',
          joursRegles: [
            JourReglesModel(
              id: 'j-1',
              cycleId: 'cycle-1',
              date: '2026-09-01',
              intensiteFlux: 'moyen',
            ),
          ],
        ),
      ];

  @override
  Future<CycleModel?> getActiveCycle() async => const CycleModel(
        id: 'cycle-1',
        dateDebut: '2026-09-01',
        dureeReglesJours: 5,
        statut: 'en_cours',
      );

  @override
  Future<CycleModel> getCycleById(String id) async => const CycleModel(
        id: 'cycle-1',
        dateDebut: '2026-09-01',
        statut: 'en_cours',
      );

  @override
  Future<CycleModel> startCycle(StartCycleRequestModel request) async => const CycleModel(
        id: 'cycle-new',
        dateDebut: '2026-09-24',
        statut: 'en_cours',
      );

  @override
  Future<JourReglesModel> logDayFlow(LogFlowRequestModel request) async => JourReglesModel(
        id: 'j-1',
        cycleId: 'cycle-1',
        date: request.date,
        intensiteFlux: request.intensiteFlux,
      );

  @override
  Future<CycleModel> updateCycle(String id, UpdateCycleRequestModel request) async =>
      const CycleModel(id: 'c1', dateDebut: '2026-09-01', statut: 'termine');

  @override
  Future<void> deleteCycle(String id) async {}

  @override
  Future<CycleStatsModel> getCycleStats() async => const CycleStatsModel(
        totalCycles: 4,
        completedCycles: 3,
        averageDuration: 28.5,
        minDuration: 27,
        maxDuration: 30,
        standardDeviation: 1.2,
        regularity: 'tres_regulier',
        averagePeriodDuration: 5.0,
        history: [],
      );
}

void main() {
  testWidgets('CalendarScreen displays Hero Card, Calendar grid and Saisie button', (WidgetTester tester) async {
    final mockRepo = MockCycleRepository();
    final bloc = CycleBloc(cycleRepository: mockRepo);
    final obsBloc = ObservationBloc(observationRepository: FakeObservationRepository());

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CycleBloc>.value(value: bloc),
            BlocProvider<ObservationBloc>.value(value: obsBloc),
          ],
          child: const CalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Calendrier & Fertilité'), findsOneWidget);
    expect(find.text('JOUR'), findsOneWidget);
    expect(find.text('Saisie du jour'), findsOneWidget);

    bloc.close();
    obsBloc.close();
  });

  testWidgets('CycleStatsScreen displays regularity hero card and metrics', (WidgetTester tester) async {
    final mockRepo = MockCycleRepository();
    final bloc = CycleBloc(cycleRepository: mockRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<CycleBloc>.value(
          value: bloc,
          child: const CycleStatsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Statistiques & Régularité'), findsOneWidget);
    expect(find.text('Durée moyenne'), findsOneWidget);
    expect(find.text('Durée des règles'), findsOneWidget);

    bloc.close();
  });
}
