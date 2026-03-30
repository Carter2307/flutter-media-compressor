import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class VideoCompressionScreen extends StatelessWidget {
  const VideoCompressionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Vidéo')),
      body: Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Compression vidéo',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Réduisez le poids de vos vidéos',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.video_library_outlined),
                label: const Text('Sélectionner une vidéo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
