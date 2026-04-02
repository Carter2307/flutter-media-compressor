import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/history/history_entry.dart';
import '../../../../core/history/history_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/button.dart';
import '../../domain/bg_removal_state.dart';
import '../providers/bg_removal_provider.dart';

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
class BackgroundRemovalScreen extends ConsumerWidget {
  const BackgroundRemovalScreen({super.key});

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
                    'Suppression de fond',
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
                  final bgEntries = entries
                      .where((e) => e.type == HistoryType.background)
                      .toList();
                  if (bgEntries.isEmpty) {
                    return _EmptyState(theme: theme);
                  }
                  return _HistoryList(entries: bgEntries);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProcessSheet(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(bgRemovalProvider.notifier);
    notifier.reset();

    final picked = await notifier.pickImage();
    if (picked == null || !context.mounted) return;

    final (bytes, name) = picked;

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProcessSheet(imageBytes: bytes, imageName: name),
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
              Icons.auto_fix_high_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Aucune image traitée',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Appuyez sur + pour supprimer\nl\'arrière-plan d\'une photo',
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
              child: file.existsSync()
                  ? Image.file(file, fit: BoxFit.cover)
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image_outlined,
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
                ClipRRect(
                  borderRadius: AppSpacing.borderRadiusLarge,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 350),
                    color: theme.colorScheme.surfaceContainerLow,
                    child: file.existsSync()
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
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await SharePlus.instance
          .share(ShareParams(files: [XFile(entry.resultPath)]));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Impossible de partager le fichier'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
  const _ProcessSheet({
    required this.imageBytes,
    required this.imageName,
  });

  final Uint8List imageBytes;
  final String imageName;

  @override
  ConsumerState<_ProcessSheet> createState() => _ProcessSheetState();
}

class _ProcessSheetState extends ConsumerState<_ProcessSheet> {
  late Uint8List _currentBytes;
  late String _currentName;

  @override
  void initState() {
    super.initState();
    _currentBytes = widget.imageBytes;
    _currentName = widget.imageName;
  }

  Future<void> _changeImage() async {
    final picked = await ref.read(bgRemovalProvider.notifier).pickImage();
    if (picked == null) return;
    setState(() {
      _currentBytes = picked.$1;
      _currentName = picked.$2;
    });
    ref.read(bgRemovalProvider.notifier).reset();
  }

  void _startProcess() {
    ref.read(bgRemovalProvider.notifier).processImage(
          _currentBytes,
          _currentName,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bgRemovalProvider);
    final notifier = ref.read(bgRemovalProvider.notifier);
    final theme = Theme.of(context);
    final status = state.status;
    final isProcessing = status == BgRemovalStatus.processing;
    final isDone = status == BgRemovalStatus.done;
    final isError = status == BgRemovalStatus.error;

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
                    'Supprimer le fond',
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
                      _SheetResultContent(
                        state: state,
                        notifier: notifier,
                      )
                    else if (isError)
                      _SheetErrorView(
                        message:
                            state.errorMessage ?? 'Une erreur est survenue',
                        onRetry: _startProcess,
                      )
                    else
                      _SheetPickedPreview(
                        imageBytes: _currentBytes,
                        isProcessing: isProcessing,
                      ),
                  ],
                ),
              ),
            ),

            // Fixed bottom actions
            _SheetActions(
              status: status,
              isProcessing: isProcessing,
              onProcess: _startProcess,
              onChange: _changeImage,
              notifier: notifier,
            ),
          ],
        ),
        );
      },
    );
  }
}

// ─── Sheet: Picked Preview ───

class _SheetPickedPreview extends StatefulWidget {
  const _SheetPickedPreview({
    required this.imageBytes,
    this.isProcessing = false,
  });
  final Uint8List imageBytes;
  final bool isProcessing;

  @override
  State<_SheetPickedPreview> createState() => _SheetPickedPreviewState();
}

class _SheetPickedPreviewState extends State<_SheetPickedPreview>
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
    if (widget.isProcessing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_SheetPickedPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isProcessing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isProcessing && _controller.isAnimating) {
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

    Widget image = ClipRRect(
      borderRadius: AppSpacing.borderRadiusLarge,
      child: Container(
        width: double.infinity,
        color: theme.colorScheme.surfaceContainerLow,
        child: Image.memory(
          widget.imageBytes,
          fit: BoxFit.contain,
        ),
      ),
    );

    if (widget.isProcessing) {
      image = FadeTransition(
        opacity: _opacity,
        child: image,
      );
    }

    return image;
  }
}

// ─── Sheet: Unified Actions ───
class _SheetActions extends ConsumerWidget {
  const _SheetActions({
    required this.status,
    required this.isProcessing,
    required this.onProcess,
    required this.onChange,
    required this.notifier,
  });

  final BgRemovalStatus status;
  final bool isProcessing;
  final VoidCallback onProcess;
  final VoidCallback onChange;
  final BgRemovalNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = status == BgRemovalStatus.done;

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
              onPressed: isDone ? () => _save(context) : onProcess,
              label: isDone ? 'Enregistrer' : 'Supprimer le fond',
              isLoading: isProcessing,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppButton(
              onPressed: isDone
                  ? () => _copy(context)
                  : isProcessing
                      ? null
                      : onChange,
              label: isDone ? 'Copier' : 'Changer',
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
    final success = await notifier.saveToGallery();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Image enregistrée' : 'Échec de l\'enregistrement',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (success) navigator.pop();
  }

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await notifier.copyToClipboard();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Image copiée'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    navigator.pop();
  }
}

// ─── Sheet: Result (scrollable content) ───
class _SheetResultContent extends StatefulWidget {
  const _SheetResultContent({required this.state, required this.notifier});
  final BgRemovalState state;
  final BgRemovalNotifier notifier;

  @override
  State<_SheetResultContent> createState() => _SheetResultContentState();
}

class _SheetResultContentState extends State<_SheetResultContent> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bytes = _showOriginal
        ? widget.state.originalImageBytes
        : widget.state.resultImageBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusLarge,
          child: Container(
            color: theme.colorScheme.surfaceContainerLow,
            child: bytes != null
                ? _AdaptiveCheckerboardImage(
                    imageBytes: bytes,
                    showCheckerboard:
                        widget.state.backgroundType ==
                                BackgroundType.transparent &&
                            !_showOriginal,
                    theme: theme,
                  )
                : const AspectRatio(aspectRatio: 3 / 4),
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
              label: 'Résultat',
              selected: !_showOriginal,
              onTap: () => setState(() => _showOriginal = false),
            ),
          ],
        ),

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
          selected: widget.state.backgroundType,
          onChanged: widget.notifier.setBackgroundType,
        ),
      ],
    );
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

class _AdaptiveCheckerboardImageState
    extends State<_AdaptiveCheckerboardImage> {
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
        final isEven =
            ((x / cellSize).floor() + (y / cellSize).floor()) % 2 == 0;
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
        final isEven =
            ((x / cellSize).floor() + (y / cellSize).floor()) % 2 == 0;
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
