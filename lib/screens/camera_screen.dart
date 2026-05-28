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
  final ExerciseAnalyzer analyzer;

  const CameraScreen({
    super.key,
    required this.exerciseName,
    required this.analyzer,
  });

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
      const imageRotation = InputImageRotation.rotation270deg;
      const inputImageFormat = InputImageFormat.nv21;

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
        final firstPose = poses.first;

        bool isWholeBodyVisible = _checkBodyVisibility(firstPose);

        if (isWholeBodyVisible) {
          final String rezultatAnaliza = widget.analyzer(firstPose);

          if (mounted) {
            setState(() {
              _detectedPoses = poses;
              _debugText = rezultatAnaliza;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _detectedPoses = [];
            _debugText = "Se cauta corpul... Asigură-te că te vezi complet în cadru.";
          });
        }
      }
    } catch (e) {
      print("Eroare procesare cadru: $e");
    } Shield: {
      await Future.delayed(const Duration(milliseconds: 100));
      _isProcessing = false;
    }
  }
  bool _checkBodyVisibility(Pose pose) {
    const double confidenceThreshold = 0.65;

    final criticalLandmarks = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    for (var type in criticalLandmarks) {
      final landmark = pose.landmarks[type];

      if (landmark == null || landmark.likelihood < confidenceThreshold) {
        return false;
      }
    }

    return true;
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
              padding: const EdgeInsets.only(top: 24, bottom: 24, left: 64, right: 64),
              color: Colors.black.withOpacity(0.7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Exercițiu: ${widget.exerciseName.toUpperCase()}",
                    style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _debugText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 32),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      )
    )
    );
  }
}