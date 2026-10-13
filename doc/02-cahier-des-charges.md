# 02 — Cahier des Charges Mobile (Flutter)
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

### Informations documentaires
- **Projet** : FertiliteApp
- **Composant** : Client mobile Flutter
- **Statut** : Validé / Prêt pour développement
- **Date** : 24 septembre 2026

---

## 1. Exigences Fonctionnelles Mobiles

L'application Flutter doit respecter les spécifications suivantes :

### 1.1 Parcours Onboarding & Authentification
- **REQ-MOB-01** : Écran d'accueil présentant les trois piliers : Estimer, Expliquer, Informer sans garantir.
- **REQ-MOB-02** : Formulaire d'inscription avec validation locale en temps réel (format email, complexité mot de passe, âge $\ge 12$ ans) et case à cocher obligatoire pour les CGU et la Politique de confidentialité.
- **REQ-MOB-03** : Écran de première configuration du profil guidant l'utilisatrice pour renseigner : objectif (suivi, projet bébé, etc.), durée habituelle du cycle (défaut : 28j), durée habituelle des règles (défaut : 5j), régularité estimée et date des dernières règles.
- **REQ-MOB-04** : Stockage du jeton d'accès et du jeton de rafraîchissement dans `flutter_secure_storage` (chiffré matériellement via Android Keystore / iOS Keychain).

### 1.2 Écran d'Accueil & Calendrier Interactif
- **REQ-MOB-05** : Calendrier mensuel personnalisé affichant :
  - Les jours de saignements réels (teintes de rouge/rose selon intensité) ;
  - Les jours de règles prévus (hachures ou contours discrets) ;
  - La fenêtre fertile estimée (halo violet doux) ;
  - Le jour d'ovulation estimé (icône distinctive / puce centrale).
- **REQ-MOB-06** : Bandeau d'information supérieur rappelant le statut du jour courant (ex. « Jour 14 du cycle — Fertilité estimée : Élevée (Confiance : Moyenne) »).
- **REQ-MOB-07** : Mention légale permanente et discrète : « Les prédictions fournies sont des estimations indicatives et ne constituent pas une méthode de contraception ni un diagnostic médical. »
- **REQ-MOB-08** : Bouton d'action flottant rapide permettant de déclarer immédiatement le début des règles ou d'enregistrer le flux du jour.

### 1.3 Écran de Saisie du Jour (Bottom Sheet / Écran dédié)
- **REQ-MOB-09** : Sélecteur d'intensité du flux menstruel (`Absent`, `Spotting`, `Léger`, `Moyen`, `Abondant`).
- **REQ-MOB-10** : Slider d'intensité de douleur (échelle visuelle de 0 à 10 avec émoticônes bienveillantes).
- **REQ-MOB-11** : Sauvegarde instantanée en base SQLite locale (Drift) : l'interface se met à jour en 0 milliseconde sans bloquer l'écran par un spinner réseau.

### 1.4 Détail de l'Estimation & Explicabilité
- **REQ-MOB-12** : Écran dédié présentant la jauge de fertilité et l'indice de confiance.
- **REQ-MOB-13** : Section interactive « Pourquoi cette estimation ? » listant les facteurs explicatifs dans des cartes ergonomiques faciles à lire.

---

## 2. Exigences Non Fonctionnelles Mobiles

### 2.1 Ergonomie & Accessibilité (a11y)
- **Contrastes de couleurs** conformes aux normes WCAG 2.1 niveau AA (rapport de contraste minimum de 4.5:1 pour le texte standard).
- Prise en charge des lecteurs d'écran (TalkBack sur Android, VoiceOver sur iOS) avec étiquettes sémantiques claires (`Semantics`).
- Support dynamique de l'agrandissement de police système sans débordement de texte (*Text Overflow*).

### 2.2 Mode Hors Connexion (Offline-First)
- **REQ-MOB-14** : Toute action de consultation et de saisie est réalisable sans réseau.
- **REQ-MOB-15** : Intégration d'un mini-moteur de calcul préliminaire côté client pour mettre à jour instantanément la projection calendaire locale dès qu'une date de règles est saisie hors ligne.
- **REQ-MOB-16** : Synchronisation transparente en arrière-plan dès la reconnexion au réseau internet.

### 2.3 Sécurité Mobile
- **REQ-MOB-17 (Verrouillage biométrique)** : Option dans les paramètres pour exiger Face ID / Touch ID / Empreinte digitale lors du lancement de l'application ou après 1 minute d'inactivité.
- **REQ-MOB-18 (Masquage sélecteur d'apps)** : Activation du floutage de l'écran lors du passage de l'application en arrière-plan pour empêcher la visualisation indiscrète des données de cycle dans le sélecteur de tâches.
