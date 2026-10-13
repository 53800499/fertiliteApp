# Modèle de Données Local & DAOs — Drift Mobile
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

## 1. Organisation des DAOs (Data Access Objects)

Pour découpler les requêtes SQL locales des couches supérieures, chaque table dispose d'un DAO typé généré par Drift :

```dart
// lib/core/database/daos/cycle_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/local_cycles_table.dart';

part 'cycle_dao.g.dart';

@DriftAccessor(tables: [LocalCycles])
class CycleDao extends DatabaseAccessor<AppDatabase> with _$CycleDaoMixin {
  CycleDao(AppDatabase db) : super(db);

  // Flux réactif observant le cycle actif
  Stream<LocalCycle?> watchCurrentCycle() {
    return (select(localCycles)..where((tbl) => tbl.status.equals('en_cours')))
        .watchSingleOrNull();
  }

  // Insertion ou mise à jour locale
  Future<void> insertOrUpdateCycle(LocalCyclesCompanion cycle) {
    return into(localCycles).insertOnConflictUpdate(cycle);
  }

  // Sélection des enregistrements non synchronisés
  Future<List<LocalCycle>> getPendingSyncCycles() {
    return (select(localCycles)..where((tbl) => tbl.syncStatus.equals('en_attente'))).get();
  }
}
```
