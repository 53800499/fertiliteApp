# Architecture Technique Détaillée — Frontend Flutter
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

## 1. Modularité par Feature (Feature-First Architecture)

L'architecture évite les répertoires "fourre-tout" en regroupant Presentation, Domain et Data par fonctionnalité métier (`features/cycle/`, `features/fertility/`, `features/calendar/`).

```text
features/cycle/
├── data/
│   ├── datasources/cycle_local_data_source.dart
│   ├── datasources/cycle_remote_data_source.dart
│   ├── models/cycle_model.dart
│   └── repositories/cycle_repository_impl.dart
├── domain/
│   ├── entities/cycle_entity.dart
│   ├── repositories/cycle_repository.dart
│   └── usecases/start_cycle_use_case.dart
└── presentation/
    ├── bloc/cycle_bloc.dart
    ├── pages/cycle_history_page.dart
    └── widgets/flow_intensity_selector.dart
```

---

## 2. Injection de Dépendances & Cycle de Vie

- Utilisation de `get_it` comme Service Locator universel ;
- Enregistrement des DataSources et Repositories en **LazySingleton** ;
- Enregistrement des BLoCs en **Factory** pour garantir leur réinitialisation propre à la destruction des pages associées.
