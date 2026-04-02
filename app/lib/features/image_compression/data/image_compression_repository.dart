import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

final imageCompressionRepositoryProvider =
    Provider<ImageCompressionRepository>(
  (ref) => ImageCompressionRepository(ref.read(apiClientProvider)),
);

class ImageCompressionRepository {
  ImageCompressionRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Ouvre le sélecteur d'images et retourne les infos du fichier.
  Future<({String path, String name, int sizeBytes, Uint8List bytes})?> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final file = File(image.path);
    final size = await file.length();
    final bytes = await file.readAsBytes();

    return (path: image.path, name: image.name, sizeBytes: size, bytes: bytes);
  }

  /// Envoie l'image au backend et retourne les bytes compressés.
  Future<Uint8List> compress(String filePath, int quality) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _apiClient.dio.post(
      '${ApiEndpoints.baseUrl}${ApiEndpoints.compress}',
      data: formData,
      queryParameters: {'quality': quality, 'format': 'jpeg'},
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 3),
        sendTimeout: const Duration(minutes: 2),
      ),
    );

    return Uint8List.fromList(response.data);
  }
}
