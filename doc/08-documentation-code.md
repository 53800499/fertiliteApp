# 08 — Documentation du Code & Conventions Flutter
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

### Informations documentaires
- **Projet** : FertiliteApp (Client Mobile Flutter)
- **Langage** : Dart 3.x (avec null safety stricte et sealed classes)
- **Gestion d'état** : `flutter_bloc`
- **Date** : 24 septembre 2026

---

## 1. Conventions de Nommage & Bonnes Pratiques

1. **Fichiers & Dossiers** : `snake_case.dart` (ex. `cycle_history_screen.dart`, `start_cycle_use_case.dart`).
2. **Classes & Enums** : `PascalCase` (ex. `CycleEntity`, `FertilityScoreCategory`).
3. **Variables & Fonctions** : `camelCase` (ex. `calculateLutealPhase()`, `fertileWindowStartDate`).
4. **Constantes** : `lowerCamelCase` (recommandation officielle Dart) ou `SCREAMING_SNAKE_CASE` uniquement pour les constantes statiques globales.

---

## 2. Structure Standard d'un BLoC (Exemple `CycleBloc`)

Utilisation des classes scellées (*sealed classes*) de Dart 3 pour garantir l'exhaustivité des cas traités dans les `switch` d'état :

```dart
// lib/features/cycle/presentation/bloc/cycle_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/cycle_entity.dart';
import '../../domain/usecases/start_cycle_use_case.dart';

// --- ÉVÉNEMENTS ---
sealed class CycleEvent extends Equatable {
  const CycleEvent();
  @override
  List<Object?> get props => [];
}

final class StartCycleRequested extends CycleEvent {
  final DateTime startDate;
  final String flowIntensity;
  const StartCycleRequested({required this.startDate, required this.flowIntensity});

  @override
  List<Object?> get props => [startDate, flowIntensity];
}

// --- ÉTATS ---
sealed class CycleState extends Equatable {
  const CycleState();
  @override
  List<Object?> get props => [];
}

final class CycleInitial extends CycleState {}
final class CycleLoading extends CycleState {}
final class CycleSuccess extends CycleState {
  final CycleEntity currentCycle;
  const CycleSuccess(this.currentCycle);

  @override
  List<Object?> get props => [currentCycle];
}
final class CycleFailure extends CycleState {
  final String errorMessage;
  const CycleFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

// --- BLOC ---
class CycleBloc extends Bloc<CycleEvent, CycleState> {
  final StartCycleUseCase startCycleUseCase;

  CycleBloc({required this.startCycleUseCase}) : super(CycleInitial()) {
    on<StartCycleRequested>((event, emit) async {
      emit(CycleLoading());
      final result = await startCycleUseCase(
        StartCycleParams(startDate: event.startDate, flowIntensity: event.flowIntensity),
      );

      result.fold(
        (failure) => emit(CycleFailure(failure.message)),
        (cycle) => emit(CycleSuccess(cycle)),
      );
    });
  }
}
```

---

## 3. Pattern UseCase avec Programmation Fonctionnelle

Chaque cas d'usage implémente une méthode `call()` et retourne un `Either<Failure, T>` :

```dart
// lib/features/cycle/domain/usecases/start_cycle_use_case.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/cycle_entity.dart';
import '../repositories/cycle_repository.dart';

class StartCycleUseCase {
  final CycleRepository repository;

  StartCycleUseCase(this.repository);

  Future<Either<Failure, CycleEntity>> call(StartCycleParams params) async {
    // Vérification de cohérence physiologique
    if (params.startDate.isAfter(DateTime.now())) {
      return const Left(ValidationFailure('La date de début ne peut pas être dans le futur.'));
    }

    return await repository.startNewCycle(params.startDate, params.flowIntensity);
  }
}
```
