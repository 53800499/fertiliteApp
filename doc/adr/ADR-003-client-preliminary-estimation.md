# ADR-003 : Calcul Préliminaire d'Estimation Côté Client en Mode Hors Ligne
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

### Statut
Accepté

### Contexte
Lorsqu'une utilisatrice saisit une nouvelle date de règles alors que son smartphone est en mode avion ou sans réseau, attendre le serveur backend pour calculer la nouvelle date d'ovulation dégraderait fortement l'expérience utilisateur et briserait la promesse du mode Offline-First.

### Décision
Implémenter un `LocalFertilityCalculator` léger dans l'application mobile. Ce moteur local applique la règle de phase lutéale standard (-14 jours) et met immédiatement à jour le calendrier sous forme d'une estimation marquée comme "préliminaire". Dès la reconnexion au réseau, l'estimation officielle du serveur NestJS (avec calcul de confiance multivarié et facteurs explicatifs) affine et remplace le calcul local.

### Conséquences
- **Avantages** :
  - Zéro latence perçue : le calendrier s'adapte instantanément ;
  - Fonctionnement hors ligne total et autonome.
- **Inconvénients** :
  - Duplication partielle de la logique de base en Dart (niveau 1 uniquement).
