# 10 — Déploiement & Publication Stores (Flutter)
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

### Informations documentaires
- **Projet** : FertiliteApp (Client Mobile)
- **Plateformes cibles** : Google Play Store (Android) & Apple App Store (iOS)
- **Automatisation** : Fastlane & GitHub Actions
- **Date** : 24 septembre 2026

---

## 1. Gestion des Flavors (Environnements)

L'application est structurée en 3 environnements étanches :
- **Development (`dev`)** : `com.fertiliteapp.app.dev` (API locale / staging) ;
- **Staging (`staging`)** : `com.fertiliteapp.app.staging` (TestFlight / Internal Testing) ;
- **Production (`prod`)** : `com.fertiliteapp.app` (Stores publics).

Commande de build Flutter avec flavor :
```bash
flutter build appbundle --flavor prod -t lib/main_prod.dart
flutter build ipa --flavor prod -t lib/main_prod.dart
```

---

## 2. Configuration & Sécurité Android

### 2.1 Obfuscation & R8 (`android/app/proguard-rules.pro`)
L'obfuscation du code source est activée pour protéger la propriété intellectuelle du moteur local :

```proguard
# Préservation des classes de modèles pour Drift et JSON
-keep class com.fertiliteapp.app.data.models.** { *; }
-keepattributes *Annotation*,Signature,InnerClasses
```

### 2.2 Signature de l'App Bundle (AAB)
Fichier `android/key.properties` (non versionné dans Git) :
```properties
storePassword=SECURE_STORE_PASSWORD
keyPassword=SECURE_KEY_PASSWORD
keyAlias=fertiliteapp-release-key
storeFile=/secure/keystores/fertiliteapp-release.keystore
```

---

## 3. Conformité aux Directives des Stores de Santé

Les politiques de Google Play et de l'Apple App Store encadrent rigoureusement les applications de santé féminine :
1. **Google Play (Health Content & Apps Policy)** :
   - Déclaration formelle dans la console Play de la catégorie Santé Reproductive ;
   - Obligation d'afficher un disclaimer de non-substitution médicale directement sur la fiche du Store et au premier lancement de l'application.
2. **Apple App Store (Guideline 1.4 — Physical Harm & Medical Care)** :
   - Transparence sur les sources algorithmiques utilisées ;
   - Interdiction de promettre l'évitement ou l'obtention d'une grossesse avec un taux de réussite de 100%.
