import 'dart:typed_data';

enum BgRemovalStatus { idle, picking, processing, done, error }

enum BackgroundType { transparent, white, black }

class BgRemovalState {
  const BgRemovalState({
    this.status = BgRemovalStatus.idle,
    this.originalImageBytes,
    this.resultImageBytes,
    this.originalFileName,
    this.errorMessage,
    this.backgroundType = BackgroundType.transparent,
  });

  final BgRemovalStatus status;
  final Uint8List? originalImageBytes;
  final Uint8List? resultImageBytes;
  final String? originalFileName;
  final String? errorMessage;
  final BackgroundType backgroundType;

  BgRemovalState copyWith({
    BgRemovalStatus? status,
    Uint8List? originalImageBytes,
    Uint8List? resultImageBytes,
    String? originalFileName,
    String? errorMessage,
    BackgroundType? backgroundType,
  }) {
    return BgRemovalState(
      status: status ?? this.status,
      originalImageBytes: originalImageBytes ?? this.originalImageBytes,
      resultImageBytes: resultImageBytes ?? this.resultImageBytes,
      originalFileName: originalFileName ?? this.originalFileName,
      errorMessage: errorMessage ?? this.errorMessage,
      backgroundType: backgroundType ?? this.backgroundType,
    );
  }

  BgRemovalState reset() => const BgRemovalState();
}
