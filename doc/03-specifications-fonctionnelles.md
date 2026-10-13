# 03 — Spécifications Fonctionnelles & Écrans Mobiles
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

### Informations documentaires
- **Projet** : FertiliteApp (Client Mobile Flutter)
- **Document source** : `docs/Document_SFD_Fertilite.docx` (SFD Version 1.0)
- **Couverture** : Déclinaison mobile des 26 Cas d'Usage (UC-01 à UC-26)
- **Date** : 24 septembre 2026

---

## 1. Cartographie des Écrans & Navigation de l'Application

L'application repose sur une barre de navigation inférieure (*BottomNavigationBar*) à 4 onglets principaux après authentification :

```text
                               ┌──────────────────────────┐
                               │   Onboarding / Accueil   │
                               └────────────┬─────────────┘
                                            │
                                            ▼
                               ┌──────────────────────────┐
                               │ Inscription / Connexion  │
                               └────────────┬─────────────┘
                                            │
                                            ▼
                        ┌───────────────────────────────────────┐
                        │        Configuration du Profil        │
                        └───────────────────┬───────────────────┘
                                            │
                                            ▼
             ┌──────────────────────────────┴──────────────────────────────┐
             │                   Application Principale                    │
             │                   (BottomNavigationBar)                     │
             ├──────────────────┬──────────────────┬───────────────────────┤
             │                  │                  │                       │
             ▼                  ▼                  ▼                       ▼
      ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         ┌─────────────┐
      │  Onglet 1   │    │  Onglet 2   │    │  Onglet 3   │         │  Onglet 4   │
      │             │    │             │    │             │         │             │
      │  Calendrier │    │ Historique  │    │ Statistiques│         │ Paramètres  │
      │  & Accueil  │    │  des Cycles │    │  du Cycle   │         │ & Profil    │
      │             │    │             │    │             │         │             │
      │ (UC-07, 11, │    │  (UC-09, 10)│    │   (UC-23)   │         │ (UC-04, 05, │
      │   12, 14)   │    │             │    │             │         │    06, 22)  │
      └──────┬──────┘    └─────────────┘    └─────────────┘         └─────────────┘
             │
             ├──► [Action Flottante] Saisie rapide Règles & Flux (UC-07, UC-08)
             ├──► [Modal / Page] Détail de la Prédiction & Explications (UC-14, UC-15)
             └──► [Page] Saisie des Indicateurs V2 (T°, Glaire, LH, Symptômes) (UC-16 à 19)
```

---

## 2. Spécifications Détaillées des Écrans Principaux

