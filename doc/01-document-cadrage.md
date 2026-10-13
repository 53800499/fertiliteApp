# 01 — Document de Cadrage Frontend Mobile
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

### Informations documentaires
- **Projet** : FertiliteApp
- **Composant** : Application mobile Flutter (Android & iOS)
- **Framework cible** : Flutter 3.x / Dart 3.x
- **Date** : 24 septembre 2026
- **Documents sources de référence** :
  - `docs/Document_de_cadrage_Application_Estimation_Fertilite.pdf` (Version 1.0, 24 août 2026)
  - `docs/Document_SFD_Fertilite.docx` (Version 1.0, 14 septembre 2026)
  - `docs/Document_Modelisation_BDD_Fertilite.docx` (Version 1.0, 14 septembre 2026)

---

## 1. Vision Mobile & Proposition de Valeur

L'application mobile **FertiliteApp** est l'interface privilégiée et intime de l'utilisatrice avec son corps. Sa mission est d'offrir une expérience utilisateur :
- **Instantanée & Fluide** : Zéro temps de chargement perçu lors de la consultation ou de la saisie ;
- **100% Fonctionnelle Hors Connexion (Offline-First)** : L'utilisatrice doit pouvoir consigner ses règles, symptômes et consulter son calendrier prévisionnel sans aucune connexion internet active ;
- **Bienveillante & Non Alarmiste** : Clarté absolue sur le fait qu'une estimation n'est jamais un diagnostic médical ni une garantie contraceptive ;
- **Respectueuse de l'Intimité** : Verrouillage biométrique rapide, masquage de l'écran dans le sélecteur d'applications, et conservation des données sensibles localement.

---

## 2. Public Cible & Personas Mobiles

1. **Amina (26 ans) — Suivi du cycle & compréhension de son corps** :
   - Besoin : Visualiser simplement l'arrivée de ses règles et comprendre les variations de son humeur et de son énergie au cours du mois.
   - Usage : 2 à 3 fois par semaine, saisie rapide en 15 secondes.
2. **Khadija (31 ans) — Projet de conception (Désir de grossesse)** :
   - Besoin : Identifier avec précision la fenêtre fertile estimée, observer la glaire cervicale, tester l'ovulation (LH) et comprendre les facteurs d'explication.
   - Usage : Quotidien durant la première phase du cycle.
3. **Fatim (22 ans) — Irrégularité & observation** :
   - Besoin : Comprendre pourquoi ses cycles oscillent entre 25 et 38 jours sans être paniquée par des moyennes théoriques inadaptées.
   - Usage : Enregistrement rigoureux de chaque début de règles et consultation des statistiques.

---

## 3. Périmètre Fonctionnel Mobile (MVP vs Phases Suivantes)

### 3.1 Périmètre MVP (Version 1) — Obligatoire
- **Onboarding & Configuration initiale (M1)** : Présentation des principes déontologiques, acceptation des CGU/confidentialité, saisie du profil déclaratif (objectif, durées habituelles).
- **Authentification & Session locale (M1)** : Inscription, connexion, persistance sécurisée du token JWT dans le Keystore/Keychain, déconnexion.
- **Gestion du cycle (M2)** : Bouton d'action rapide « Mes règles ont commencé », sélection du flux quotidien (spotting, léger, moyen, abondant) et niveau de douleur.
- **Calendrier interactif (M3)** : Vue mensuelle avec code couleur doux (règles, fertilité estimée, jour d'ovulation estimé) et écran de détail d'une journée.
- **Consultation de la prédiction (M4)** : Jauge de fertilité, niveau de confiance (faible, moyen, élevé), écran explicatif « Pourquoi cette estimation ? ».
- **Notifications locales & push (M6)** : Réception et gestion des rappels quotidiens et alertes de fenêtre fertile.
- **Historique & Statistiques (M7)** : Liste des cycles passés, durées moyennes, min/max, indice de régularité.
- **Paramètres & Confidentialité (M1)** : Verrouillage biométrique (Face ID / empreinte digitale), gestion des consentements, demande de suppression du compte.

### 3.2 Périmètre V2 & Évolutions
- Saisie des biomarqueurs avancés : Température basale (°C), glaire cervicale, résultats de tests d'ovulation LH, catalogue de symptômes catégorisés (M5).
- Écran d'analyse contextuelle d'un rapport intime avec avertissement explicite (M8).
- Gestion de l'abonnement Premium via In-App Purchases Google Play Billing / StoreKit (M9).

---

## 4. Contraintes Techniques Mobiles

1. **Compatibilité** :
   - Android : API 26+ (Android 8.0 Oreo ou supérieur) ;
   - iOS : iOS 14.0 ou supérieur.
2. **Performances UI** : 60 images par seconde (FPS) constantes, absence de saccades (jank), animations fluides (animations implicites Flutter).
3. **Empreinte mémoire & batterie** :
   - Taille de l'application : < 35 Mo (APK/IPA optimisé) ;
   - Aucun service d'arrière-plan permanent énergivore ;
   - Synchronisation réseau opportuniste et économique.
