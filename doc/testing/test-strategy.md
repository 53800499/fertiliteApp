# Plan de Tests Mobiles & Assurance Qualité (Flutter)
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

## 1. Matrice des Tests Automatisés

| Type de Test | Cible | Outil | Couverture visée |
|---|---|---|---|
| **Unit Tests** | Domain Entities, UseCases, Helpers | `flutter_test` | $\ge 90\%$ |
| **BLoC Tests** | Transitions d'états, gestion des erreurs réseau | `bloc_test` | $\ge 95\%$ |
| **Widget Tests** | Formulaire de saisie, Calendrier, Badges | `flutter_test` | Composants critiques |
| **Integration** | Parcours offline, synchronisation de retour réseau | `integration_test` | 100% des parcours critiques |

---

## 2. Commandes de Lancement des Tests Mobiles

```bash
# Exécution de tous les tests unitaires et de BLoCs
flutter test

# Exécution avec rapport de couverture
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Exécution des tests d'intégration sur émulateur connecté
flutter test integration_test/offline_first_flow_test.dart
```
