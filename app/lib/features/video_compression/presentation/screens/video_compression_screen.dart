import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/history/history_entry.dart';
import '../../../../core/history/history_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/button.dart';
import '../../domain/video_compression_state.dart';
import '../providers/video_compression_provider.dart';

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

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes o';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
}

// ─── Main Screen ───

class VideoCompressionScreen extends ConsumerWidget {
  const VideoCompressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Compression Vidéo',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: FloatingActionButton(
                      onPressed: () => _openProcessSheet(context, ref),
                      elevation: 0,
                      shape: const CircleBorder(),
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        Icons.add,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: historyAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    const Center(child: Text('Erreur de chargement')),
                data: (entries) {
                  final videoEntries = entries
                      .where((e) => e.type == HistoryType.video)
                      .toList();
                  if (videoEntries.isEmpty) {
                    return _EmptyState(theme: theme);
                  }
                  return _HistoryList(entries: videoEntries);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProcessSheet(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(videoCompressionProvider.notifier);
    notifier.reset();

    await notifier.pickVideo();
    final state = ref.read(videoCompressionProvider);
    if (state.status != VideoCompressionStatus.picked) return;
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ProcessSheet(),
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
      child: Padding(
        padding: AppSpacing.paddingHorizontalXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Aucune vidéo compressée',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Appuyez sur + pour compresser\nune vidéo',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── History List ───

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.entries});
  final List<HistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) => _HistoryTile(entry: entries[index]),
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.entry});
  final HistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final file = File(entry.resultPath);

    return GestureDetector(
      onTap: () => _showDetail(context, ref),
      child: Container(
        padding: AppSpacing.paddingAllSm,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: AppSpacing.borderRadiusMedium,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppSpacing.borderRadiusSmall,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.videocam_rounded,
                    size: 24,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.originalName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _relativeDate(entry.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetailSheet(entry: entry, ref: ref),
    );
  }
}

