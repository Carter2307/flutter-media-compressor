import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/video_compression_state.dart';

final videoCompressionRepositoryProvider =
    Provider<VideoCompressionRepository>(
  (ref) => VideoCompressionRepository(ref.read(apiClientProvider)),
);

class VideoCompressionRepository {
  VideoCompressionRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Ouvre le sélecteur de vidéos et retourne (path, name, sizeBytes).
  /// Retourne null si l'utilisateur annule.
  Future<({String path, String name, int sizeBytes})?> pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return null;

    final file = File(video.path);
    final size = await file.length();

    return (path: video.path, name: video.name, sizeBytes: size);
  }

  /// Envoie la vidéo au backend et retourne les bytes compressés.
  Future<Uint8List> compress(String filePath, VideoQuality quality) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _apiClient.dio.post(
      '${ApiEndpoints.baseUrl}${ApiEndpoints.compressVideo}',
      data: formData,
      queryParameters: {'quality': quality.apiValue},
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 2),
      ),
    );

    return Uint8List.fromList(response.data);
  }

  /// Enregistre la vidéo compressée dans le répertoire Documents.
  Future<String> saveVideo(Uint8List bytes, String originalName) async {
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${dir.path}/video_compressed');
    if (!await outputDir.exists()) await outputDir.create(recursive: true);

    final baseName = originalName.contains('.')
        ? originalName.substring(0, originalName.lastIndexOf('.'))
        : originalName;
    final fileName =
        '${baseName}_compressed_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final filePath = '${outputDir.path}/$fileName';

    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }
}
