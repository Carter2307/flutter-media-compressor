import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/button.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Grid of feature icons in diamond layout
              _FeatureIconsGrid(theme: theme),

              const Spacer(flex: 2),

              // App icon + title
              Icon(
                Icons.compress_rounded,
                size: 44,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Compressez vos\nfichiers en un clic',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Réduisez la taille de vos images, vidéos et PDF '
                'directement depuis votre téléphone. Rapide, simple et efficace.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // Get started button
              AppButton(
                onPressed: () async {
                  await completeOnboarding();
                  ref.invalidate(onboardingCompletedProvider);
                  if (context.mounted) {
                    context.go('/home');
                  }
                },
                label: 'Commencer',
                size: AppButtonSize.lg,
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

// Diamond-shaped grid of 4 feature icons
class _FeatureIconsGrid extends StatelessWidget {
  const _FeatureIconsGrid({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    const iconSize = 68.0;
    const spacing = 12.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: 1 icon centered
        _FeatureIcon(
          icon: Icons.image_outlined,
          color: const Color(0xFF4CAF50),
          size: iconSize,
        ),
        const SizedBox(height: spacing),
        // Row 2: 2 icons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FeatureIcon(
              icon: Icons.videocam_outlined,
              color: const Color(0xFFE91E63),
              size: iconSize,
            ),
            const SizedBox(width: spacing),
            _FeatureIcon(
              icon: Icons.auto_fix_high_outlined,
              color: const Color(0xFF9C27B0),
              size: iconSize,
            ),
          ],
        ),
        const SizedBox(height: spacing),
        // Row 3: 3 icons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FeatureIcon(
              icon: Icons.picture_as_pdf_outlined,
              color: const Color(0xFFFF5722),
              size: iconSize,
            ),
            const SizedBox(width: spacing),
            _FeatureIcon(
              icon: Icons.compress_rounded,
              color: const Color(0xFF2196F3),
              size: iconSize,
            ),
            const SizedBox(width: spacing),
            _FeatureIcon(
              icon: Icons.speed_rounded,
              color: const Color(0xFFFF9800),
              size: iconSize,
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        icon,
        size: size * 0.45,
        color: color,
      ),
    );
  }
}
