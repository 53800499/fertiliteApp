# 09 — Stratégie de Tests Mobile (Flutter)
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

### Informations documentaires
- **Projet** : FertiliteApp (Client Mobile Flutter)
- **Outils de test** : `flutter_test`, `bloc_test`, `mocktail`, `integration_test`
- **Date** : 24 septembre 2026

---

## 1. Organisation des Tests Mobiles

```text
test/
├── unit/
│   ├── features/cycle/start_cycle_use_case_test.dart
│   ├── features/fertility/local_fertility_calculator_test.dart
│   └── core/network/auth_interceptor_test.dart
│
├── bloc/
│   ├── features/cycle/cycle_bloc_test.dart
│   └── features/fertility/fertility_bloc_test.dart
│
├── widget/
│   ├── features/calendar/calendar_grid_widget_test.dart
│   └── features/cycle/log_flow_bottom_sheet_test.dart
│
└── integration_test/
    └── offline_first_flow_test.dart
```

---

## 2. Exemple de Test Unitaire de BLoC (`bloc_test`)

```dart
// test/bloc/features/cycle/cycle_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fertiliteapp/features/cycle/presentation/bloc/cycle_bloc.dart';
import 'package:fertiliteapp/features/cycle/domain/usecases/start_cycle_use_case.dart';
import 'package:fertiliteapp/features/cycle/domain/entities/cycle_entity.dart';

class MockStartCycleUseCase extends Mock implements StartCycleUseCase {}

void main() {
  late MockStartCycleUseCase mockUseCase;
  late CycleBloc cycleBloc;

  setUp(() {
    mockUseCase = MockStartCycleUseCase();
    cycleBloc = CycleBloc(startCycleUseCase: mockUseCase);
  });

  tearDown(() {
    cycleBloc.close();
  });

  final testDate = DateTime(2026, 9, 24);
  final expectedCycle = CycleEntity(
    id: 'server-id',
    localClientId: 'local-uuid',
    startDate: testDate,
    status: 'en_cours',
  );

  blocTest<CycleBloc, CycleState>(
    'émet [CycleLoading, CycleSuccess] lorsque l enregistrement des règles réussit',
    build: () {
      when(() => mockUseCase(any())).thenAnswer(
        (_) async => Right(expectedCycle),
      );
      return cycleBloc;
    },
    act: (bloc) => bloc.add(StartCycleRequested(startDate: testDate, flowIntensity: 'moyen')),
    expect: () => [
      CycleLoading(),
      CycleSuccess(expectedCycle),
    ],
    verify: (_) {
      verify(() => mockUseCase(any())).called(1);
    },
  );
}
```

---

## 3. Test d'Intégration du Scénario Hors Ligne (Offline-First)

Le test `offline_first_flow_test.dart` simule :
1. Déconnexion réseau artificielle (`NetworkInfo.setMockConnected(false)`) ;
2. Déclaration d'un cycle par l'utilisatrice dans l'interface Flutter ;
3. Vérification immédiate que le calendrier se met à jour localement avec une estimation préliminaire ;
4. Rétablissement de la connexion réseau ;
5. Vérification que le `SyncEngine` synchronise la donnée avec le backend et met à jour le statut en `'synchronise'`.
