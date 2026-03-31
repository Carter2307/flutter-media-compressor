import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/pdf_compression_state.dart';
import '../providers/pdf_compression_provider.dart';

class PdfCompressionScreen extends ConsumerWidget {
  const PdfCompressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pdfCompressionProvider);
    final notifier = ref.read(pdfCompressionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compression PDF'),
        actions: [
          if (state.status == PdfCompressionStatus.done ||
              state.status == PdfCompressionStatus.picked)
            IconButton(
              onPressed: () => notifier.reset(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Nouveau fichier',
            ),
        ],
      ),
      body: switch (state.status) {
        PdfCompressionStatus.idle => _IdleView(onPick: notifier.pickFile),
        PdfCompressionStatus.picking => _IdleView(onPick: notifier.pickFile),
        PdfCompressionStatus.picked => _PickedView(state: state, notifier: notifier),
        PdfCompressionStatus.compressing => const _CompressingView(),
        PdfCompressionStatus.done => _ResultView(state: state, notifier: notifier),
        PdfCompressionStatus.error => _ErrorView(
            message: state.errorMessage ?? 'Une erreur est survenue',
            onRetry: () => notifier.reset(),
          ),
      },
    );
  }
}

// ─── Idle ────────────────────────────────────────────────────────────────────

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
              Icons.picture_as_pdf_outlined,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Réduisez le poids\nde vos PDF',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sélectionnez un document depuis votre appareil',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Choisir un PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Picked (Configuration) ──────────────────────────────────────────────────

class _PickedView extends StatelessWidget {
  const _PickedView({required this.state, required this.notifier});
  final PdfCompressionState state;
  final PdfCompressionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        const SizedBox(height: AppSpacing.xs),

        _FileInfoCard(state: state),

        const SizedBox(height: AppSpacing.lg),

        // Aperçu AVANT compression
        Text(
          'APERÇU',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PreviewContainer(previewBytes: state.previewBytes),

        const SizedBox(height: AppSpacing.xl),

        Text(
          'NIVEAU DE COMPRESSION',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _CompressionLevelSelector(
          selected: state.compressionLevel,
          onChanged: notifier.setCompressionLevel,
        ),

        const SizedBox(height: AppSpacing.xxl),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: notifier.compress,
            icon: const Icon(Icons.compress_rounded, size: 18),
            label: const Text('Compresser'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusFull,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton(
            onPressed: notifier.reset,
            child: const Text('Changer de fichier'),
          ),
        ),
      ],
    );
  }
}

// ─── Compressing ─────────────────────────────────────────────────────────────

class _CompressingView extends StatelessWidget {
  const _CompressingView();

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
            'Compression en cours…',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Optimisation des images…',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Result ──────────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  const _ResultView({required this.state, required this.notifier});
  final PdfCompressionState state;
  final PdfCompressionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        const SizedBox(height: AppSpacing.xs),

        _FileInfoCard(state: state),

        const SizedBox(height: AppSpacing.lg),

        if (state.alreadyOptimized) ...[
          const _AlreadyOptimizedBanner(),
          const SizedBox(height: AppSpacing.md),
        ],

        _StatsCard(state: state),

        const SizedBox(height: AppSpacing.xxl),

        // Enregistrer
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: state.alreadyOptimized ? null : () => _save(context),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Enregistrer le PDF'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusFull,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Partager
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: state.alreadyOptimized ? null : () => _share(context),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Partager'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusFull,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Changer le niveau → retour config
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: notifier.backToConfig,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Changer le niveau'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusFull,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Nouveau fichier
        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton(
            onPressed: notifier.reset,
            child: const Text('Nouveau fichier'),
          ),
        ),

        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await notifier.save();
    messenger.showSnackBar(
      SnackBar(
        content: Text(success ? 'PDF enregistré' : 'Échec de l\'enregistrement'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final bytes = state.resultBytes;
    final name = state.originalFileName;
    if (bytes == null || name == null) return;

    try {
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/$name');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de partager le fichier'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ─── Preview Container ────────────────────────────────────────────────────────

class _PreviewContainer extends StatelessWidget {
  const _PreviewContainer({required this.previewBytes});
  final Uint8List? previewBytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: AppSpacing.borderRadiusLarge,
      child: Container(
        height: 240,
        color: theme.colorScheme.surfaceContainerLow,
        child: previewBytes != null
            ? Image.memory(
                previewBytes!,
                fit: BoxFit.contain,
                width: double.infinity,
              )
            : Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
      ),
    );
  }
}

// ─── File Info Card ───────────────────────────────────────────────────────────

class _FileInfoCard extends StatelessWidget {
  const _FileInfoCard({required this.state});
  final PdfCompressionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusMedium,
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf_rounded, size: 36, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.originalFileName ?? '',
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${state.originalPageCount} page${state.originalPageCount > 1 ? 's' : ''}'
                  ' · ${_formatSize(state.originalSizeBytes)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Already Optimized Banner ─────────────────────────────────────────────────

class _AlreadyOptimizedBanner extends StatelessWidget {
  const _AlreadyOptimizedBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: AppSpacing.borderRadiusMedium,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Ce PDF est déjà optimisé — aucune réduction possible.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Compression Level Selector ───────────────────────────────────────────────

class _CompressionLevelSelector extends StatelessWidget {
  const _CompressionLevelSelector({
    required this.selected,
    required this.onChanged,
  });

  final PdfCompressionLevel selected;
  final ValueChanged<PdfCompressionLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PdfCompressionLevel.values.map((level) {
        final isSelected = level == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: level != PdfCompressionLevel.values.last ? AppSpacing.xs : 0,
            ),
            child: ChoiceChip(
              label: Center(child: Text(level.label)),
              selected: isSelected,
              onSelected: (_) => onChanged(level),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.borderRadiusMedium,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Stats Card ───────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.state});
  final PdfCompressionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduction = state.reductionPercent;
    final gained = !state.alreadyOptimized && reduction > 0;

    final afterValue = state.alreadyOptimized
        ? _formatSize(state.originalSizeBytes)
        : _formatSize(state.resultSizeBytes);
    final reductionValue = state.alreadyOptimized
        ? '—'
        : gained
            ? '-${reduction.toStringAsFixed(1)}%'
            : '${reduction.toStringAsFixed(1)}%';
    final reductionColor = state.alreadyOptimized
        ? theme.colorScheme.onSurfaceVariant
        : gained
            ? Colors.green.shade600
            : theme.colorScheme.onSurface;

    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusMedium,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(label: 'Avant', value: _formatSize(state.originalSizeBytes)),
          ),
          Container(width: 1, height: 40, color: theme.dividerColor),
          Expanded(
            child: _StatCell(label: 'Après', value: afterValue),
          ),
          Container(width: 1, height: 40, color: theme.dividerColor),
          Expanded(
            child: _StatCell(
              label: 'Réduction',
              value: reductionValue,
              valueColor: reductionColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(color: valueColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────

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
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text('Erreur', style: theme.textTheme.titleMedium),
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
            ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

// ─── Utils ────────────────────────────────────────────────────────────────────

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes o';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
}
