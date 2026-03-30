# IMAGE UTILITY — Cahier des Charges Fonctionnel

> **Application Mobile Flutter**  
> Version : 1.0 | Date : Mars 2025 | Statut : Brouillon  
> Plateforme cible : iOS & Android

---

## Table des matières

1. [Présentation du projet](#1-présentation-du-projet)
2. [Public cible et cas d'usage](#2-public-cible-et-cas-dusage)
3. [Spécifications fonctionnelles](#3-spécifications-fonctionnelles)
4. [Architecture technique](#4-architecture-technique)
5. [Design & Expérience utilisateur](#5-design--expérience-utilisateur)
6. [Exigences non-fonctionnelles](#6-exigences-non-fonctionnelles)
7. [Roadmap & jalons](#7-roadmap--jalons)
8. [Contraintes et risques](#8-contraintes-et-risques)
9. [Glossaire](#9-glossaire)

---

## 1. Présentation du projet

### 1.1 Contexte et motivation

Les créatifs, développeurs et professionnels du contenu digital ont régulièrement besoin d'outils légers pour traiter leurs médias directement depuis leur smartphone. Les solutions existantes sont soit trop lourdes, soit payantes par abonnement, soit fragmentées entre plusieurs applications.

Image Utility répond à ce besoin en regroupant quatre opérations essentielles dans une seule application mobile native, gratuite, rapide et disponible hors-ligne.

### 1.2 Objectif général

Développer une application mobile multiplateforme (iOS & Android) avec Flutter permettant à l'utilisateur de :

- Supprimer le fond d'une photo (détourage automatique par IA)
- Compresser une vidéo en réduisant son poids de façon significative
- Compresser une image (JPEG, PNG, WEBP) en ajustant qualité et dimensions
- Compresser un fichier PDF en réduisant sa taille sans perte visuelle notable

### 1.3 Périmètre

Le projet couvre le développement de l'application mobile uniquement. Aucun compte utilisateur ni backend cloud n'est requis pour la version 1.0. Tous les traitements s'effectuent **localement sur l'appareil**.

---

## 2. Public cible et cas d'usage

### 2.1 Profils utilisateurs

| Profil | Besoin principal |
|---|---|
| Créatifs & graphistes | Détourage rapide pour compositions, e-commerce, réseaux sociaux |
| Photographes amateurs | Compression d'images avant partage ou envoi par e-mail |
| Étudiants & professionnels | Compression de PDF (rapports, CV, présentations) |
| Vidéastes & créateurs de contenu | Réduction du poids de vidéos avant publication |

### 2.2 Cas d'usage principaux

- Détourer un produit photographié sur table pour l'intégrer dans une composition
- Compresser une vidéo de 200 Mo en moins de 50 Mo avant envoi WhatsApp
- Réduire un PDF de 10 Mo pour l'envoyer par e-mail (limite 5 Mo)
- Exporter une photo allégée pour accélérer le chargement d'un site web

---

## 3. Spécifications fonctionnelles

### 3.1 Vue d'ensemble

| ID | Fonctionnalité | Description | Priorité |
|---|---|---|---|
| F01 | Suppression de fond | Détourage IA automatique d'une photo | 🔴 Haute |
| F02 | Compression vidéo | Réduction du poids d'un fichier vidéo | 🔴 Haute |
| F03 | Compression image | Optimisation d'une photo JPEG/PNG/WEBP | 🔴 Haute |
| F04 | Compression PDF | Réduction du poids d'un document PDF | 🔴 Haute |
| F05 | Prévisualisation | Affichage avant/après pour chaque résultat | 🔴 Haute |
| F06 | Partage & export | Sauvegarde dans la galerie ou partage natif | 🔴 Haute |
| F07 | Historique | Liste des fichiers traités récemment | 🟡 Moyenne |
| F08 | Traitement par lot | Traitement de plusieurs fichiers simultanément | 🟢 Basse |

---

### 3.2 F01 – Suppression de fond

**Description**  
L'utilisateur sélectionne une photo depuis sa galerie ou capture une photo directement. L'algorithme supprime automatiquement l'arrière-plan et génère un fichier PNG avec fond transparent.

**Comportements attendus**
- Accès à la galerie et à la caméra via permissions système
- Traitement local via un modèle IA embarqué (ML Kit Selfie Segmentation) ou API tierce (remove.bg)
- Prévisualisation du résultat avec possibilité de zoomer
- Affichage d'un damier pour matérialiser la transparence
- Option : fond de remplacement (couleur unie ou image personnalisée)
- Export en PNG (transparent), JPEG (fond blanc) ou WEBP

**Contraintes**
- Temps de traitement : < 5 secondes pour une image ≤ 12 Mpx
- Formats d'entrée supportés : JPEG, PNG, HEIC, WEBP
- Résolution maximale traitée : 4000 × 4000 px

---

### 3.3 F02 – Compression vidéo

**Description**  
L'utilisateur sélectionne une vidéo depuis sa galerie. L'application applique une compression via FFmpeg en ciblant un niveau de qualité ou une résolution définie par l'utilisateur.

**Comportements attendus**
- Sélecteur de qualité : Haute (720p) / Moyenne (480p) / Basse (360p) ou bitrate personnalisé
- Affichage de la taille estimée après compression avant lancement
- Barre de progression en temps réel
- Aperçu de la vidéo compressée avant export
- Métadonnées conservées ou optionnellement supprimées

**Contraintes**
- Codec cible : H.264 (compatibilité universelle)
- Formats d'entrée : MP4, MOV, AVI, MKV
- Durée maximale supportée : 30 minutes
- Package Flutter : `ffmpeg_kit_flutter`

---

### 3.4 F03 – Compression d'image

**Description**  
L'utilisateur sélectionne une ou plusieurs images. Il ajuste le niveau de qualité et les dimensions cibles. L'application génère une version allégée du fichier.

**Comportements attendus**
- Slider de qualité de 10 % à 100 % avec mise à jour en temps réel du poids estimé
- Option de redimensionnement : largeur/hauteur max ou pourcentage
- Comparaison avant/après côte à côte (split view)
- Affichage du gain en Ko/Mo et du ratio de compression
- Traitement multiple (jusqu'à 10 images en lot)

**Contraintes**
- Formats d'entrée : JPEG, PNG, WEBP, HEIC
- Formats de sortie : JPEG, PNG, WEBP (au choix de l'utilisateur)
- Package Flutter : `flutter_image_compress`

---

### 3.5 F04 – Compression PDF

**Description**  
L'utilisateur importe un fichier PDF. L'application réduit son poids en appliquant une recompression des images embarquées et en supprimant les métadonnées superflues.

**Comportements attendus**
- Sélection de fichier via le gestionnaire de fichiers système
- Affichage du nombre de pages et de la taille originale
- Niveaux de compression : Léger / Standard / Agressif
- Aperçu de la première page du PDF résultant
- Affichage du poids avant/après et du pourcentage de réduction

**Contraintes**
- Package Flutter : `syncfusion_flutter_pdf` ou `pdf` (Dart)
- Traitement limité aux PDF non protégés par mot de passe
- Taille maximale : 100 Mo

---

## 4. Architecture technique

### 4.1 Stack technologique

| Composant | Technologie / Package | Justification |
|---|---|---|
| Framework UI | Flutter 3.x (Dart) | Multiplateforme iOS & Android, une seule codebase |
| Suppression de fond | `remove.bg` API / ML Kit | Haute précision ; ML Kit pour mode offline |
| Compression vidéo | `ffmpeg_kit_flutter` | FFmpeg natif embarqué, performant et complet |
| Compression image | `flutter_image_compress` | Implémentation native iOS/Android, rapide |
| Compression PDF | `syncfusion_flutter_pdf` | Manipulation avancée de PDF en Dart |
| Sélection fichiers | `file_picker` + `image_picker` | Accès galerie, fichiers et caméra unifié |
| Partage / Export | `share_plus` + `gallery_saver` | Partage natif multi-app et sauvegarde galerie |
| Gestion d'état | Riverpod / Bloc | Séparation claire UI / logique métier |
| Navigation | `go_router` | Navigation déclarative, deep linking ready |
| Stockage local | Hive / SharedPreferences | Historique des traitements, préférences |

### 4.2 Architecture applicative

L'application suit une architecture en couches inspirée de Clean Architecture :

- **Presentation layer** : Widgets Flutter, gestion d'état (Riverpod/Bloc)
- **Domain layer** : Use cases, entités (`ImageFile`, `VideoFile`, `PdfFile`)
- **Data layer** : Repositories, datasources (local uniquement en v1.0)
- **Core** : Utilitaires, constantes, thème, extensions

### 4.3 Structure des dossiers

```
lib/
├── core/                   # Thème, constantes, utilitaires
├── features/
│   ├── background_removal/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── image_compression/
│   ├── video_compression/
│   └── pdf_compression/
├── shared/                 # Widgets réutilisables
└── main.dart
```

---

## 5. Design & Expérience utilisateur

### 5.1 Principes directeurs

- **Minimalisme** : interface épurée, une action principale par écran
- **Feedback immédiat** : loaders, progress bars, estimations en temps réel
- **Offline-first** : toutes les fonctions de base fonctionnent sans connexion
- **Accessibilité** : tailles de texte adaptatives, contrastes WCAG AA

### 5.2 Navigation principale

Bottom Navigation Bar avec 5 onglets :

```
[🖼 Image]  [🎬 Vidéo]  [✂️ Fond]  [📄 PDF]  [🕓 Historique]
```

### 5.3 Flux utilisateur type — Compression image

```
Onglet « Image »
    └─► Bouton « Sélectionner »
            └─► Choix : Galerie / Caméra / Fichiers
                    └─► Aperçu + sliders (qualité, dimensions)
                                └─► Estimation poids en temps réel
                                        └─► Bouton « Compresser »
                                                └─► Barre de progression
                                                        └─► Résultat :
                                                            avant/après · poids gagné
                                                            [Sauvegarder] [Partager] [Recommencer]
```

### 5.4 Thème visuel

| Élément | Valeur |
|---|---|
| Mode | Clair & sombre (respect préférences système) |
| Couleur primaire | `#1565C0` (bleu profond) |
| Police | Inter ou Roboto (Google Fonts) |
| Icônes | Material Design 3 + iconographie custom par feature |

---

## 6. Exigences non-fonctionnelles

### 6.1 Performance

| Opération | Cible |
|---|---|
| Compression image ≤ 8 Mo | < 2 secondes |
| Compression vidéo 1 min / 720p | < 30 secondes (appareil mid-range) |
| Suppression de fond offline, 12 Mpx | < 8 secondes |
| Démarrage à froid de l'application | < 2 secondes |

### 6.2 Compatibilité

- **iOS** : version 14.0 minimum
- **Android** : API 21 (Android 5.0 Lollipop) minimum
- Support des appareils 64-bit uniquement

### 6.3 Sécurité & vie privée

- Aucun fichier utilisateur n'est envoyé à un serveur sans consentement explicite
- Les fichiers traités sont stockés temporairement dans le cache, effaçables depuis l'app
- Conformité RGPD : aucune collecte de données personnelles en v1.0
- Permissions demandées au moment de l'usage (just-in-time permissions)

### 6.4 Fiabilité

- Gestion des erreurs : messages clairs en cas d'échec (fichier corrompu, mémoire insuffisante…)
- Pas de crash sur interruption (appel entrant, mise en arrière-plan)
- Reprise automatique possible pour les compressions longues

---

## 7. Roadmap & jalons

### v1.0 – MVP

- [ ] Compression image avec aperçu avant/après
- [ ] Compression PDF basique
- [ ] Compression vidéo (qualité prédéfinie)
- [ ] Suppression de fond (mode online via API)
- [ ] Export / partage natif

### v1.1

- [ ] Historique des fichiers traités
- [ ] Mode sombre complet
- [ ] Suppression de fond offline (modèle embarqué)
- [ ] Compression vidéo avec paramètres avancés

### v2.0

- [ ] Traitement par lot (images, PDF)
- [ ] Éditeur basique post-détourage (recadrage, remplacement de fond)
- [ ] Widget iOS / Android pour accès rapide
- [ ] Internationalisation (EN, FR, ES)

---

## 8. Contraintes et risques

### 8.1 Contraintes techniques

- `ffmpeg_kit_flutter` augmente significativement la taille de l'APK/IPA (+30 à 50 Mo)
- Le traitement vidéo est intensif en CPU : prévoir une gestion thermique et un feedback clair
- ML Kit Selfie Segmentation est optimisé pour les portraits ; les résultats sur objets peuvent être moins précis
- La compression PDF en Dart pur est limitée : envisager une approche via impression système sur iOS

### 8.2 Matrice des risques

| Risque | Probabilité | Mitigation |
|---|---|---|
| Performance insuffisante sur anciens appareils | 🟡 Moyenne | Tests sur devices bas de gamme dès le sprint 1 ; dégradation gracieuse |
| Qualité de détourage insatisfaisante offline | 🔴 Haute | Fallback sur API remove.bg + cache résultat |
| Taille d'app trop importante (> 100 Mo) | 🟡 Moyenne | Séparation en flavors / download-on-demand pour FFmpeg |
| Refus App Store (permissions excessives) | 🟢 Basse | Déclaration précise des usages dans Privacy Manifest (iOS 17+) |

---

## 9. Glossaire

| Terme | Définition |
|---|---|
| Flutter | Framework open-source de Google pour créer des apps iOS et Android à partir d'une seule codebase en Dart |
| FFmpeg | Bibliothèque multimédia open-source pour l'encodage, le décodage et la manipulation de vidéos et audios |
| Détourage | Opération consistant à isoler le sujet d'une image en supprimant l'arrière-plan |
| HEIC | Format d'image haute efficacité utilisé par défaut sur iPhone |
| MVP | Minimum Viable Product — version minimale du produit permettant de valider les hypothèses clés |
| RGPD | Règlement Général sur la Protection des Données (réglementation européenne) |
| ML Kit | Bibliothèque de machine learning mobile de Google, disponible pour iOS et Android |
| Clean Architecture | Pattern d'architecture logicielle qui sépare les responsabilités en couches indépendantes |

---

*Document confidentiel – usage interne*  
*Image Utility v1.0 – Mars 2025*
