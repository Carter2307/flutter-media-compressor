import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/history/history_entry.dart';
import '../../../../core/history/history_provider.dart';
import '../../data/video_compression_repository.dart';
import '../../domain/video_compression_state.dart';

final videoCompressionProvider =
    StateNotifierProvider<VideoCompressionNotifier, VideoCompressionState>(
        (ref) {
  return VideoCompressionNotifier(
    ref.read(videoCompressionRepositoryProvider),
    ref,
  );
});

class VideoCompressionNotifier extends StateNotifier<VideoCompressionState> {
  VideoCompressionNotifier(this._repository, this._ref)
      : super(const VideoCompressionState());

  final VideoCompressionRepository _repository;
  final Ref _ref;

  /// Étape 1 : sélection de la vidéo.
  Future<void> pickVideo() async {
    state = state.copyWith(status: VideoCompressionStatus.picking);

    final picked = await _repository.pickVideo();
    if (picked == null) {
      state = state.copyWith(status: VideoCompressionStatus.idle);
      return;
    }

    state = state.copyWith(
      status: VideoCompressionStatus.picked,
      originalFileName: picked.name,
      originalFilePath: picked.path,
      originalSizeBytes: picked.sizeBytes,
      resultBytes: null,
      resultSizeBytes: 0,
    );
  }

  /// Met à jour la qualité sans déclencher de compression.
  void setQuality(VideoQuality quality) {
    if (quality == state.quality) return;
    state = state.copyWith(quality: quality);
  }

  /// Étape 2 : lance la compression.
  Future<void> compress() async {
    if (state.originalFilePath == null) return;
    state = state.copyWith(status: VideoCompressionStatus.compressing);

    try {
      final resultBytes = await _repository.compress(
        state.originalFilePath!,
        state.quality,
      );

      // Écrire le résultat dans un fichier temp pour le player vidéo
      final tmp = await getTemporaryDirectory();
      final tempPath =
          '${tmp.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await File(tempPath).writeAsBytes(resultBytes);

      state = state.copyWith(
        status: VideoCompressionStatus.done,
        resultBytes: resultBytes,
        resultFilePath: tempPath,
        resultSizeBytes: resultBytes.length,
        showCompressed: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: VideoCompressionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Enregistre la vidéo et l'ajoute à l'historique.
  Future<bool> save() async {
    final bytes = state.resultBytes;
    final name = state.originalFileName;
    if (bytes == null || name == null) return false;

    try {
      await _repository.saveVideo(bytes, name);

      await _ref.read(historyProvider.notifier).add(
            originalName: name,
            type: HistoryType.video,
            resultBytes: bytes,
            originalSizeBytes: state.originalSizeBytes,
          );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Toggle entre la vidéo originale et compressée.
  void togglePreview(bool showCompressed) {
    state = state.copyWith(showCompressed: showCompressed);
  }

  /// Retour à l'écran de configuration.
  void backToConfig() {
    state = state.copyWith(
      status: VideoCompressionStatus.picked,
      resultBytes: null,
      resultSizeBytes: 0,
      errorMessage: null,
    );
  }

  void reset() {
    state = state.reset();
  }
}
