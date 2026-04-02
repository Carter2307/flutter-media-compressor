import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/history/history_entry.dart';
import '../../../../core/history/history_provider.dart';
import '../../data/image_compression_repository.dart';
import '../../domain/image_compression_state.dart';

final imageCompressionProvider =
    StateNotifierProvider<ImageCompressionNotifier, ImageCompressionState>(
        (ref) {
  return ImageCompressionNotifier(
    ref.read(imageCompressionRepositoryProvider),
    ref,
  );
});

class ImageCompressionNotifier extends StateNotifier<ImageCompressionState> {
  ImageCompressionNotifier(this._repository, this._ref)
      : super(const ImageCompressionState());

  final ImageCompressionRepository _repository;
  final Ref _ref;

  /// Sélection d'une image depuis la galerie.
  Future<void> pickImage() async {
    final picked = await _repository.pickImage();
    if (picked == null) return;

    state = state.copyWith(
      status: ImageCompressionStatus.picked,
      originalFileName: picked.name,
      originalFilePath: picked.path,
      originalSizeBytes: picked.sizeBytes,
      originalBytes: picked.bytes,
      resultBytes: null,
      resultSizeBytes: 0,
    );
  }

  /// Met à jour la qualité.
  void setQuality(int quality) {
    if (quality == state.quality) return;
    state = state.copyWith(quality: quality);
  }

  /// Lance la compression.
  Future<void> compress() async {
    if (state.originalFilePath == null) return;
    state = state.copyWith(status: ImageCompressionStatus.compressing);

    try {
      final resultBytes = await _repository.compress(
        state.originalFilePath!,
        state.quality,
      );

      state = state.copyWith(
        status: ImageCompressionStatus.done,
        resultBytes: resultBytes,
        resultSizeBytes: resultBytes.length,
        showCompressed: true,
      );

      // Ajout à l'historique
      final name = state.originalFileName;
      if (name != null) {
        await _ref.read(historyProvider.notifier).add(
              originalName: name,
              type: HistoryType.image,
              resultBytes: resultBytes,
              originalSizeBytes: state.originalSizeBytes,
            );
      }
    } catch (e) {
      state = state.copyWith(
        status: ImageCompressionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Toggle entre l'image originale et compressée.
  void togglePreview(bool showCompressed) {
    state = state.copyWith(showCompressed: showCompressed);
  }

  /// Reset complet pour une nouvelle image.
  void reset() {
    state = state.reset();
  }
}
