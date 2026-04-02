import 'dart:typed_data';

enum ImageCompressionStatus { idle, picked, compressing, done, error }

class ImageCompressionState {
  const ImageCompressionState({
    this.status = ImageCompressionStatus.idle,
    this.originalFileName,
    this.originalFilePath,
    this.originalSizeBytes = 0,
    this.originalBytes,
    this.resultBytes,
    this.resultSizeBytes = 0,
    this.quality = 85,
    this.showCompressed = true,
    this.errorMessage,
  });

  final ImageCompressionStatus status;
  final String? originalFileName;
  final String? originalFilePath;
  final int originalSizeBytes;
  final Uint8List? originalBytes;
  final Uint8List? resultBytes;
  final int resultSizeBytes;
  final int quality;
  final bool showCompressed;
  final String? errorMessage;

  double get reductionPercent {
    if (originalSizeBytes == 0) return 0;
    return (1 - resultSizeBytes / originalSizeBytes) * 100;
  }

  static const _absent = Object();

  ImageCompressionState copyWith({
    ImageCompressionStatus? status,
    String? originalFileName,
    String? originalFilePath,
    int? originalSizeBytes,
    Object? originalBytes = _absent,
    Object? resultBytes = _absent,
    int? resultSizeBytes,
    int? quality,
    bool? showCompressed,
    String? errorMessage,
  }) {
    return ImageCompressionState(
      status: status ?? this.status,
      originalFileName: originalFileName ?? this.originalFileName,
      originalFilePath: originalFilePath ?? this.originalFilePath,
      originalSizeBytes: originalSizeBytes ?? this.originalSizeBytes,
      originalBytes:
          originalBytes == _absent ? this.originalBytes : originalBytes as Uint8List?,
      resultBytes:
          resultBytes == _absent ? this.resultBytes : resultBytes as Uint8List?,
      resultSizeBytes: resultSizeBytes ?? this.resultSizeBytes,
      quality: quality ?? this.quality,
      showCompressed: showCompressed ?? this.showCompressed,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  ImageCompressionState reset() => const ImageCompressionState();
}