// ─── Detail Sheet ───

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.entry, required this.ref});
  final HistoryEntry entry;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = File(entry.resultPath);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

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
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                  ),
                ),

                // Preview
                if (file.existsSync())
                  ClipRRect(
                    borderRadius: AppSpacing.borderRadiusLarge,
                    child: _VideoPreview(path: entry.resultPath),
                  )
                else
                  ClipRRect(
                    borderRadius: AppSpacing.borderRadiusLarge,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      color: theme.colorScheme.surfaceContainerLow,
                      child: Center(
                        child: Icon(
                          Icons.videocam_off_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: AppSpacing.lg),

                Text(
                  entry.originalName,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppSpacing.md),

                _DetailRow(
                  label: 'Date',
                  value: dateFormat.format(entry.createdAt),
                  theme: theme,
                ),
                _DetailRow(
                  label: 'Taille originale',
                  value: _formatSize(entry.originalSizeBytes),
                  theme: theme,
                ),
                _DetailRow(
                  label: 'Taille résultat',
                  value: _formatSize(entry.resultSizeBytes),
                  theme: theme,
                ),

                const SizedBox(height: AppSpacing.xl),

                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        onPressed: () => _save(context),
                        label: 'Enregistrer',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        onPressed: () => _delete(context),
                        label: 'Supprimer',
                        variant: AppButtonVariant.outlined,
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

  Future<void> _save(BuildContext context) async {
    try {
      await SharePlus.instance
          .share(ShareParams(files: [XFile(entry.resultPath)]));
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ─── Process Sheet ───

class _ProcessSheet extends ConsumerStatefulWidget {
  const _ProcessSheet();

  @override
  ConsumerState<_ProcessSheet> createState() => _ProcessSheetState();
}

class _ProcessSheetState extends ConsumerState<_ProcessSheet> {
  Future<void> _changeVideo() async {
    final notifier = ref.read(videoCompressionProvider.notifier);
    notifier.reset();
    await notifier.pickVideo();
    final state = ref.read(videoCompressionProvider);
    if (state.status != VideoCompressionStatus.picked && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _startCompress() {
    ref.read(videoCompressionProvider.notifier).compress();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoCompressionProvider);
    final notifier = ref.read(videoCompressionProvider.notifier);
    final theme = Theme.of(context);
    final status = state.status;
    final isCompressing = status == VideoCompressionStatus.compressing;
    final isDone = status == VideoCompressionStatus.done;
    final isError = status == VideoCompressionStatus.error;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Compresser la vidéo',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      if (isDone)
                        _SheetResultContent(state: state, notifier: notifier)
                      else if (isError)
                        _SheetErrorView(
                          message:
                              state.errorMessage ?? 'Une erreur est survenue',
                          onRetry: _startCompress,
                        )
                      else
                        _SheetPickedContent(
                          state: state,
                          notifier: notifier,
                          isCompressing: isCompressing,
                        ),
                    ],
                  ),
                ),
              ),

              // Fixed bottom actions
              _SheetActions(
                status: status,
                isCompressing: isCompressing,
                onCompress: _startCompress,
                onChange: _changeVideo,
                notifier: notifier,
                state: state,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Sheet: Picked Content ───

class _SheetPickedContent extends StatefulWidget {
  const _SheetPickedContent({
    required this.state,
    required this.notifier,
    required this.isCompressing,
  });
  final VideoCompressionState state;
  final VideoCompressionNotifier notifier;
  final bool isCompressing;

  @override
  State<_SheetPickedContent> createState() => _SheetPickedContentState();
}

class _SheetPickedContentState extends State<_SheetPickedContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = Tween<double>(begin: 0.6, end: 0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isCompressing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_SheetPickedContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompressing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isCompressing && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget preview = ClipRRect(
      borderRadius: AppSpacing.borderRadiusLarge,
      child: widget.state.originalFilePath != null
          ? _VideoPreview(path: widget.state.originalFilePath!)
          : Container(
              height: 200,
              color: theme.colorScheme.surfaceContainerLow,
              child: Center(
                child: Icon(
                  Icons.videocam_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
    );

    if (widget.isCompressing) {
      preview = FadeTransition(
        opacity: _opacity,
        child: preview,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        preview,

        const SizedBox(height: AppSpacing.md),

        // File info
        _FileInfoCard(state: widget.state),

        const SizedBox(height: AppSpacing.xl),

        // Quality selector
        Text(
          'QUALITÉ DE COMPRESSION',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _QualitySelector(
          selected: widget.state.quality,
          onChanged: widget.isCompressing
              ? null
              : widget.notifier.setQuality,
        ),
      ],
    );
  }
}

// ─── Sheet: Result Content ───

class _SheetResultContent extends StatefulWidget {
  const _SheetResultContent({required this.state, required this.notifier});
  final VideoCompressionState state;
  final VideoCompressionNotifier notifier;

  @override
  State<_SheetResultContent> createState() => _SheetResultContentState();
}

class _SheetResultContentState extends State<_SheetResultContent> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = _showOriginal
        ? widget.state.originalFilePath
        : widget.state.resultFilePath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusLarge,
          child: path != null
              ? _VideoPreview(
                  key: ValueKey(path),
                  path: path,
                )
              : Container(
                  height: 200,
                  color: theme.colorScheme.surfaceContainerLow,
                ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Toggle
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
              label: 'Compressé',
              selected: !_showOriginal,
              onTap: () => setState(() => _showOriginal = false),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xl),

        // Stats
        _StatsCard(state: widget.state),
      ],
    );
  }
}

// ─── Sheet: Unified Actions ───

class _SheetActions extends StatelessWidget {
  const _SheetActions({
    required this.status,
    required this.isCompressing,
    required this.onCompress,
    required this.onChange,
    required this.notifier,
    required this.state,
  });

  final VideoCompressionStatus status;
  final bool isCompressing;
  final VoidCallback onCompress;
  final VoidCallback onChange;
  final VideoCompressionNotifier notifier;
  final VideoCompressionState state;

  @override
  Widget build(BuildContext context) {
    final isDone = status == VideoCompressionStatus.done;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              onPressed: isDone ? () => _save(context) : onCompress,
              label: isDone ? 'Enregistrer' : 'Compresser',
              isLoading: isCompressing,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppButton(
              onPressed: isDone
                  ? () => _share(context)
                  : isCompressing
                      ? null
                      : onChange,
              label: isDone ? 'Partager' : 'Changer',
              variant: AppButtonVariant.outlined,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final success = await notifier.save();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Vidéo enregistrée' : 'Échec de l\'enregistrement',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (success) navigator.pop();
  }

  Future<void> _share(BuildContext context) async {
    final bytes = state.resultBytes;
    final name = state.originalFileName;
    if (bytes == null || name == null) return;

    try {
      final tmp = await getTemporaryDirectory();
      final baseName = name.contains('.')
          ? name.substring(0, name.lastIndexOf('.'))
          : name;
      final file = File('${tmp.path}/${baseName}_compressed.mp4');
      await file.writeAsBytes(bytes);
      await SharePlus.instance
          .share(ShareParams(files: [XFile(file.path)]));
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

// ─── Sheet: Error ───

class _SheetErrorView extends StatelessWidget {
  const _SheetErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Column(
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
          AppButton(
            onPressed: onRetry,
            label: 'Réessayer',
            expand: false,
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───

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

class _FileInfoCard extends StatelessWidget {
  const _FileInfoCard({required this.state});
  final VideoCompressionState state;

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
          Icon(Icons.videocam_rounded,
              size: 36, color: theme.colorScheme.primary),
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
                  _formatSize(state.originalSizeBytes),
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

class _QualitySelector extends StatelessWidget {
  const _QualitySelector({
    required this.selected,
    required this.onChanged,
  });

  final VideoQuality selected;
  final ValueChanged<VideoQuality>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: VideoQuality.values.map((quality) {
        final isSelected = quality == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right:
                  quality != VideoQuality.values.last ? AppSpacing.xs : 0,
            ),
            child: ChoiceChip(
              label: Center(child: Text(quality.label)),
              selected: isSelected,
              onSelected: onChanged != null ? (_) => onChanged!(quality) : null,
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

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.state});
  final VideoCompressionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduction = state.reductionPercent;
    final gained = reduction > 0;

    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: AppSpacing.borderRadiusMedium,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
                label: 'Avant', value: _formatSize(state.originalSizeBytes)),
          ),
          Container(width: 1, height: 40, color: theme.dividerColor),
          Expanded(
            child: _StatCell(
                label: 'Après', value: _formatSize(state.resultSizeBytes)),
          ),
          Container(width: 1, height: 40, color: theme.dividerColor),
          Expanded(
            child: _StatCell(
              label: 'Réduction',
              value: gained
                  ? '-${reduction.toStringAsFixed(1)}%'
                  : '${reduction.toStringAsFixed(1)}%',
              valueColor: gained
                  ? Colors.green.shade600
                  : theme.colorScheme.onSurface,
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

// ─── Video Preview ───

class _VideoPreview extends StatefulWidget {
  final String path;
  const _VideoPreview({super.key, required this.path});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showPlayButton = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      })
      ..addListener(() {
        if (mounted) {
          final playing = _controller.value.isPlaying;
          if (_showPlayButton == playing) {
            setState(() => _showPlayButton = !playing);
          }
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _showPlayButton = true;
      } else {
        _controller.play();
        _showPlayButton = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: GestureDetector(
            onTap: _togglePlay,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                AnimatedOpacity(
                  opacity: _showPlayButton ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 56,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        VideoProgressIndicator(
          _controller,
          allowScrubbing: true,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
