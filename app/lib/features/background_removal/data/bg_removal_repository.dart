import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/bg_removal_state.dart';

final bgRemovalRepositoryProvider = Provider<BgRemovalRepository>((ref) {
  return BgRemovalRepository(ref.read(apiClientProvider));
});

class BgRemovalRepository {
  BgRemovalRepository(this._apiClient);

  final ApiClient _apiClient;
  final _picker = ImagePicker();

  Future<(Uint8List bytes, String name)?> pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return (bytes, file.name);
  }

  Future<Uint8List> removeBackground({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        imageBytes,
        filename: fileName,
      ),
    });

    final response = await _apiClient.dio.post(
      '${ApiEndpoints.baseUrl}${ApiEndpoints.removeBackground}',
      data: formData,
      queryParameters: {'processor': 'birefnet'},
      options: Options(
        responseType: ResponseType.bytes,
        contentType: 'multipart/form-data',
      ),
    );

    return Uint8List.fromList(response.data as List<int>);
  }

  Future<Uint8List> applyBackground({
    required Uint8List pngBytes,
    required BackgroundType bgType,
  }) async {
    if (bgType == BackgroundType.transparent) return pngBytes;

    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final bgColor = bgType == BackgroundType.white ? Colors.white : Colors.black;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Paint()..color = bgColor,
    );
    canvas.drawImage(image, Offset.zero, Paint());

    final picture = recorder.endRecording();
    final result = await picture.toImage(image.width, image.height);
    final byteData = await result.toByteData(format: ui.ImageByteFormat.png);

    image.dispose();
    result.dispose();

    return byteData!.buffer.asUint8List();
  }

  Future<bool> saveToGallery(Uint8List bytes) async {
    try {
      // Write to temp file first, then save to gallery
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/bg_removed_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      final result = await ImageGallerySaverPlus.saveFile(filePath);
      debugPrint('[saveToGallery] result: $result (${result.runtimeType})');

      // Clean up temp file
      if (await file.exists()) await file.delete();

      if (result is Map) {
        return result['isSuccess'] == true;
      }
      return result != null;
    } catch (e, stack) {
      debugPrint('[saveToGallery] error: $e\n$stack');
      return false;
    }
  }
}
