import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/bg_removal_state.dart';
import '../providers/bg_removal_provider.dart';

class BackgroundRemovalScreen extends ConsumerWidget {
  const BackgroundRemovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bgRemovalProvider);
    final notifier = ref.read(bgRemovalProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppression de fond'),
        actions: [
          if (state.status == BgRemovalStatus.done)
            IconButton(
              onPressed: () => notifier.reset(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Recommencer',
            ),
        ],
      ),
      body: switch (state.status) {
        BgRemovalStatus.idle => _IdleView(onPick: notifier.pickAndProcess),
        BgRemovalStatus.picking => _IdleView(onPick: notifier.pickAndProcess),
        BgRemovalStatus.processing => const _ProcessingView(),
        BgRemovalStatus.done => _ResultView(state: state, notifier: notifier),
        BgRemovalStatus.error => _ErrorView(
            message: state.errorMessage ?? 'Une erreur est survenue',
            onRetry: () => notifier.reset(),
          ),
      },
    );
  }
}

// ─── Idle ───

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onPick});
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppSpacing.paddingHorizontalXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_fix_high_outlined,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Supprimez l\'arrière-plan\nd\'une photo',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sélectionnez une image depuis votre galerie',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Choisir une photo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Processing ───

class _ProcessingView extends StatelessWidget {
  const _ProcessingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Traitement en cours…',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Suppression de l\'arrière-plan',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Result ───

class _ResultView extends StatelessWidget {
  const _ResultView({required this.state, required this.notifier});
  final BgRemovalState state;
  final BgRemovalNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        const SizedBox(height: AppSpacing.xs),

        // Preview
        _ImagePreview(state: state),

        const SizedBox(height: AppSpacing.xl),

        // Background type
        Text(
          'TYPE DE FOND',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _BackgroundTypeSelector(
          selected: state.backgroundType,
          onChanged: notifier.setBackgroundType,
        ),

        const SizedBox(height: AppSpacing.xxl),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _save(context),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _copy(context),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copier'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await notifier.saveToGallery();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Image enregistrée' : 'Échec de l\'enregistrement',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await notifier.copyToClipboard();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Image copiée'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── Image Preview ───

class _ImagePreview extends StatefulWidget {
  const _ImagePreview({required this.state});
  final BgRemovalState state;

  @override
  State<_ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<_ImagePreview> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bytes =
        _showOriginal ? widget.state.originalImageBytes : widget.state.resultImageBytes;

    return Column(
      children: [
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusLarge,
          child: Container(
            color: theme.colorScheme.surfaceContainerLow,
            child: bytes != null
                ? _AdaptiveCheckerboardImage(
                    imageBytes: bytes,
                    showCheckerboard:
                        widget.state.backgroundType == BackgroundType.transparent &&
                            !_showOriginal,
                    theme: theme,
                  )
                : const AspectRatio(aspectRatio: 3 / 4),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Toggle original / result
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ToggleChip(
              label: 'Original',
              selected: _showOriginal,
              onTap: () => setState(() => _showOriginal = true),
            ),
            const SizedBox(width: AppSpacing.xs),
            _ToggleChip(
              label: 'Résultat',
              selected: !_showOriginal,
              onTap: () => setState(() => _showOriginal = false),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─── Background Type Selector ───

class _BackgroundTypeSelector extends StatelessWidget {
  const _BackgroundTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final BackgroundType selected;
  final ValueChanged<BackgroundType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _BgOption(
          label: 'Transp.',
          isSelected: selected == BackgroundType.transparent,
          onTap: () => onChanged(BackgroundType.transparent),
          child: CustomPaint(
            painter: _SmallCheckerboardPainter(),
            size: const Size(36, 36),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _BgOption(
          label: 'Blanc',
          isSelected: selected == BackgroundType.white,
          onTap: () => onChanged(BackgroundType.white),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _BgOption(
          label: 'Noir',
          isSelected: selected == BackgroundType.black,
          onTap: () => onChanged(BackgroundType.black),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _BgOption extends StatelessWidget {
  const _BgOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipOval(child: child),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error ───

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppSpacing.paddingHorizontalXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Erreur',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Adaptive Checkerboard Image ───

class _AdaptiveCheckerboardImage extends StatefulWidget {
  const _AdaptiveCheckerboardImage({
    required this.imageBytes,
    required this.showCheckerboard,
    required this.theme,
  });

  final Uint8List imageBytes;
  final bool showCheckerboard;
  final ThemeData theme;

  @override
  State<_AdaptiveCheckerboardImage> createState() =>
      _AdaptiveCheckerboardImageState();
}

class _AdaptiveCheckerboardImageState extends State<_AdaptiveCheckerboardImage> {
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
  }

  @override
  void didUpdateWidget(_AdaptiveCheckerboardImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBytes != widget.imageBytes) {
      _resolveImageSize();
    }
  }

  void _resolveImageSize() {
    final imageProvider = MemoryImage(widget.imageBytes);
    final stream = imageProvider.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _aspectRatio = info.image.width / info.image.height;
        });
        info.image.dispose();
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _aspectRatio ?? 3 / 4;

    return AspectRatio(
      aspectRatio: ratio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.showCheckerboard)
            CustomPaint(painter: _CheckerboardPainter()),
          Image.memory(
            widget.imageBytes,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

// ─── Checkerboard Painters ───

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 16.0;
    final light = Paint()..color = Colors.white;
    final dark = Paint()..color = const Color(0xFFE0E0E0);

    for (double y = 0; y < size.height; y += cellSize) {
      for (double x = 0; x < size.width; x += cellSize) {
        final isEven = ((x / cellSize).floor() + (y / cellSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          isEven ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SmallCheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 6.0;
    final light = Paint()..color = Colors.white;
    final dark = Paint()..color = const Color(0xFFD0D0D0);

    for (double y = 0; y < size.height; y += cellSize) {
      for (double x = 0; x < size.width; x += cellSize) {
        final isEven = ((x / cellSize).floor() + (y / cellSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          isEven ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
