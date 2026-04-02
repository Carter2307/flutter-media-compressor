import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/history/history_entry.dart';
import '../../../../core/history/history_provider.dart';
import '../../data/bg_removal_repository.dart';
import '../../domain/bg_removal_state.dart';

final bgRemovalProvider =
    StateNotifierProvider<BgRemovalNotifier, BgRemovalState>((ref) {
  return BgRemovalNotifier(
    ref.read(bgRemovalRepositoryProvider),
    ref,
  );
});

class BgRemovalNotifier extends StateNotifier<BgRemovalState> {
  BgRemovalNotifier(this._repository, this._ref) : super(const BgRemovalState());

  final BgRemovalRepository _repository;
  final Ref _ref;
  Uint8List? _transparentResult;

  /// Pick image only, returns the picked data or null if cancelled.
  Future<(Uint8List bytes, String name)?> pickImage() async {
    return _repository.pickImage();
  }

  /// Process an already-picked image.
  Future<void> processImage(Uint8List bytes, String name) async {
    state = state.copyWith(
      status: BgRemovalStatus.processing,
      originalImageBytes: bytes,
      originalFileName: name,
    );

    try {
      final result = await _repository.removeBackground(
        imageBytes: bytes,
        fileName: name,
      );
      _transparentResult = result;

      final displayed = await _repository.applyBackground(
        pngBytes: result,
        bgType: state.backgroundType,
      );

      state = state.copyWith(
        status: BgRemovalStatus.done,
        resultImageBytes: displayed,
      );
    } catch (e) {
      state = state.copyWith(
        status: BgRemovalStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> setBackgroundType(BackgroundType type) async {
    if (type == state.backgroundType) return;
    state = state.copyWith(backgroundType: type);

    if (_transparentResult != null) {
      final displayed = await _repository.applyBackground(
        pngBytes: _transparentResult!,
        bgType: type,
      );
      state = state.copyWith(resultImageBytes: displayed);
    }
  }

  Future<bool> saveToGallery() async {
    final bytes = state.resultImageBytes;
    if (bytes == null) return false;

    final success = await _repository.saveToGallery(bytes);

    if (success) {
      await _ref.read(historyProvider.notifier).add(
            originalName: state.originalFileName ?? 'image',
            type: HistoryType.background,
            resultBytes: bytes,
            originalSizeBytes: state.originalImageBytes?.length ?? 0,
          );
    }

    return success;
  }

  Future<void> copyToClipboard() async {
    final bytes = state.resultImageBytes;
    if (bytes == null) return;
    await Clipboard.setData(ClipboardData(text: ''));
  }

  void reset() {
    _transparentResult = null;
    state = state.reset();
  }
}
