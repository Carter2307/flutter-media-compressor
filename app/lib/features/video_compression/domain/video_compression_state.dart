import 'dart:typed_data';

enum VideoCompressionStatus { idle, picking, picked, compressing, done, error }

enum VideoQuality {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case VideoQuality.low:
        return 'Basse';
      case VideoQuality.medium:
        return 'Moyenne';
      case VideoQuality.high:
        return 'Haute';
    }
  }

  String get apiValue {
    switch (this) {
      case VideoQuality.low:
        return 'low';
      case VideoQuality.medium:
        return 'medium';
      case VideoQuality.high:
        return 'high';
    }
  }
}

class VideoCompressionState {
  const VideoCompressionState({
    this.status = VideoCompressionStatus.idle,
    this.originalFileName,
    this.originalFilePath,
    this.originalSizeBytes = 0,
    this.resultBytes,
    this.resultFilePath,
    this.resultSizeBytes = 0,
    this.quality = VideoQuality.medium,
    this.showCompressed = true,
    this.errorMessage,
  });

  final VideoCompressionStatus status;
  final String? originalFileName;
  final String? originalFilePath;
  final int originalSizeBytes;
  final Uint8List? resultBytes;
  final String? resultFilePath;
  final int resultSizeBytes;
  final VideoQuality quality;
  final bool showCompressed;
  final String? errorMessage;

  double get reductionPercent {
    if (originalSizeBytes == 0) return 0;
    return (1 - resultSizeBytes / originalSizeBytes) * 100;
  }

  static const _absent = Object();

  VideoCompressionState copyWith({
    VideoCompressionStatus? status,
    String? originalFileName,
    String? originalFilePath,
    int? originalSizeBytes,
    Object? resultBytes = _absent,
    String? resultFilePath,
    int? resultSizeBytes,
    VideoQuality? quality,
    bool? showCompressed,
    String? errorMessage,
  }) {
    return VideoCompressionState(
      status: status ?? this.status,
      originalFileName: originalFileName ?? this.originalFileName,
      originalFilePath: originalFilePath ?? this.originalFilePath,
      originalSizeBytes: originalSizeBytes ?? this.originalSizeBytes,
      resultBytes:
          resultBytes == _absent ? this.resultBytes : resultBytes as Uint8List?,
      resultFilePath: resultFilePath ?? this.resultFilePath,
      resultSizeBytes: resultSizeBytes ?? this.resultSizeBytes,
      quality: quality ?? this.quality,
      showCompressed: showCompressed ?? this.showCompressed,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  VideoCompressionState reset() => const VideoCompressionState();
}
