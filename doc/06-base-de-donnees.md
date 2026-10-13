# 06 — Base de Données Locale Mobile (Drift / SQLite)
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

### Informations documentaires
- **Projet** : FertiliteApp (Client Mobile Flutter)
- **Technologie de persistance locale** : **Drift** (anciennement Moor) / SQLite
- **Sécurité au repos** : Chiffrement intégral de la base avec **SQLCipher** (AES-256)
- **Date** : 24 septembre 2026

---

## 1. Schéma des Tables Locales Drift (`lib/core/database/`)

### 1.1 Table `LocalCycles`
```dart
import 'package:drift/drift.dart';

@DataClassName('LocalCycle')
class LocalCycles extends Table {
  TextColumn get id => text()(); // UUID serveur (nullable avant synchro)
  TextColumn get localClientId => text()(); // UUID local (clé primaire locale)
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get cycleLengthDays => integer().nullable()();
  IntColumn get periodDurationDays => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('en_cours'))();
  TextColumn get syncStatus => text().withDefault(const Constant('en_attente'))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {localClientId};
}
```

### 1.2 Table `LocalCycleDays` (Jour de règles)
```dart
@DataClassName('LocalCycleDay')
class LocalCycleDays extends Table {
  TextColumn get id => text().nullable()();
  TextColumn get localClientId => text()();
  TextColumn get cycleLocalId => text()(); // Référence vers LocalCycles.localClientId
  DateTimeColumn get date => dateTime()();
  TextColumn get flowIntensity => text()(); // absent, spotting, leger, moyen, abondant
  IntColumn get painLevel => integer().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('en_attente'))();

  @override
  Set<Column> get primaryKey => {localClientId};
}
```

### 1.3 Table `LocalPredictions`
```dart
@DataClassName('LocalPrediction')
class LocalPredictions extends Table {
  TextColumn get id => text().nullable()();
  DateTimeColumn get generationDate => dateTime()();
  DateTimeColumn get estimatedOvulationDate => dateTime()();
  IntColumn get uncertaintyMarginDays => integer().withDefault(const Constant(2))();
  DateTimeColumn get fertileWindowStartDate => dateTime()();
  DateTimeColumn get fertileWindowEndDate => dateTime()();
  TextColumn get fertilityCategory => text()(); // faible, moyenne, elevee
  RealColumn get fertilityScoreValue => real()();
  TextColumn get confidenceLevel => text()(); // faible, moyen, eleve
  BoolColumn get isPreliminaryLocal => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get factorsJson => text().nullable()(); // Sérialisation des explications

  @override
  Set<Column> get primaryKey => {generationDate};
}
```

---

## 2. Sécurisation Locale via SQLCipher

Pour garantir qu'une personne ayant un accès physique au smartphone ne puisse extraire le fichier SQLite des règles de l'utilisatrice :
1. Une clé de chiffrement aléatoire de 256 bits est générée à l'installation de l'application via un générateur pseudo-aléatoire cryptographique (`Random.secure()`).
2. Cette clé est stockée dans le trousseau matériel sécurisé :
   - **Android Keystore** (avec fallback EncryptedSharedPreferences) ;
   - **iOS Keychain**.
3. La base Drift est ouverte en passant cette clé au driver SQLCipher.
