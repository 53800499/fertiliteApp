# ADR-002 : Choix de Drift (SQLite) pour la Persistance Locale Offline-First
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

### Statut
Accepté

### Contexte
L'application doit fonctionner hors ligne avec des requêtes relationnelles complexes (filtrage par date, cycles actifs, calculs statistiques locaux). Deux approches de stockage local étaient candidates :
1. Base NoSQL clé-valeur (Hive / Isar / SharedPreferences) ;
2. Base de données relationnelle typée SQLite via **Drift**.

### Décision
Adopter **Drift (SQLite)** avec intégration de **SQLCipher** pour le chiffrement des données de santé au repos.

### Conséquences
- **Avantages** :
  - Requêtes SQL typées avec vérification à la compilation par le code-generator Drift ;
  - Flux réactifs natifs (`watch()`) qui mettent à jour automatiquement l'UI lors de l'insertion d'un jour de règles ;
  - Structure relationnelle identique au backend PostgreSQL, simplifiant considérablement le travail du moteur de synchronisation.
- **Inconvénients** :
  - Nécessite l'exécution régulière de `dart run build_runner build` lors des modifications de tables.
