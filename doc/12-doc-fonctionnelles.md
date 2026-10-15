# 12 — Spécifications UI/UX, Design System & Ergonomie
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

### Informations documentaires
- **Projet** : FertiliteApp (Client Mobile Flutter)
- **Thème visuel** : Doux, bienveillant, non médicalisé et haut de gamme
- **Date** : 24 septembre 2026

---

## 1. Charte Graphique & Palette Harmonique

L'application refuse l'aspect clinique et anxiogène des hôpitaux pour adopter une esthétique apaisante, moderne et chaleureuse.

```text
               PALETTE CHROMATIQUE DU CYCLE (DESIGN TOKENS)
               
 ┌──────────────────────┐   ┌──────────────────────┐   ┌──────────────────────┐
 │     Menstruation     │   │   Fenêtre Fertile    │   │  Pic d'Ovulation     │
 │       (Saignements)  │   │     (Période Clé)    │   │       (J-Ovu)        │
 │                      │   │                      │   │                      │
 │     #D9534F (Doux)   │   │     #9D71E8 (Lilas)  │   │    #7B42BC (Pourpre) │
 └──────────────────────┘   └──────────────────────┘   └──────────────────────┘
 ┌──────────────────────┐   ┌──────────────────────┐   ┌──────────────────────┐
 │   Fertilité Faible   │   │  Arrière-plan Doux   │   │    Texte & Contraste │
 │     (Phase Repos)    │   │     (Fond d'Écran)   │   │       (Lisibilité)   │
 │                      │   │                      │   │                      │
 │     #6BAA75 (Sauge)  │   │     #FAF8F5 (Crème)  │   │    #2D2424 (Ardoise) │
 └──────────────────────┘   └──────────────────────┘   └──────────────────────┘
```

### Valeurs Hexadécimales & Rôles Sémantiques :
- **Menstruation active** : `#D9534F` (Rouge brique velouté) ;
- **Menstruation prévue** : `#F2A4A2` avec hachures ou bordure pointillée ;
- **Fenêtre fertile** : `#9D71E8` (Lilas lumineux) ;
- **Jour d'ovulation** : `#7B42BC` avec un anneau de pulsation doux ;
- **Fertilité faible** : `#6BAA75` (Vert sauge doux) ;
- **Surfaces & Cards** : `#FFFFFF` avec ombrages légers (`box-shadow: 0 4px 16px rgba(0,0,0,0.04)`) ;
- **Fond de page** : `#FAF8F5` (Blanc cassé chaud).

---

## 2. Typographie & Lisibilité

Utilisation de la police moderne **Plus Jakarta Sans** ou **Outfit** via `google_fonts` :
- **Titres d'écrans** : Outfit Semi-Bold 24sp ;
- **Sous-titres & Badges** : Plus Jakarta Sans Medium 16sp ;
- **Corps de texte** : Plus Jakarta Sans Regular 14sp (hauteur de ligne : 1.5 pour une lecture aérée) ;
- **Chiffres du calendrier** : Outfit Medium 16sp centrés.

---

## 3. Ligne Éditoriale & Micro-Rédaction (Copywriting Éthique)

L'expression verbale de l'application façonne la confiance et évite toute détresse psychologique :

| Ce qu'on évite (Langage anxiogène ou faux) | Ce qu'on écrit (Bienveillant, clair et prudent) |
|---|---|
| « Vous ne pouvez pas tomber enceinte aujourd'hui. » | « La probabilité estimée de conception est aujourd'hui faible. » |
| « Vous ovulez aujourd'hui avec certitude. » | « Votre ovulation est estimée autour de cette date. » |
| « Cycle anormal détecté ! » | « Une variabilité est constatée sur ce cycle par rapport à votre moyenne. » |
| « Prédiction garantie. » | « Estimation basée sur l'analyse de vos 5 derniers cycles. » |

---

## 4. Illustrations & Visuels

> **Illustrations et visuels** : des images pertinentes représentant des femmes de façon naturelle, sans tomber dans les clichés.

### 4.1 Principes Directeurs
- **Authenticité & Réalisme** : Représenter les femmes dans des postures naturelles et apaisantes de la vie quotidienne (écoute de son corps, repos, bien-être, travail, sérénité), loin des poses figées ou hyper-médicalisées.
- **Diversité & Inclusivité** : Refléter la pluralité des profils, carnations et morphologies, en résonance directe avec les personas cibles de l'application (Amina, Khadija, Fatim).
- **Zéro Cliché & Zéro Infantilisation** :
  - Proscrire les clichés désuets (surabondance de rose fuchsia, cœurs caricaturaux, esthétique kitsch) ;
  - Proscrire la dramatisation anxiogène de la douleur ou des symptômes menstruels ;
  - Prôner une approche éditoriale sobre, élégante, scientifique et bienveillante.

### 4.2 Ligne Graphique des Visuels
- **Style artistique** : Illustrations vectorielles minimalistes, aquarelles numériques épurées ou photographies documentaires chaleureuses avec une lumière douce et naturelle.
- **Intégration chromatique** : Respect strict de la palette harmonique (améthyste, lilas `#9D71E8`, pêche `#FFAB91`, sauge `#6BAA75` et fond crème `#FAF8F5`).
- **Cas d'usage applicatifs** :
  1. *Écrans d'Onboarding* : Présentation des 3 piliers (Estimer, Expliquer, Informer sans garantir) avec des scènes de vie inspirantes ;
  2. *États Vides (Empty States)* : Illustrations bienveillantes invitant à la première saisie de cycle sans sentiment de vide clinique ;
  3. *Pédagogie & Explicabilité* : Schémas corporels élégants et éducatifs pour la section « Pourquoi cette estimation ? ».

