import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/history/presentation/screens/history_screen.dart';
import '../features/image_compression/presentation/screens/image_compression_screen.dart';
import '../features/video_compression/presentation/screens/video_compression_screen.dart';
import '../features/background_removal/presentation/screens/background_removal_screen.dart';
import '../features/pdf_compression/presentation/screens/pdf_compression_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../shared/widgets/app_bottom_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingAsync = ref.watch(onboardingCompletedProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final hasCompleted = onboardingAsync.valueOrNull ?? false;
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!hasCompleted && !isOnboarding) return '/onboarding';
      if (hasCompleted && isOnboarding) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/image',
                builder: (context, state) => const ImageCompressionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/video',
                builder: (context, state) => const VideoCompressionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/background',
                builder: (context, state) => const BackgroundRemovalScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pdf',
                builder: (context, state) => const PdfCompressionScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
