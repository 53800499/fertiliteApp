import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/observations/data/models/observation_models.dart';
import 'package:frontend/features/observations/presentation/bloc/observation_bloc.dart';
import 'package:frontend/features/observations/presentation/widgets/day_observations_card.dart';
import 'package:frontend/features/observations/presentation/widgets/observation_entry_bottom_sheet.dart';
import 'observation_bloc_test.dart';

void main() {
  testWidgets('DayObservationsCard displays biomarqueurs when data exists',
      (WidgetTester tester) async {
    final fakeRepo = FakeObservationRepository();
    final bloc = ObservationBloc(observationRepository: fakeRepo);

    const obs = DayObservationsModel(
      date: '2026-10-01',
      temperature: TemperatureBasaleModel(
        date: '2026-10-01',
        temperatureCelsius: 36.65,
      ),
      glaire: GlaireCervicaleModel(
        date: '2026-10-01',
        typeGlaire: GlaireType.filantBlancOeuf,
      ),
      testsLh: [
        TestOvulationModel(
          date: '2026-10-01',
          resultat: LhResult.pic,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<ObservationBloc>.value(
            value: bloc,
            child: DayObservationsCard(
              date: DateTime(2026, 10, 1),
              observations: obs,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Biomarqueurs & Symptômes'), findsOneWidget);
    expect(find.text('36.65 °C'), findsOneWidget);
    expect(find.text("Filante (Blanc d'œuf)"), findsOneWidget);
    expect(find.text('Fertile'), findsOneWidget);
    expect(find.text('LH: Pic de LH'), findsOneWidget);
    expect(find.text('Modifier'), findsOneWidget);

    bloc.close();
  });

  testWidgets('ObservationEntryBottomSheet renders tabs and sliders correctly',
      (WidgetTester tester) async {
    final fakeRepo = FakeObservationRepository();
    final bloc = ObservationBloc(observationRepository: fakeRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<ObservationBloc>.value(
            value: bloc,
            child: ObservationEntryBottomSheet(
              date: DateTime(2026, 10, 1),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Observations & Biomarqueurs'), findsOneWidget);
    expect(find.text('Température'), findsOneWidget);
    expect(find.text('Glaire'), findsOneWidget);
    expect(find.text('Test LH'), findsOneWidget);
    expect(find.text('Symptômes'), findsOneWidget);
    expect(find.text('Enregistrer les observations'), findsOneWidget);

    bloc.close();
  });
}
