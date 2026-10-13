import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/fertility/presentation/bloc/fertility_bloc.dart';
import 'package:frontend/features/fertility/presentation/widgets/fertility_explanation_bottom_sheet.dart';
import 'fertility_bloc_test.dart';

void main() {
  testWidgets('FertilityExplanationBottomSheet displays score, confidence and explanations',
      (WidgetTester tester) async {
    final fakeRepo = FakeFertilityRepository();
    final bloc = FertilityBloc(fertilityRepository: fakeRepo);

    bloc.add(const LoadCurrentFertilityEvent());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<FertilityBloc>.value(
            value: bloc,
            child: const FertilityExplanationBottomSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Comprendre mon estimation'), findsOneWidget);
    expect(find.textContaining('Score continu'), findsOneWidget);
    expect(find.text('Probabilité élevée'), findsOneWidget);
    expect(find.text('Confiance élevée'), findsOneWidget);
    expect(find.text('Facteurs pris en compte (Explicabilité)'), findsOneWidget);
    expect(find.text('Cycles réguliers'), findsOneWidget);
    expect(find.text('Actualiser mon estimation'), findsOneWidget);
    expect(find.textContaining('Avertissement médical'), findsOneWidget);

    bloc.close();
  });
}
