import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../domain/pdf_compression_state.dart';

final pdfCompressionRepositoryProvider = Provider<PdfCompressionRepository>(
  (_) => PdfCompressionRepository(),
);

class PdfCompressionRepository {
  /// Ouvre le sélecteur de fichiers et retourne (bytes, nom, pages).
  /// Retourne null si l'utilisateur annule.
  Future<(Uint8List bytes, String name, int pageCount)?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;

    final doc = sf.PdfDocument(inputBytes: bytes);
    final pageCount = doc.pages.count;
    doc.dispose();

    return (bytes, file.name, pageCount);
  }

  /// Compresse le PDF en mémoire et retourne les bytes résultants.
  Future<Uint8List> compress(
    Uint8List inputBytes,
    PdfCompressionLevel level,
  ) async {
    final doc = sf.PdfDocument(inputBytes: inputBytes);

    doc.compressionLevel = _toSyncfusionLevel(level);

    if (level == PdfCompressionLevel.aggressive) {
      _removeMetadata(doc);
    }

    final outputBytes = Uint8List.fromList(await doc.save());
    doc.dispose();
    return outputBytes;
  }

  /// Enregistre le PDF dans le répertoire Documents et retourne le chemin.
  Future<String> savePdf(Uint8List bytes, String originalName) async {
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${dir.path}/pdf_compressed');
    if (!await outputDir.exists()) await outputDir.create(recursive: true);

    final baseName = originalName.endsWith('.pdf')
        ? originalName.substring(0, originalName.length - 4)
        : originalName;
    final fileName =
        '${baseName}_compressed_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = '${outputDir.path}/$fileName';

    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  sf.PdfCompressionLevel _toSyncfusionLevel(PdfCompressionLevel level) {
    switch (level) {
      case PdfCompressionLevel.light:
        return sf.PdfCompressionLevel.normal;
      case PdfCompressionLevel.standard:
        return sf.PdfCompressionLevel.best;
      case PdfCompressionLevel.aggressive:
        return sf.PdfCompressionLevel.best;
    }
  }

  void _removeMetadata(sf.PdfDocument doc) {
    doc.documentInformation.author = '';
    doc.documentInformation.creator = '';
    doc.documentInformation.keywords = '';
    doc.documentInformation.producer = '';
    doc.documentInformation.subject = '';
    doc.documentInformation.title = '';
  }
}
