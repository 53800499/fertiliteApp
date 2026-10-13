# 05 — Spécifications Techniques Mobile : Moteur Offline-First & Synchro
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

### Informations documentaires
- **Projet** : FertiliteApp (Client Mobile Flutter)
- **Composant** : Moteur Hors Ligne (`core/sync/`) & Calcul Local
- **Base locale** : SQLite via **Drift** (avec chiffrement SQLCipher)
- **Date** : 24 septembre 2026

---

## 1. Philosophie & Principe « Local-As-Source-Of-Truth »

Dans FertiliteApp, l'interface utilisateur n'interroge **jamais directement le réseau** pour afficher les données. 

> **Principe fondamental : L'interface lit toujours et uniquement la base de données locale Drift.**

```text
                               UTILISATRICE
                                    │
                                    ▼ [Action de Saisie]
                    ┌───────────────────────────────┐
                    │      BLoC / Presentation      │
                    └───────────────┬───────────────┘
                                    │ Écriture immédiate (< 10 ms)
                                    ▼
                    ┌───────────────────────────────┐
                    │       Base Locale Drift       │◄───── Source unique de vérité
                    │      (SQLite / SQLCipher)     │       pour l'affichage UI
                    └───────┬───────────────▲───────┘
                            │               │
               Flux réactif │               │ Réconciliation
               (Watchers)   │               │ & Mise à jour
                            ▼               │
                    ┌───────────────┐       │
                    │ Calcul Local  │       │
                    │ Préliminaire  │       │
                    └───────────────┘       │
                                            │
                            ┌───────────────┴───────────────┐
                            │          Sync Engine          │
                            │   (Worker d'arrière-plan)     │
                            └───────────────┬───────────────┘
                                            │
                                  Réseau disponible ?
                                     (Oui / Non)
                                            │
                                            ▼
                            ┌───────────────────────────────┐
                            │          Backend API          │
                            │           (NestJS)            │
                            └───────────────────────────────┘
```

---

## 2. Le Moteur d'Estimation Local Préliminaire

Pour éviter que l'utilisatrice hors connexion ne voie un calendrier vide après avoir enregistré ses règles, l'application intègre une version compacte en Dart du `CalendarEngine` :

```dart
// lib/features/fertility/data/local_fertility_calculator.dart

class LocalFertilityCalculator {
  /// Calcule instantanément une projection calendaire locale
  static LocalPredictionResult calculatePreliminary({
    required DateTime lastPeriodStartDate,
    required int averageCycleLengthDays,
  }) {
    // Règle biologique de la phase lutéale standard (14 jours)
    final estimatedOvulation = lastPeriodStartDate.add(
      Duration(days: averageCycleLengthDays - 14),
    );

    // Fenêtre fertile : 5 jours avant + jour d'ovulation + 1 jour après
    final fertileStart = estimatedOvulation.subtract(const Duration(days: 5));
    final fertileEnd = estimatedOvulation.add(const Duration(days: 1));

    return LocalPredictionResult(
      estimatedOvulationDate: estimatedOvulation,
      fertileWindowStartDate: fertileStart,
      fertileWindowEndDate: fertileEnd,
      isLocalPreliminary: true, // Marqueur indiquant qu'une validation serveur viendra affiner
      confidenceLevel: 'moyen',
    );
  }
}
```

Dès la reconnexion, l'estimation officielle du serveur NestJS (avec niveau de confiance complet et facteurs explicatifs) viendra remplacer cette estimation préliminaire locale.

---

## 3. Le Moteur de Synchronisation (`SyncEngine`)

### 3.1 Cycle de Vie d'un Enregistrement
Chaque table locale dispose de deux colonnes de synchronisation :
1. `id_client_local` : UUID v4 généré localement lors de la création de la ligne sur le mobile.
2. `statut_synchronisation` : Énumération (`en_attente`, `synchronise`, `conflit`).

```text
[Saisie Utilisatrice] ──► INSERT (id_client_local: UUID, statut: 'en_attente')
                                  │
                                  ▼
                        [Détection Réseau OK]
                                  │
                                  ▼
           POST /api/v1/cycles/start avec id_client_local
                                  │
                  ┌───────────────┴───────────────┐
                  ▼                               ▼
            [Succès 201]                     [Erreur 4xx/5xx]
                  │                               │
        UPDATE statut_synchro =            Maintien en file d'attente
           'synchronise'                   avec politique de retry
        Stockage ID serveur                exponentiel
```

---

## 4. Politique de Résolution des Conflits

Dans les rares cas où une donnée a été modifiée sur deux appareils différents hors ligne :
- **Règle retenue** : **Dernière écriture horodatée gagnante (Last-Write-Wins - LWW)** basée sur le timestamp UTC `date_maj`.
- **Intégrité physiologique** : Pour les cycles menstruels, si deux cycles ouverts en conflit sont détectés, l'application conserve la date la plus récente et consigne la divergence dans un journal local pour éviter toute perte d'historique.
