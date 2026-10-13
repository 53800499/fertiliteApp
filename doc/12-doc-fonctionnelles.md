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
