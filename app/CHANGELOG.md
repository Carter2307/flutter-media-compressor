# Changelog — Image Utility

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
