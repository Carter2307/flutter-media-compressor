# Changelog — Image Utility

## [0.3.0] - 2026-03-30

### Historique partagé + Page d'accueil

#### Système d'historique (API partagée)
- **Stockage** : fichier JSON (`history.json`) + fichiers résultats dans `{appDocDir}/history/` — 0 nouvelle dépendance de stockage
- `HistoryEntry` : modèle avec id, nom original, chemin résultat, type, date, tailles (original/résultat)
- `HistoryService` : lecture/écriture JSON + sauvegarde des buffers sur disque
  - `add()` — écrit le fichier + ajoute au JSON
  - `getAll()` / `getResultBytes()` / `remove()` / `clear()`
  - `groupByType()` — groupement par utilitaire
- `HistoryProvider` : `AsyncNotifierProvider` Riverpod, utilisable par toutes les features
- Fichiers : `lib/core/history/history_entry.dart`, `history_service.dart`, `history_provider.dart`

#### Page d'accueil refaite
- Grille 2x2 des outils (Image, Vidéo, Fond, PDF) avec navigation
- Entrées historiques groupées par type avec icône de section
- Chaque entrée : thumbnail (chargé depuis le disque), nom, taille, date
- État vide : message centré
- Fichier : `lib/features/history/presentation/screens/history_screen.dart`

#### Intégration background_removal → historique
- Après sauvegarde galerie réussie → ajout automatique dans l'historique
- Le buffer résultat est stocké sur disque pour consultation ultérieure

#### Dépendance ajoutée
- `intl` — formatage des dates

---

## [0.2.0] - 2026-03-30

### Suppression de fond (feature complète)

#### Dépendances ajoutées
- `image_picker` — sélection d'image depuis la galerie
- `image_gallery_saver_plus` — sauvegarde dans la galerie
- `permission_handler` — gestion des permissions système

#### API
- Connecté à l'API FastAPI locale (`http://localhost:8000`)
- Endpoint : `POST /api/remove-background` (multipart, query param `processor=birefnet`)
- Réponse en bytes (PNG)
- Endpoints également référencés : `/api/compress`, `/api/resize`, `/api/upscale`

#### Architecture (Clean Architecture)
- **Domain** : `BgRemovalState` avec statuts (idle, picking, processing, done, error) et types de fond (transparent, blanc, noir)
- **Data** : `BgRemovalRepository` — pick image, appel API remove.bg, application de fond coloré, sauvegarde galerie
- **Presentation** : `BgRemovalNotifier` (StateNotifier) + `bgRemovalProvider`

#### UI — Design minimaliste
- **État idle** : écran centré avec icône + bouton "Choisir une photo"
- **État processing** : loader circulaire + texte
- **État résultat** :
  - Preview image avec damier de transparence (CustomPainter)
  - Toggle Original / Résultat (chips animés)
  - Sélecteur de type de fond : Transparent (damier), Blanc, Noir
  - Bouton "Enregistrer dans la galerie" (ElevatedButton)
  - Bouton "Copier dans le presse-papier" (OutlinedButton)
- **État erreur** : message + bouton réessayer
- Bouton refresh dans l'AppBar pour recommencer
- Fichiers :
  - `lib/features/background_removal/domain/bg_removal_state.dart`
  - `lib/features/background_removal/data/bg_removal_repository.dart`
  - `lib/features/background_removal/presentation/providers/bg_removal_provider.dart`
  - `lib/features/background_removal/presentation/screens/background_removal_screen.dart`

---

## [0.1.0] - 2026-03-30

### Setup initial du projet

#### Architecture
- Mise en place de la structure Clean Architecture (`core/`, `features/`, `shared/`, `app/`)
- Création des modules features : `background_removal`, `image_compression`, `video_compression`, `pdf_compression`, `history`
- Chaque feature suit le pattern `data/` → `domain/` → `presentation/screens/`

#### Dépendances ajoutées
- `flutter_riverpod` — gestion d'état
- `go_router` — navigation déclarative
- `dio` — client HTTP
- `google_fonts` — police Work Sans
- `freezed_annotation` + `json_annotation` — modèles immuables
- `freezed` + `build_runner` + `json_serializable` — génération de code (dev)

#### Navigation (GoRouter)
- `StatefulShellRoute.indexedStack` avec 5 branches
- Routes : `/home` (accueil), `/image`, `/video`, `/background`, `/pdf`
- `NavigationBar` Material 3 avec icônes outlined/filled
- Fichiers : `lib/app/router.dart`, `lib/shared/widgets/app_bottom_nav_bar.dart`

#### Gestion d'état (Riverpod)
- `ProviderScope` dans `main.dart`
- `routerProvider` pour GoRouter
- `apiClientProvider` pour le client Dio
- Fichier : `lib/main.dart`, `lib/app/app.dart`

#### Client API (Dio)
- Timeouts : connect 15s, receive 30s, send 30s
- `LogInterceptor` actif en mode debug
- Méthodes : `get`, `post`, `put`, `delete`, `upload` (multipart)
- Fichiers : `lib/core/network/api_client.dart`, `lib/core/network/api_endpoints.dart`

#### Design System
- **Couleur primaire** : `#1565C0` (bleu profond)
- **Police** : Work Sans (Google Fonts)
- **Spacing** : échelle de 4px (4, 8, 12, 16, 20, 24, 32, 40, 48, 64)
- **Border radius** : small (8), medium (12), large (16)
- **Thèmes** : light + dark, suit les préférences système
- **Composants stylisés** : AppBar, Card, ElevatedButton, OutlinedButton, InputDecoration, NavigationBar
- Fichiers : `lib/core/theme/app_colors.dart`, `lib/core/theme/app_spacing.dart`, `lib/core/theme/app_typography.dart`, `lib/core/theme/app_theme.dart`

#### Écrans placeholder
- `HomeScreen` — `/home` (page d'accueil, historique des fichiers traités)
- `ImageCompressionScreen` — `/image`
- `VideoCompressionScreen` — `/video`
- `BackgroundRemovalScreen` — `/background`
- `PdfCompressionScreen` — `/pdf`
