import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../main.dart';

class CameraScreen extends StatefulWidget {
  final String exerciseName;
  const CameraScreen({super.key, required this.exerciseName});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    if (cameras.isEmpty) return;

    CameraDescription frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print("Eroare la pornirea camerei: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameraController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Analiză: ${widget.exerciseName}")),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_cameraController!),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Modul activ: ${widget.exerciseName}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Așază-te în profil complet pentru a începe numărarea genoflexiunilor...",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}