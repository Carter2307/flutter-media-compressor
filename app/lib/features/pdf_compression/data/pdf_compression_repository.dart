import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/pdf_compression_state.dart';

final pdfCompressionRepositoryProvider = Provider<PdfCompressionRepository>(
  (ref) => PdfCompressionRepository(ref.read(apiClientProvider)),
);

class PdfCompressionRepository {
  PdfCompressionRepository(this._apiClient);

  final ApiClient _apiClient;

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

  /// Génère un aperçu JPEG de la première page via le backend.
  /// Retourne null en cas d'erreur (silencieux côté UX, loggué).
  Future<Uint8List?> getPreview(Uint8List bytes, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType('application', 'pdf'),
        ),
      });

      final response = await _apiClient.dio.post(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.pdfPreview}',
        data: formData,
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      final json = response.data as Map<String, dynamic>;
      return base64.decode(json['preview_base64'] as String);
    } catch (e) {
      debugPrint('PDF preview error: $e');
      return null;
    }
  }

  /// Envoie le PDF au backend et retourne le résultat décodé.
  Future<({
    Uint8List pdfBytes,
    bool alreadyOptimized,
    int compressedSize,
  })> compress(
    Uint8List inputBytes,
    String fileName,
    PdfCompressionLevel level,
  ) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        inputBytes,
        filename: fileName,
        contentType: DioMediaType('application', 'pdf'),
      ),
    });

    final response = await _apiClient.dio.post(
      '${ApiEndpoints.baseUrl}${ApiEndpoints.compressPdf}',
      data: formData,
      queryParameters: {'level': level.apiValue},
      options: Options(
        responseType: ResponseType.json,
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(minutes: 2),
        sendTimeout: const Duration(minutes: 2),
      ),
    );

    final json = response.data as Map<String, dynamic>;
    final optimized = json['optimized'] as bool;
    final compressedSize = json['compressed_size'] as int;
    final pdfBytes = base64.decode(json['pdf_base64'] as String);

    return (
      pdfBytes: pdfBytes,
      alreadyOptimized: !optimized,
      compressedSize: compressedSize,
    );
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
}
