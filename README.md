# FertiliteApp — Client Mobile Flutter

> **Application mobile de suivi de cycle et d'estimation intelligente de la fertilité**  
> Développée avec **Flutter 3.x / Dart 3.x**, **Clean Architecture**, **BLoC / Cubit**, et persistance locale **Drift / SQLCipher (Offline-First)**.

---

## 1. Principes Clés de l'Application

- **Offline-First Intégral** : La base locale SQLite (Drift) chiffrée avec SQLCipher constitue l'unique source de vérité pour l'affichage UI. L'application est 100% opérationnelle sans réseau.
- **Moteur Local Préliminaire** : Dès qu'une date de règles est enregistrée hors connexion, un mini-calcul local met à jour instantanément la projection calendaire sans latence perçue.
- **Synchronisation en Arrière-Plan** : Le `SyncEngine` synchronise de manière transparente et incrémentale les modifications dès la détection d'une connexion internet.
- **Sécurité & Confidentialité de Santé** : Verrouillage biométrique (Face ID / empreinte), protection de l'écran dans le sélecteur d'applications, et aucun envoi de données physiologiques vers des outils d'analytics tiers.

---

## 2. Documentation Complète du Frontend

Consultez le dossier [`doc/`](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc) pour les spécifications exhaustives :
- [01 — Document de Cadrage Mobile](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/01-document-cadrage.md)
- [02 — Cahier des Charges Mobile](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/02-cahier-des-charges.md)
- [03 — Spécifications des Écrans (UC-01 à UC-26)](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/03-specifications-fonctionnelles.md)
- [04 — Architecture Clean & BLoC Flutter](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/04-architecture-technique.md)
- [05 — Moteur Offline-First & Synchronisation](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/05-specifications-techniques.md)
- [06 — Base de Données Locale Drift & SQLCipher](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/06-base-de-donnees.md)
- [07 — Client API Réseau Dio](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/07-api.md)
- [08 — Directives de Code Dart 3 & BLoC](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/08-documentation-code.md)
- [09 — Stratégie de Tests Mobile (Unit, Widget, Integration)](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/09-tests.md)
- [10 — Déploiement Stores Google Play & App Store](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/10-deploiement.md)
- [11 — Stratégie Mobile, Télémétrie & Freemium](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/11-doc-strategie-.md)
- [12 — Design System, Ergonomie & Charte Chromatique](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/12-doc-fonctionnelles.md)
- Dossiers spécialisés : [`architecture/`](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/architecture), [`database/`](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/database), [`deployment/`](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/deployment), [`operations/`](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/operations), [`security/`](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/security), [`testing/`](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/testing), [`adr/`](file:///c:/Sikirou/eskay/FertiliteApp/FertiliteApp/frontend/doc/adr).

---

## 3. Démarrage Rapide

### Prérequis
- Flutter SDK 3.19+ ou supérieur
- Android Studio / Xcode configuré avec émulateur ou appareil physique

### Installation & Lancement
```bash
# 1. Se positionner dans le dossier frontend
cd frontend

# 2. Récupérer les dépendances Flutter
flutter pub get

# 3. Générer les fichiers Drift et sérialiseurs JSON
dart run build_runner build --delete-conflicting-outputs

# 4. Lancer l'application en mode développement
flutter run -t lib/main_dev.dart --flavor dev
```

### Lancement des Tests
```bash
# Exécution de tous les tests unitaires et de BLoCs
flutter test

# Exécution avec rapport de couverture
flutter test --coverage
```
