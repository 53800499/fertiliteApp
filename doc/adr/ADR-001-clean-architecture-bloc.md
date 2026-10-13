# ADR-001 : Choix de la Clean Architecture avec BLoC / Cubit
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

### Statut
Accepté

### Contexte
L'application doit gérer des flux complexes de données locales et distantes, des états asynchrones et une logique d'affichage dynamique selon le mode connecté ou hors ligne. Le choix du gestionnaire d'état et de l'architecture logicielle est déterminant pour la maintenabilité.

### Décision
Adopter la **Clean Architecture** articulée autour de `flutter_bloc` (BLoC pour les flux à états multiples, Cubit pour les bascules simples).

### Conséquences
- **Avantages** :
  - Découplage complet entre l'interface Flutter et la logique métier ;
  - Testabilité unitaire des BLoCs sans monter de widgets Flutter ;
  - Standardisation de l'équipe (flux unidirectionnel événements $\rightarrow$ états).
- **Inconvénients** :
  - Verbosité initiale (nécessite la création de classes d'événements et d'états pour chaque écran).
