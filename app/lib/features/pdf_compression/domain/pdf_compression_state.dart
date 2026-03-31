import 'dart:typed_data';

enum PdfCompressionStatus { idle, picking, picked, compressing, done, error }

enum PdfCompressionLevel {
  light,
  standard,
  aggressive;

  String get label {
    switch (this) {
      case PdfCompressionLevel.light:
        return 'Léger';
      case PdfCompressionLevel.standard:
        return 'Standard';
      case PdfCompressionLevel.aggressive:
        return 'Agressif';
    }
  }

  String get apiValue {
    switch (this) {
      case PdfCompressionLevel.light:
        return 'light';
      case PdfCompressionLevel.standard:
        return 'standard';
      case PdfCompressionLevel.aggressive:
        return 'aggressive';
    }
  }
}

class PdfCompressionState {
  const PdfCompressionState({
    this.status = PdfCompressionStatus.idle,
    this.originalFileName,
    this.originalSizeBytes = 0,
    this.originalPageCount = 0,
    this.resultBytes,
    this.resultSizeBytes = 0,
    this.compressionLevel = PdfCompressionLevel.standard,
    this.errorMessage,
    this.alreadyOptimized = false,
    this.previewBytes,
  });

  final PdfCompressionStatus status;
  final String? originalFileName;
  final int originalSizeBytes;
  final int originalPageCount;
  final Uint8List? resultBytes;
  final int resultSizeBytes;
  final PdfCompressionLevel compressionLevel;
  final String? errorMessage;
  final bool alreadyOptimized;
  final Uint8List? previewBytes;

  double get reductionPercent {
    if (originalSizeBytes == 0) return 0;
    return (1 - resultSizeBytes / originalSizeBytes) * 100;
  }

  static const _absent = Object();

  PdfCompressionState copyWith({
    PdfCompressionStatus? status,
    String? originalFileName,
    int? originalSizeBytes,
    int? originalPageCount,
    Object? resultBytes = _absent,
    int? resultSizeBytes,
    PdfCompressionLevel? compressionLevel,
    String? errorMessage,
    bool? alreadyOptimized,
    Object? previewBytes = _absent,
  }) {
    return PdfCompressionState(
      status: status ?? this.status,
      originalFileName: originalFileName ?? this.originalFileName,
      originalSizeBytes: originalSizeBytes ?? this.originalSizeBytes,
      originalPageCount: originalPageCount ?? this.originalPageCount,
      resultBytes: resultBytes == _absent ? this.resultBytes : resultBytes as Uint8List?,
      resultSizeBytes: resultSizeBytes ?? this.resultSizeBytes,
      compressionLevel: compressionLevel ?? this.compressionLevel,
      errorMessage: errorMessage ?? this.errorMessage,
      alreadyOptimized: alreadyOptimized ?? this.alreadyOptimized,
      previewBytes: previewBytes == _absent ? this.previewBytes : previewBytes as Uint8List?,
    );
  }

  PdfCompressionState reset() => const PdfCompressionState();
}
