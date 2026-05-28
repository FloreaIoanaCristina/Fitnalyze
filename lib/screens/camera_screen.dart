import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../pose-estimation-helpers/pose_painter.dart';

typedef ExerciseAnalyzer = String Function(Pose pose);

class CameraScreen extends StatefulWidget {
  final String exerciseName;
  const CameraScreen({super.key, required this.exerciseName});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isProcessing = false;
  String _debugText = "Se inițializează MediaPipe...";
  List<Pose> _detectedPoses = [];

  final Size _targetSize = const Size(480, 640);


  @override
  void initState() {
    super.initState();
    _initializeCameraAndModel();
  }

  Future<void> _initializeCameraAndModel() async {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    );
    _poseDetector = PoseDetector(options: options);

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _debugText = "Nu s-a găsit nicio cameră video.");
      return;
    }
    final frontCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController!.initialize();

      _cameraController!.startImageStream((CameraImage image) {
        if (!_isProcessing) {
          _isProcessing = true;
          _processCameraImage(image);
        }
      });

      setState(() => _debugText = "Caut corpul pentru exercițiu...");
    } catch (e) {
      setState(() => _debugText = "Eroare la pornirea camerei: $e");
    }

    if (mounted) setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_poseDetector == null) {
      _isProcessing = false;
      return;
    }

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      final imageRotation = InputImageRotation.rotation270deg;
      final inputImageFormat = InputImageFormat.nv21;

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
      final poses = await _poseDetector!.processImage(inputImage);

      if (!mounted) return;

      if (poses.isNotEmpty) {
        setState(() {
          _detectedPoses = poses;
          _debugText = "Pozitie detectata";
        });
      } else {
        setState(() {
          _detectedPoses = [];
          _debugText = "Caut corpul... (Asigură-te că te vezi de la brâu în sus)";
        });
      }
    } catch (e) {
      print("Eroare procesare cadru: $e");
    } Shield: {
      await Future.delayed(const Duration(milliseconds: 100));
      _isProcessing = false;
    }
  }

  Future<void> _testeazaCuPozaDinGalerie() async {
    _isProcessing = true;

    setState(() {
      _debugText = "Se deschide galeria... Alege o poză FULL-BODY.";
    });

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);

      if (file == null) {
        setState(() {
          _debugText = "Ai anulat selectarea pozei.";
          _isProcessing = false;
        });
        return;
      }

      final inputImage = InputImage.fromFilePath(file.path);

      setState(() {
        _debugText = "ML Kit analizează poza...";
      });

      final poses = await _poseDetector!.processImage(inputImage);

      setState(() {
        if (poses.isNotEmpty) {
          final puncte = poses.first.landmarks.length;
          _debugText = "SUCCES ML KIT!\nA detectat corpul și a găsit $puncte puncte cheie.";
        } else {
          _debugText = "ML Kit a rulat, dar nu a văzut niciun corp.\nAsigură-te că în poză se văd umerii și șoldurile clare!";
        }
      });
    } catch (e) {
      setState(() {
        _debugText = "Eroare la selectare/procesare: $e";
      });
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _isProcessing = true;
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
    _poseDetector?.close();
    _cameraController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    final size = MediaQuery.of(context).size;

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;

      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
    }

    if (mounted) {
    Navigator.pop(context);
    }
    },
    child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
           SizedBox(
              width: size.width,
              height: size.height,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize!.height,
                  height: _cameraController!.value.previewSize!.width,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),

          if (_detectedPoses.isNotEmpty)
            CustomPaint(
              painter: PosePainter(_detectedPoses, _targetSize),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.black.withOpacity(0.7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Antrenament: ${widget.exerciseName.toUpperCase()}",
                    style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _debugText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _testeazaCuPozaDinGalerie,
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.photo_library, color: Colors.white),
        label: const Text("Test Galerie (Full-Body)", style: TextStyle(color: Colors.white)),
      ),
    )
    );
  }
}