import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart';

import '../pose-estimation-helpers/exercise_result.dart';
import '../pose-estimation-helpers/pose_painter.dart';

typedef ExerciseAnalyzer = ExerciseResult Function(Pose pose);

class CameraScreen extends StatefulWidget {
  final String exerciseName;
  final ExerciseResult Function(Pose) analyzer;
  final bool requiresLandscape;

  const CameraScreen({
    super.key,
    required this.exerciseName,
    required this.analyzer,
    this.requiresLandscape = false,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isProcessing = false;
  List<Pose> _detectedPoses = [];
  String _displayValue = "0";
  String _feedbackText = "Se inițializează camera...";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await SystemChrome.setPreferredOrientations(
      widget.requiresLandscape
          ? [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]
          : [
        DeviceOrientation.portraitUp,
      ],
    );

    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      await _initializeCameraAndModel();
    }
  }

  Future<void> _initializeCameraAndModel() async {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    );
    _poseDetector = PoseDetector(options: options);

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _feedbackText = "Nu s-a găsit nicio cameră video.");
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

      if (mounted) {
        setState(() => _feedbackText = "Caut corpul pentru exercițiu...");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _feedbackText = "Eroare la pornirea camerei: $e");
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_poseDetector == null || !mounted) {
      _isProcessing = false;
      return;
    }

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final InputImageRotation imageRotation = widget.requiresLandscape
          ? InputImageRotation.rotation90deg
          : InputImageRotation.rotation270deg;

      const inputImageFormat = InputImageFormat.nv21;

      final metadata = InputImageMetadata(
        size: Size(
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
      final poses = await _poseDetector!.processImage(inputImage);

      if (!mounted) return;

      if (poses.isNotEmpty) {
        final firstPose = poses.first;
        bool isWholeBodyVisible = _checkBodyVisibility(firstPose);

        if (isWholeBodyVisible) {
          final ExerciseResult rezultatAnaliza = widget.analyzer(firstPose);
          setState(() {
            _detectedPoses = poses;
            _displayValue = rezultatAnaliza.displayValue;
            _feedbackText = rezultatAnaliza.feedback;
          });
        } else {
          setState(() {
            _detectedPoses = poses;
            _displayValue = _displayValue;
            _feedbackText = "CORP INCOMPLET\nAsigură-te că ți se văd umerii, șoldurile și gleznele.";
          });
        }
      } else {
        setState(() {
          _detectedPoses = [];
          _displayValue = _displayValue;
          _feedbackText = "Se caută corpul... Asigură-te că te vezi complet în cadru.";
        });
      }
    } catch (e) {
      print("Eroare procesare cadru: $e");
    } finally {
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

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
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

    Widget uiOverlay = Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: widget.requiresLandscape ? 20 : 0,
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
                const SizedBox(height: 12),
                Text(
                  _displayValue,
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  _feedbackText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          top: 12,
          left: 12,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
              onPressed: () async {
                if (_cameraController != null && _cameraController!.value.isStreamingImages) {
                  await _cameraController!.stopImageStream();
                }
                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
      ],
    );

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
                  width: _cameraController!.value.previewSize!.width,
                  height: _cameraController!.value.previewSize!.height,
                  child: CameraPreview(_cameraController!),
                ),
              )
            ),

            if (_cameraController != null &&
                _cameraController!.value.isInitialized &&
                _detectedPoses.isNotEmpty)
              CustomPaint(
                painter: PosePainter(
                  _detectedPoses,
                  Size(
                    _cameraController!.value.previewSize!.width,
                    _cameraController!.value.previewSize!.height,
                  ),
                  isLandscape: widget.requiresLandscape,
                ),
              ),
            uiOverlay,
          ],
        ),
      ),
    );
  }
}