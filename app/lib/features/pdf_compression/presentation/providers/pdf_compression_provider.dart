import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/history/history_entry.dart';
import '../../../../core/history/history_provider.dart';
import '../../data/pdf_compression_repository.dart';
import '../../domain/pdf_compression_state.dart';

final pdfCompressionProvider =
    StateNotifierProvider<PdfCompressionNotifier, PdfCompressionState>((ref) {
  return PdfCompressionNotifier(
    ref.read(pdfCompressionRepositoryProvider),
    ref,
  );
});

class PdfCompressionNotifier extends StateNotifier<PdfCompressionState> {
  PdfCompressionNotifier(this._repository, this._ref)
      : super(const PdfCompressionState());

  final PdfCompressionRepository _repository;
  final Ref _ref;

  static const int _maxFileSizeBytes = 100 * 1024 * 1024; // 100 Mo

  /// Bytes originaux conservés pour re-compresser lors du changement de niveau.
  Uint8List? _originalBytes;

  Future<void> pickAndCompress() async {
    state = state.copyWith(status: PdfCompressionStatus.picking);

    final picked = await _repository.pickPdf();
    if (picked == null) {
      state = state.copyWith(status: PdfCompressionStatus.idle);
      return;
    }

    final (bytes, name, pageCount) = picked;

    if (bytes.length > _maxFileSizeBytes) {
      state = state.copyWith(
        status: PdfCompressionStatus.error,
        errorMessage: 'Le fichier dépasse la limite de 100 Mo autorisée.',
      );
      return;
    }

    _originalBytes = bytes;

    state = state.copyWith(
      status: PdfCompressionStatus.compressing,
      originalFileName: name,
      originalSizeBytes: bytes.length,
      originalPageCount: pageCount,
    );

    await _runCompression();
  }

  Future<void> setCompressionLevel(PdfCompressionLevel level) async {
    if (level == state.compressionLevel) return;
    if (_originalBytes == null) return;

    state = state.copyWith(
      compressionLevel: level,
      status: PdfCompressionStatus.compressing,
    );

    await _runCompression();
  }

  Future<bool> save() async {
    final bytes = state.resultBytes;
    final name = state.originalFileName;
    if (bytes == null || name == null) return false;

    try {
      await _repository.savePdf(bytes, name);

      await _ref.read(historyProvider.notifier).add(
            originalName: name,
            type: HistoryType.pdf,
            resultBytes: bytes,
            originalSizeBytes: state.originalSizeBytes,
          );

      return true;
    } catch (_) {
      return false;
    }
  }

  void reset() {
    _originalBytes = null;
    state = state.reset();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _runCompression() async {
    try {
      final result = await _repository.compress(
        _originalBytes!,
        state.originalFileName ?? 'document.pdf',
        state.compressionLevel,
      );

      state = state.copyWith(
        status: PdfCompressionStatus.done,
        resultBytes: result.pdfBytes,
        resultSizeBytes: result.compressedSize,
        previewBytes: result.previewBytes,
        alreadyOptimized: result.alreadyOptimized,
      );
    } catch (e) {
      state = state.copyWith(
        status: PdfCompressionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
