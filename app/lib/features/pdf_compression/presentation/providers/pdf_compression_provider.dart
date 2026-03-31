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

  Uint8List? _originalBytes;

  /// Étape 1 : sélection du fichier → état `picked` immédiat, puis chargement aperçu en arrière-plan.
  Future<void> pickFile() async {
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

    // Afficher l'écran de config immédiatement (UX fluide)
    state = state.copyWith(
      status: PdfCompressionStatus.picked,
      originalFileName: name,
      originalSizeBytes: bytes.length,
      originalPageCount: pageCount,
      resultBytes: null,
      resultSizeBytes: 0,
      previewBytes: null,
      alreadyOptimized: false,
    );

    // Charger l'aperçu en arrière-plan
    loadPreview();
  }

  /// Charge l'aperçu de la première page sans bloquer l'UI.
  /// Utilise un cache : ne refait pas l'appel si déjà chargé.
  Future<void> loadPreview() async {
    if (_originalBytes == null || state.previewBytes != null) return;
    final name = state.originalFileName ?? 'document.pdf';
    final preview = await _repository.getPreview(_originalBytes!, name);
    if (mounted) {
      state = state.copyWith(previewBytes: preview);
    }
  }

  /// Étape 2 : lance la compression (action explicite utilisateur).
  Future<void> compress() async {
    if (_originalBytes == null) return;
    state = state.copyWith(status: PdfCompressionStatus.compressing);
    await _runCompression();
  }

  /// Met à jour le niveau sans déclencher de compression.
  void setCompressionLevel(PdfCompressionLevel level) {
    if (level == state.compressionLevel) return;
    state = state.copyWith(compressionLevel: level);
  }

  /// Retourne à l'écran de configuration avec le fichier déjà chargé.
  void backToConfig() {
    state = state.copyWith(
      status: PdfCompressionStatus.picked,
      resultBytes: null,
      resultSizeBytes: 0,
      alreadyOptimized: false,
      errorMessage: null,
    );
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
