import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class ImageCompressionScreen extends StatefulWidget {
  const ImageCompressionScreen({super.key});

  @override
  State<ImageCompressionScreen> createState() => _ImageCompressionScreenState();
}

class _ImageCompressionScreenState extends State<ImageCompressionScreen> {
  // VARIABLES D'ÉTAT 
  XFile? _selectedImage;  
  double _quality = 85.0; 
  bool _isCompressing = false;  
  String _originalSize = "0 MB";  
  String _estimatedOutput = "0 KB";  
  int _originalSizeBytes = 0; 

// Equivalent d'axios
  final Dio _dio = Dio(); 

  final String _apiUrl = "http://127.0.0.1:8000/api/compress";

  // Formatage des octets en unités lisibles
  String _formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return ((bytes / math.pow(1024, i)).toStringAsFixed(decimals)) +
        " " +
        suffixes[i];
  }

  // Sélection de l'image via la galerie native
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final file = File(image.path);
      final size = await file.length();
      setState(() {
        _selectedImage = image;
        _originalSizeBytes = size;
        _originalSize = _formatBytes(size);
        _updateEstimation(size);
      });
    }
  }

  // Calcule une estimation visuelle basée sur un ratio de compression 
  void _updateEstimation(int originalSize) {
    double factor = (_quality / 100) * 0.6;
    setState(() {
      _estimatedOutput = _formatBytes((originalSize * factor).toInt());
    });
  }

  // Envoi du fichier à l'API Python et sauvegarde du résultat
  Future<void> _compressAndSave() async {
    if (_selectedImage == null) return;
    setState(() => _isCompressing = true);

    try {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          _selectedImage!.path,
          filename: _selectedImage!.name,
        ),
      });

      
      final response = await _dio.post(
        _apiUrl,
        data: formData,
        queryParameters: {"quality": _quality.toInt(), "format": "jpeg"},
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        // Création d'un fichier temporaire sur le stockage local du téléphone
        final tempDir = await Directory.systemTemp.createTemp();
        final tempFile = File(
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        // Écriture des octets reçus de l'API dans ce fichier
        await tempFile.writeAsBytes(Uint8List.fromList(response.data));

        // Transfert du fichier vers la galerie photo de l'utilisateur
        final result = await ImageGallerySaverPlus.saveFile(
          tempFile.path,
          name: "compressed_${DateTime.now().millisecondsSinceEpoch}",
        );

        await tempFile.delete();

        if (result != null && result['isSuccess'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Image sauvegardée ! (Vérifiez votre galerie)"),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur de connexion à l'API Python")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompressing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            const SizedBox(height: 90),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      "Séléctionner une image",
                      style: AppTypography.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      "Supports : JPG, PNG, WEBP jusqu'à 20MB",
                      style: AppTypography.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text("Accéder à la galerie"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _buildSectionTitle("Taille d'origine"),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      _originalSize,
                      style: AppTypography.textTheme.headlineMedium,
                    ),
                  ),
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: AppColors.surfaceLight,
                    child: _selectedImage == null
                        ? const Icon(
                            Icons.image_outlined,
                            size: 80,
                            color: AppColors.textDisabledLight,
                          )
                        : Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Qualité de la compression",
                          style: AppTypography.textTheme.titleMedium,
                        ),
                        Text(
                          "${_quality.toInt()}%",
                          style: AppTypography.textTheme.headlineSmall
                              ?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                    Slider(
                      value: _quality,
                      min: 10,
                      max: 100,
                      onChanged: (val) {
                        setState(() => _quality = val);
                        if (_originalSizeBytes > 0) {
                          _updateEstimation(_originalSizeBytes);
                        }
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.05),
                        borderRadius: AppSpacing.borderRadiusMedium,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          const Icon(
                            Icons.analytics_outlined,
                            color: AppColors.warning,
                          ),
                          Text(
                            "Sortie estimée",
                            style: AppTypography.textTheme.bodySmall,
                          ),
                          Text(
                            _originalSize,
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: AppColors.textSecondaryLight,
                          ),
                          Text(
                            _estimatedOutput,
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCompressing ? null : _compressAndSave,
                icon: _isCompressing
                    ? const SizedBox.shrink()
                    : const Icon(Icons.auto_fix_high),
                label: _isCompressing
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      )
                    : const Text("Compresser l'image"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondaryLight,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
