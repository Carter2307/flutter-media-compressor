import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/history/history_entry.dart';
import '../../../../core/history/history_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/button.dart';

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes o';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
}

String _relativeDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) return DateFormat('HH:mm').format(date);
  if (diff == 1) return 'hier';
  if (diff == 2) return 'avant-hier';
  return DateFormat('dd/MM/yyyy').format(date);
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Erreur de chargement')),
        data: (entries) => _HomeContent(entries: entries),
      ),
    );
  }
}

// ─── Content ───

class _HomeContent extends StatefulWidget {
  const _HomeContent({required this.entries});
  final List<HistoryEntry> entries;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  String _query = '';

  List<HistoryEntry> get _filtered {
    if (_query.isEmpty) return widget.entries;
    final q = _query.toLowerCase();
    return widget.entries
        .where((e) => e.originalName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Title + search
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Récents',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher',
                      prefixIcon: const Icon(Icons.search, size: 22),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),

          // Grid or empty state
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(theme: theme),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSpacing.lg,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.52,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _GridItem(entry: filtered[index]),
                  childCount: filtered.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xxl),
          ),
        ],
      ),
    );
  }
}

// ─── Grid Item ───

class _GridItem extends ConsumerWidget {
  const _GridItem({required this.entry});
  final HistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showDetailSheet(context, ref),
      child: Column(
        children: [
          // Preview
          AspectRatio(
            aspectRatio: 4 / 4,
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusMedium,
              child: Container(
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerLow,
                child: _buildPreview(theme),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Name
          Text(
            entry.originalName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),

          // Date
          Text(
            _relativeDate(entry.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          // Type
          Text(
            entry.type.shortLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    switch (entry.type) {
      case HistoryType.pdf:
        return Center(
          child: Icon(
            Icons.picture_as_pdf_rounded,
            size: 40,
            color: const Color(0xFFD84315).withValues(alpha: 0.8),
          ),
        );
      case HistoryType.video:
        return Center(
          child: Icon(
            Icons.videocam_rounded,
            size: 40,
            color: const Color(0xFF7B1FA2).withValues(alpha: 0.8),
          ),
        );
      case HistoryType.image:
      case HistoryType.background:
        final file = File(entry.resultPath);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
        }
        return Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
    }
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HistoryDetailSheet(entry: entry, ref: ref),
    );
  }
}

// ─── Detail Sheet ───

class _HistoryDetailSheet extends StatelessWidget {
  const _HistoryDetailSheet({required this.entry, required this.ref});
  final HistoryEntry entry;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = File(entry.resultPath);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final compression = entry.originalSizeBytes > 0
        ? ((1 - entry.resultSizeBytes / entry.originalSizeBytes) * 100)
            .toStringAsFixed(0)
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                  ),
                ),

                // Preview
                ClipRRect(
                  borderRadius: AppSpacing.borderRadiusLarge,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 350),
                    color: theme.colorScheme.surfaceContainerLow,
                    child: entry.type == HistoryType.pdf
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.picture_as_pdf_rounded,
                                  size: 64,
                                  color: const Color(0xFFD84315).withValues(alpha: 0.8),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  entry.originalName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          )
                        : entry.type == HistoryType.video
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.videocam_rounded,
                                      size: 64,
                                      color: const Color(0xFF7B1FA2).withValues(alpha: 0.8),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      entry.originalName,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              )
                        : file.existsSync()
                            ? Image.file(file, fit: BoxFit.contain)
                            : Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 48,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // File name
                Text(
                  entry.originalName,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppSpacing.md),

                // Info rows
                _InfoRow(
                  icon: Icons.category_outlined,
                  label: 'Type',
                  value: entry.type.label,
                  theme: theme,
                ),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: dateFormat.format(entry.createdAt),
                  theme: theme,
                ),
                _InfoRow(
                  icon: Icons.straighten_outlined,
                  label: 'Taille originale',
                  value: _formatSize(entry.originalSizeBytes),
                  theme: theme,
                ),
                _InfoRow(
                  icon: Icons.compress_outlined,
                  label: 'Taille résultat',
                  value: _formatSize(entry.resultSizeBytes),
                  theme: theme,
                ),
                if (compression != null)
                  _InfoRow(
                    icon: Icons.trending_down_outlined,
                    label: 'Réduction',
                    value: '$compression%',
                    theme: theme,
                  ),

                const SizedBox(height: AppSpacing.xl),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        onPressed: () => entry.type == HistoryType.pdf
                            ? _share(context)
                            : _saveToGallery(context),
                        label: entry.type == HistoryType.pdf
                            ? 'Partager'
                            : 'Enregistrer',
                        icon: entry.type == HistoryType.pdf
                            ? Icons.share_rounded
                            : Icons.download_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (entry.type != HistoryType.pdf)
                      SizedBox(
                        height: 48,
                        width: 48,
                        child: IconButton.outlined(
                          onPressed: () => _share(context),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSpacing.borderRadiusFull,
                            ),
                          ),
                        ),
                      ),
                    if (entry.type != HistoryType.pdf)
                      const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _delete(context),
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: theme.colorScheme.error,
                          ),
                          label: Text(
                            'Supprimer',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.colorScheme.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSpacing.borderRadiusFull,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveToGallery(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final bytes = await ref.read(historyProvider.notifier).getResultBytes(entry);
    if (bytes == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Fichier introuvable'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await ImageGallerySaverPlus.saveFile(entry.resultPath);
      navigator.pop();
      final msg = entry.type == HistoryType.video
          ? 'Vidéo enregistrée'
          : 'Image enregistrée';
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Échec de l\'enregistrement'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _share(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final file = File(entry.resultPath);
    if (!file.existsSync()) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Fichier introuvable'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await SharePlus.instance.share(ShareParams(files: [XFile(entry.resultPath)]));
  }

  Future<void> _delete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await ref.read(historyProvider.notifier).remove(entry.id);
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Élément supprimé'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(value, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ─── Empty State ───

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Aucun fichier traité',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Vos fichiers récents apparaîtront ici',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
