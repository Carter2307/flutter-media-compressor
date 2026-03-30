import 'dart:typed_data';

enum PdfCompressionStatus { idle, picking, compressing, done, error }

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
  });

  final PdfCompressionStatus status;
  final String? originalFileName;
  final int originalSizeBytes;
  final int originalPageCount;
  final Uint8List? resultBytes;
  final int resultSizeBytes;
  final PdfCompressionLevel compressionLevel;
  final String? errorMessage;

  double get reductionPercent {
    if (originalSizeBytes == 0) return 0;
    return (1 - resultSizeBytes / originalSizeBytes) * 100;
  }

  PdfCompressionState copyWith({
    PdfCompressionStatus? status,
    String? originalFileName,
    int? originalSizeBytes,
    int? originalPageCount,
    Uint8List? resultBytes,
    int? resultSizeBytes,
    PdfCompressionLevel? compressionLevel,
    String? errorMessage,
  }) {
    return PdfCompressionState(
      status: status ?? this.status,
      originalFileName: originalFileName ?? this.originalFileName,
      originalSizeBytes: originalSizeBytes ?? this.originalSizeBytes,
      originalPageCount: originalPageCount ?? this.originalPageCount,
      resultBytes: resultBytes ?? this.resultBytes,
      resultSizeBytes: resultSizeBytes ?? this.resultSizeBytes,
      compressionLevel: compressionLevel ?? this.compressionLevel,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  PdfCompressionState reset() => const PdfCompressionState();
}
