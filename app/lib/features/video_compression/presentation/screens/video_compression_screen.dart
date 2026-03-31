import 'dart:io';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:video_player/video_player.dart';


enum _ScreenState { initial, processing, result }

class VideoCompressionScreen extends StatefulWidget {
  const VideoCompressionScreen({super.key});

  @override
  State<VideoCompressionScreen> createState() => _VideoCompressionScreenState();
}

class _VideoCompressionScreenState extends State<VideoCompressionScreen> {
  _ScreenState _screenState = _ScreenState.initial;

  // Données de la vidéo sélectionnée et compressée
  XFile? _selectedVideo;
  String? _compressedVideoPath;

  String _selectedQuality =
      'medium'; 
  int _originalSizeInBytes = 0;
  int _compressedSizeInBytes = 0;

  final Dio _dio = Dio();
   
  final String _apiUrl = "http://127.0.0.1:8000/api/compress-video";

  // Réinitialise l'écran pour une nouvelle compression
  void _reset() {
    setState(() {
      _screenState = _ScreenState.initial;
      _selectedVideo = null;
      _compressedVideoPath = null;
      _originalSizeInBytes = 0;
      _compressedSizeInBytes = 0;
    });
  }

  // Utilitaire pour convertir des octets bruts en format lisible  
  String _formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (Math.log(bytes) / Math.log(1024)).floor();
    return ((bytes / Math.pow(1024, i)).toStringAsFixed(decimals)) +
        " " +
        suffixes[i];
  }

  // Utilise ImagePicker pour récupérer une vidéo de la galerie du téléphone
  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final file = File(video.path);
      final size = await file.length();
      setState(() {
        _selectedVideo = video;
        _originalSizeInBytes = size;
      });
    }
  }

  Future<void> _compressAndSave() async {
    if (_selectedVideo == null) return;

    setState(() => _screenState = _ScreenState.processing);

    try {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          _selectedVideo!.path,
          filename: _selectedVideo!.name,
        ),
      });

      final response = await _dio.post(
        _apiUrl,
        data: formData,
        queryParameters: {"quality": _selectedQuality},
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        final Uint8List videoBytes = Uint8List.fromList(response.data);
        _compressedSizeInBytes = videoBytes.length;

        // Création d'un fichier temporaire local pour stocker la réponse binaire
        final tempDir = await Directory.systemTemp.createTemp();
        final tempFile = File('${tempDir.path}/compressed.mp4');
        await tempFile.writeAsBytes(videoBytes);

        // Enregistre définitivement le fichier dans la galerie de l'utilisateur
        final result = await ImageGallerySaverPlus.saveFile(tempFile.path);

        if (mounted && result != null && result['isSuccess'] == true) {
          setState(() {
            // On stocke le chemin local pour permettre au lecteur vidéo de fonctionner
            _compressedVideoPath = tempFile.path;
            _screenState = _ScreenState.result;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur durant la compression : ${e.toString()}"),
          ),
        );
        setState(() => _screenState = _ScreenState.initial);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1565C0),
        actions: [
          if (_screenState == _ScreenState.result)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentStateUI(),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_screenState) {
      case _ScreenState.initial:
        return "Sélectionner une vidéo";
      case _ScreenState.processing:
        return "Compression en cours...";
      case _ScreenState.result:
        return "Résultat de la compression";
    }
  }

  Widget _buildCurrentStateUI() {
    switch (_screenState) {
      case _ScreenState.initial:
        return _buildInitialUI();
      case _ScreenState.processing:
        return _buildProcessingUI();
      case _ScreenState.result:
        return _buildResultUI();
    }
  }

  Widget _buildInitialUI() {
    return SingleChildScrollView(
      key: const ValueKey('initial'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildVideoSelectionCard(),
          if (_selectedVideo != null) ...[
            const SizedBox(height: 24),
            _buildQualitySettingsCard(),
            const SizedBox(height: 32),
            _buildStartCompressionButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoSelectionCard() {
    return _buildMainCard(
      child: Column(
        children: [
          if (_selectedVideo == null)
            const Icon(Icons.video_library, size: 40, color: Color(0xFF1565C0))
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 220,  
                child: _VideoPreview(path: _selectedVideo!.path),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            _selectedVideo == null
                ? "Sélectionner une vidéo"
                : "Vidéo sélectionnée",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_selectedVideo != null)
            Text(
              _selectedVideo!.name,
              style: const TextStyle(color: Colors.grey),
            ),
          if (_selectedVideo != null) Text(_formatBytes(_originalSizeInBytes)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _pickVideo,
            child: Text(
              _selectedVideo == null
                  ? "Parcourir la galerie"
                  : "Changer de vidéo",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualitySettingsCard() {
    return _buildMainCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Paramètres de qualité",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildQualityOptions(),
        ],
      ),
    );
  }

  Widget _buildStartCompressionButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _compressAndSave,
        icon: const Icon(Icons.compress),
        label: const Text(
          "Compresser la vidéo",
          style: TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingUI() {
    return const Center(
      key: ValueKey('Chargement'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text("Compression de la vidéo, veuillez patienter..."),
        ],
      ),
    );
  }

  Widget _buildResultUI() {
    return DefaultTabController(
      length: 2,
      child: Padding(
        key: const ValueKey('result'),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildResultInfoCard(),
            const SizedBox(height: 24),
            const TabBar(
              tabs: [
                Tab(text: "Vidéo compressée"),
                Tab(text: "Vidéo originale"),
              ],
              labelColor: Color(0xFF1565C0),
              unselectedLabelColor: Colors.grey,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildVideoPlayer("Compressée", _compressedVideoPath),
                  _buildVideoPlayer("Originale", _selectedVideo?.path),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _reset,
              child: const Text("Compresser une autre vidéo"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultInfoCard() {
    double savings =
        100 - (_compressedSizeInBytes / _originalSizeInBytes * 100);
    return _buildMainCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _infoColumn("Originale", _formatBytes(_originalSizeInBytes)),
          _infoColumn("Compressée", _formatBytes(_compressedSizeInBytes)),
          _infoColumn("Économie", "${savings.toStringAsFixed(1)}%"),
        ],
      ),
    );
  }

  Widget _infoColumn(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer(String title, String? path) {
    if (path == null) return const Center(child: Text("Fichier introuvable"));
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _VideoPreview(path: path),
      ),
    );
  }

  Widget _buildMainCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildQualityOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _qualityOption("Basse", "low"),
        _qualityOption("Moyenne", "medium"),
        _qualityOption("Haute", "high"),
      ],
    );
  }

  Widget _qualityOption(String label, String qualityValue) {
    bool isSelected = _selectedQuality == qualityValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedQuality = qualityValue);
        }
      },
      selectedColor: const Color(0xFF1565C0),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  final String path;
  const _VideoPreview({required this.path});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      IconButton(
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause_circle
                              : Icons.play_circle,
                          color: Colors.white,
                          size: 50,
                        ),
                        onPressed: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            VideoProgressIndicator(_controller, allowScrubbing: true),
          ],
        );
      },
    );
  }
}