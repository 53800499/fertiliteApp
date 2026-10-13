# 04 — Architecture Technique Mobile (Clean Architecture Flutter)
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

### Informations documentaires
- **Projet** : FertiliteApp (Client Mobile)
- **Pattern architectural** : **Clean Architecture** (Uncle Bob) + **BLoC Pattern**
- **Injection de dépendances** : `get_it` / `injectable`
- **Date** : 24 septembre 2026

---

## 1. Schéma d'Architecture en Couches (Clean Architecture)

L'application mobile est découpée en 3 couches concentriques étanches garantissant la testabilité unitaire, l'indépendance vis-à-vis des frameworks et l'isolation du mode hors ligne :

```text
 ┌────────────────────────────────────────────────────────────────────────┐
 │                           PRESENTATION LAYER                           │
 │                                                                        │
 │   ┌──────────────────────┐              ┌────────────────────────┐     │
 │   │  Screens & Pages     │              │  Custom Widgets        │     │
 │   │  (StatelessWidgets)  │◄─────────────┤  (Calendar, Gauge)     │     │
 │   └──────────┬───────────┘              └────────────────────────┘     │
 │              │ Envoi d'événements                                      │
 │              ▼                                                         │
 │   ┌──────────────────────┐              ┌────────────────────────┐     │
 │   │     BLoC / Cubit     │─────────────►│    BlocBuilder /       │     │
 │   │   (State Machine)    │ Émet États   │    BlocConsumer (UI)   │     │
 │   └──────────┬───────────┘              └────────────────────────┘     │
 └──────────────┼─────────────────────────────────────────────────────────┘
                │ Invoque UseCases
                ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │                              DOMAIN LAYER                              │
 │  (100% Dart Pur — Zéro dépendance Flutter, SQLite ou Réseau)           │
 │                                                                        │
 │   ┌──────────────────────┐              ┌────────────────────────┐     │
 │   │      Use Cases       │              │    Domain Entities     │     │
 │   │ (StartCycleUseCase)  │─────────────►│ (Cycle, Prediction)    │     │
 │   └──────────┬───────────┘              └────────────────────────┘     │
 │              │ Appelle interface Repository                            │
 │              ▼                                                         │
 │   ┌──────────────────────────────────────────────────────────────┐     │
 │   │                  Repository Interfaces (Contrats)            │     │
 │   │                  (ICycleRepository, IFertilityRepository)    │     │
 │   └──────────────────────────────────────────────────────────────┘     │
 └──────────────────────────────────────┬─────────────────────────────────┘
                                        │ Implémenté par
                                        ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │                               DATA LAYER                               │
 │                                                                        │
 │   ┌──────────────────────────────────────────────────────────────┐     │
 │   │                  Repository Implementations                  │     │
 │   │                  (CycleRepositoryImpl)                       │     │
 │   └──────────┬───────────────────────────────────────┬───────────┘     │
 │              │                                       │                 │
 │              ▼                                       ▼                 │
 │   ┌──────────────────────┐              ┌────────────────────────┐     │
 │   │ Local DataSource     │              │ Remote DataSource      │     │
 │   │ (Drift / SQLite DB)  │              │ (Dio REST Client API)  │     │
 │   │ Écriture instantanée │              │ Synchro asynchrone     │     │
 │   └──────────────────────┘              └────────────────────────┘     │
 └────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Arborescence du Code Source (`lib/`)

L'organisation des dossiers combine une approche par couche technique (`core/`) et par fonctionnalité (`features/`) :

```text
lib/
├── app/
│   ├── app.dart                          # MaterialApp, thèmes et routes globales
│   └── app_router.dart                   # Configuration GoRouter
│
├── core/                                 # Socle transversal technique
│   ├── database/                         # Base locale Drift (app_database.dart, DAOs)
│   ├── di/                               # Injection de dépendances (injection_container.dart)
│   ├── error/                            # Failures et Exceptions (failures.dart)
│   ├── network/                          # Client Dio, NetworkInfo (connectivité internet)
│   ├── security/                         # BiometricsHelper, SecureStorageHelper
│   ├── theme/                            # Couleurs douces, typographie Google Fonts, styles
│   └── utils/                            # Formateurs de dates, validateurs
│
├── features/                             # Modules fonctionnels découplés
│   ├── auth/                             # Authentification, Inscription & Profil initial
│   │   ├── data/                         # AuthRemoteDataSource, AuthRepositoryImpl
│   │   ├── domain/                       # LoginUseCase, RegisterUseCase, UserEntity
│   │   └── presentation/                 # LoginScreen, RegisterScreen, AuthBloc
│   │
│   ├── cycle/                            # Gestion des Cycles & Règles
│   │   ├── data/                         # CycleLocalDataSource, CycleRemoteDataSource, CycleRepositoryImpl
│   │   ├── domain/                       # StartCycleUseCase, LogFlowUseCase, CycleEntity
│   │   └── presentation/                 # CycleHistoryScreen, LogFlowBottomSheet, CycleBloc
│   │
│   ├── calendar/                         # Visualisation Mensuelle
│   │   ├── data/                         # CalendarDataSource, CalendarRepositoryImpl
│   │   ├── domain/                       # GetMonthDataUseCase, DayDetailEntity
│   │   └── presentation/                 # CalendarScreen, CalendarGridWidget, CalendarBloc
│   │
│   ├── fertility/                        # Estimation & Explicabilité
│   │   ├── data/                         # LocalFertilityCalculator, FertilityRepositoryImpl
│   │   ├── domain/                       # GetActivePredictionUseCase, PredictionEntity
│   │   └── presentation/                 # PredictionDetailScreen, FactorsListWidget, FertilityBloc
│   │
│   ├── observations/                     # Indicateurs V2 (T°, Glaire, LH, Symptômes)
│   │   ├── data/                         # ObservationRepositoryImpl
│   │   ├── domain/                       # LogObservationUseCase
│   │   └── presentation/                 # ObservationScreen, ObservationBloc
│   │
│   ├── notifications/                    # Gestion des Préférences d'Alertes
│   │   ├── data/                         # NotificationRepositoryImpl, LocalNotificationService
│   │   └── presentation/                 # NotificationSettingsScreen
│   │
│   └── settings/                         # Confidentialité, Sécurité & Profil
│       ├── data/                         # SettingsRepositoryImpl
│       └── presentation/                 # PrivacySettingsScreen, BiometricsSettingsScreen
│
└── main.dart                             # Initialisation Drift, GetIt et runApp
```

---

## 3. Le Flux de Données Unidirectionnel (UDF)

Lorsqu'une utilisatrice appuie sur « Enregistrer mes règles » :
1. **Événement UI** : L'écran dispatch `CycleBloc.add(StartCycleRequested(startDate))`.
2. **Exécution du Cas d'Usage** : Le `CycleBloc` invoque `StartCycleUseCase.call(params)`.
3. **Persistance Locale Immédiate** : Le `CycleRepositoryImpl` enregistre immédiatement le nouveau cycle dans la base SQLite locale via Drift (`CycleDao.insertCycle`).
4. **Mise à jour UI Instantanée** : Le `CycleBloc` émet `CycleOperationSuccess(newCycle)`. L'interface réagit en moins de 16 ms sans spinner réseau.
5. **Synchronisation Asynchrone en Arrière-Plan** : Le `SyncEngine` détecte un enregistrement non synchronisé (`statut_synchronisation = en_attente`) et déclenche la requête HTTP `POST /api/v1/cycles/start` via Dio lorsque le réseau est disponible.