### 2.1 Écran 1 : Inscription & Connexion (UC-01, UC-02, UC-03)
- **Composants visuels** :
  - Logo épuré FertiliteApp avec baseline apaisante ;
  - Champs texte stylisés : Email, Mot de passe (avec bascule d'affichage du texte masqué) ;
  - Sélecteur de date de naissance avec contrôle de majorité médicale ($\ge 12$ ans) ;
  - Cases à cocher pour les consentements :
    - *« J'accepte les Conditions Générales d'Utilisation »* (Lien cliquable ouvrant une modal) ;
    - *« J'accepte la Politique de Confidentialité des données de santé »* (Lien cliquable) ;
  - Bouton d'action principal « Créer mon compte » désactivé tant que les CGU ne sont pas cochées ;
  - Lien « Mot de passe oublié ? » déclenchant le parcours de récupération (UC-03).
- **BLoC associé** : `AuthBloc` (événements : `RegisterSubmitted`, `LoginSubmitted`, `ForgotPasswordRequested`).

---

### 2.2 Écran 2 : Accueil & Calendrier Mensuel (UC-07, UC-11, UC-14)
- **Composants visuels** :
  - **Header Statut du Jour** :
    - Numéro du jour dans le cycle en cours (ex. « J-12 ») ;
    - Badge coloré du niveau de fertilité : Vert doux (`Faible`), Pêche doux (`Moyenne`), Violet doux (`Élevée`) ;
    - Badge de confiance : 1 à 3 étoiles ou texte explicatif (« Confiance : Élevée ») ;
    - Bouton « Comprendre cette estimation » ouvrant l'Écran de Détail (UC-15) ;
  - **Grille Calendaire Mensuelle** :
    - Navigation par balayage horizontal (swipe) entre mois consécutifs ;
    - Pastilles colorées sur les dates :
      - Rouge brique / rose : Jours de règles réelles ;
      - Contour pointillé rose : Règles futures projetées ;
      - Halo violet clair : Fenêtre fertile estimée ;
      - Pastille violette pleine avec icône fleur/goutte : Ovulation estimée ;
  - **Bouton d'Action Flottant (FAB)** : « + Saisie du jour » ou « Mes règles ont commencé ».
- **BLoC associé** : `CalendarBloc` et `CycleBloc`.

---

### 2.3 Écran 3 : Détail du Jour & Saisie Rapide (UC-08, UC-12)
- Déclenché au toucher d'une date sur le calendrier ou via le bouton de saisie :
  - **Sélecteur de flux menstruel** : 5 pastilles horizontales avec icônes :
    - `Aucun` / `Spotting` / `Léger` / `Moyen` / `Abondant` ;
  - **Échelle de douleur** : Jauge interactive de 0 à 10 avec qualificatifs (« Aucune », « Légère », « Modérée », « Intense ») ;
  - **Notes personnelles** : Champ texte libre sauvegardé localement ;
  - **Bouton d'enregistrement** : Sauvegarde instantanée en base Drift locale, mise à jour immédiate du calendrier et envoi d'un événement de synchronisation en tâche de fond.

---

### 2.4 Écran 4 : Détail de l'Estimation & Facteurs Explicatifs (UC-14, UC-15)
- **Composants visuels** :
  - Graphique en arc ou jauge de probabilité relative (0 à 100%) ;
  - Marge d'incertitude affichée clairement : *« Fenêtre fertile estimée du 12 au 18 octobre (marge de ± 2 jours) »* ;
  - Mention légale mise en exergue : *« Cette estimation statistique reflète votre historique passé et ne saurait garantir une absence de fertilité ou une conception. »* ;
  - **Liste des Facteurs Explicatifs** :
    - Cartes interactives détaillant les sources du calcul :
      - *« Vos 6 derniers cycles durent en moyenne 29 jours »* ;
      - *« Régularité constatée : Forte (variation < 2 jours) »* ;
      - *« Phase lutéale standard de 14 jours appliquée »*.
- **BLoC associé** : `FertilityBloc`.

---

### 2.5 Écran 5 : Historique des Cycles & Correction (UC-09, UC-10)
- Liste chronologique inversée des cycles passés sous forme de cartes élégantes :
  - Date de début, date de fin, durée totale (ex. « 29 jours ») ;
  - Durée des saignements (ex. « 5 jours de règles ») ;
  - Statut : `'Terminé'` ou `'En cours'` ;
  - Bouton « Modifier » : Ouvre l'écran de correction de dates (UC-09).

---

### 2.6 Écran 6 : Statistiques & Tendances du Cycle (UC-23)
- Graphique en barres de l'évolution des durées des 6 à 12 derniers cycles ;
- Indicateurs clés en résumé :
  - **Durée moyenne** : ex. 28.5 jours ;
  - **Cycle le plus court** : 26 jours | **Cycle le plus long** : 31 jours ;
  - **Écart-type / Dispersion** : 1.8 jour ;
  - **Indice de régularité** : « Régulier ».

---

### 2.7 Écran 7 : Centre de Confidentialité & Paramètres (UC-04, UC-05, UC-06, UC-22)
- **Paramètres de sécurité** :
  - Interrupteur « Verrouillage biométrique (Face ID / Empreinte) » ;
  - Interrupteur « Masquer l'écran dans le sélecteur d'applications » ;
- **Consentements de recherche** :
  - Interrupteur « Contribuer à la recherche médicale avec des données anonymisées » (Opt-in désactivé par défaut) ;
- **Sessions connectées** : Liste des téléphones connectés avec bouton « Révoquer » ;
- **Zone de danger** :
  - Bouton rouge « Supprimer mon compte et mes données » avec modal d'avertissement et confirmation par mot de passe (UC-06).
