# 11 — Stratégie Mobile, Télémétrie & Monétisation
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

### Informations documentaires
- **Projet** : FertiliteApp (Client Mobile Flutter)
- **Axes** : Analytics respectueux de la vie privée, rétention et modèle freemium
- **Date** : 24 septembre 2026

---

## 1. Télémétrie & Analytics : La Ligne Rouge de la Confidentialité

Dans FertiliteApp, **aucune donnée physiologique ne transite dans les outils d'analytics tiers** (comme Firebase Analytics ou Mixpanel).

### Ce qui est STRICTEMENT INTERDIT de logger :
- La date de début ou fin des règles ;
- La valeur des températures, glaires ou symptômes ;
- Le niveau estimé de fertilité ou la date d'ovulation ;
- Les notes libres ou toute mention de rapports intimes.

### Ce qui est mesuré de manière anonyme :
- L'ouverture de l'application et la session globale (DAU / MAU) ;
- La complétion de l'onboarding (taux de conversion étape par étape) ;
- Les métriques techniques (taux de crash via Sentry, latence de synchronisation hors ligne, temps de démarrage de l'app à froid).

---

## 2. Modèle Économique Freemium (Achats In-App)

Conformément au chapitre 17 du document de cadrage :

| Fonctionnalité | Plan Gratuit | Plan Premium |
|---|---|---|
| Suivi du cycle menstruel & flux | Inclus | Inclus |
| Calendrier interactif & projections | Inclus | Inclus |
| Estimation basique de fertilité | Inclus | Inclus |
| Notifications de rappel | Inclus | Inclus |
| **Explications détaillées & facteurs multivariés** | Limité (1 facteur) | **Complet (tous les facteurs)** |
| **Statistiques approfondies & tendances historiques** | 3 derniers cycles | **Historique illimité** |
| **Intégration indicateurs complémentaires V2** | Température seule | **T° + Glaire + Tests LH + Symptômes** |
| **Export des données pour consultation médicale** | Format texte brut | **Rapport PDF soigné pour le médecin** |

### Intégration Technique des Achats In-App
Utilisation du package officiel `in_app_purchase` de Flutter, avec validation cryptographique des reçus côté serveur NestJS (`POST /api/v1/billing/verify-receipt`) avant activation des droits dans la base PostgreSQL.
