import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class ImageCompressionScreen extends StatelessWidget {
  const ImageCompressionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Image')),
      body: Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Compression d\'image',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Optimisez vos photos JPEG, PNG et WEBP',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Sélectionner une image'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
