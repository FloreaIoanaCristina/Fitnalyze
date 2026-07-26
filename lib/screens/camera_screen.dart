import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:screenshot/screenshot.dart';

import '../data/isar_service.dart';
import '../pose-estimation-helpers/exercise_result.dart';
import '../pose-estimation-helpers/pose_painter.dart';
import '../services/badge_service.dart';
import '../theme/app_colors.dart';
import '../widgets/badge_unlocked_dialog.dart';
import '../widgets/floating_feedback.dart';

typedef ExerciseAnalyzer = ExerciseResult Function(Pose pose);

class CameraScreen extends StatefulWidget {
  final String exerciseId;
  final String exerciseName;
  final ExerciseResult Function(Pose) analyzer;
  final bool requiresLandscape;

  final bool isFreeMode;
  final int targetReps;
  final int targetDurationSeconds;
  final VoidCallback? onCompleted;

  const CameraScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    required this.analyzer,
    this.requiresLandscape = false,
    this.isFreeMode = true,
    this.targetReps = 0,
    this.targetDurationSeconds = 0,
    this.onCompleted,
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
  bool _hasCompleted = false;
  Offset _overlayPosition = const Offset(20, 20);

  final ScreenshotController _screenshotController = ScreenshotController();

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
      ResolutionPreset.high,
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

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
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
          ? InputImageRotation.rotation0deg
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

          String formattedDisplay = rezultatAnaliza.displayValue;

          if (!widget.isFreeMode) {
            if (widget.targetReps > 0) {
              // Modul Repetări: ex "3 / 10"
              formattedDisplay = "${rezultatAnaliza.currentProgress} / ${widget.targetReps}";
            } else if (widget.targetDurationSeconds > 0) {
              // Modul Timer: ex "00:15 / 00:30"
              String currentTime = _formatTime(rezultatAnaliza.currentProgress);
              String targetTime = _formatTime(widget.targetDurationSeconds);
              formattedDisplay = "$currentTime / $targetTime";
            }
          }

          setState(() {
            _detectedPoses = poses;
            _displayValue = formattedDisplay;
            _feedbackText = rezultatAnaliza.feedback;
          });

          if (!widget.isFreeMode &&
              widget.onCompleted != null &&
              !_hasCompleted) {
            bool repsAchieved = widget.targetReps > 0 &&
                rezultatAnaliza.currentProgress >= widget.targetReps;

            bool timeAchieved = widget.targetDurationSeconds > 0 &&
                rezultatAnaliza.currentProgress >= widget.targetDurationSeconds;

            if (repsAchieved || timeAchieved) {
              _hasCompleted = true;
              if (_cameraController != null && _cameraController!.value.isStreamingImages) {
                await _cameraController!.stopImageStream();
              }
              await _handleExerciseFinished(rezultatAnaliza);
            }
          }
        } else {
          setState(() {
            _detectedPoses = poses;
            _displayValue = _displayValue;
            _feedbackText =
                "CORP INCOMPLET\nAsigură-te că ți se văd umerii, șoldurile și gleznele.";
          });
        }
      } else {
        setState(() {
          _detectedPoses = [];
          _displayValue = _displayValue;
          _feedbackText =
              "Se caută corpul... Asigură-te că te vezi complet în cadru.";
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

  Future<void> _handleExerciseFinished(ExerciseResult rezultat) async {
    final isTimerBased = widget.targetDurationSeconds > 0;
    final reps = isTimerBased ? 0 : rezultat.currentProgress;
    final duration = isTimerBased ? rezultat.currentProgress : 0;

    await IsarService.instance.logWorkoutSession(
      exerciseId: widget.exerciseName.toLowerCase(),
      completedReps: reps,
      durationSeconds: duration,
    );

    final newBadges = await BadgeService.instance.checkAndAwardBadges(
      exerciseId: widget.exerciseId,
      completedReps: reps,
      durationSeconds: duration,
      isTimerBased: isTimerBased,
      screenshotController: _screenshotController,
    );

    if (mounted && newBadges.isNotEmpty) {
      for (var badge in newBadges) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => BadgeUnlockedDialog(badge: badge),
        );
      }
    }

    if (widget.onCompleted != null) {
      widget.onCompleted!();
    }
  }

  @override
  void dispose() {
    _isProcessing = true;
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
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
          body: SafeArea(
        child:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ));
    }

    final size = MediaQuery.of(context).size;

    final preview = _cameraController!.value.previewSize!;
    final previewWidth =
        widget.requiresLandscape ? preview.width : preview.height;

    final previewHeight =
        widget.requiresLandscape ? preview.height : preview.width;

    Widget uiOverlay = Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: _overlayPosition.dx,
          top: _overlayPosition.dy,
          child: SafeArea(
            child: GestureDetector(
              onPanUpdate: (details) {
                final screen = MediaQuery.of(context).size;

                const cardWidth = 240.0;
                const cardHeight = 170.0; // aprox. înălțimea cardului

                setState(() {
                  final newX = (_overlayPosition.dx + details.delta.dx)
                      .clamp(0.0, screen.width - cardWidth);

                  final newY = (_overlayPosition.dy + details.delta.dy)
                      .clamp(0.0, screen.height - cardHeight);

                  _overlayPosition = Offset(newX, newY);
                });
              },
              child: FloatingFeedback(
                exerciseName: widget.exerciseName,
                displayValue: _displayValue,
                feedback: _feedbackText,
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: AppColors.textPrimary, size: 24),
              onPressed: () async {
                if (_cameraController != null &&
                    _cameraController!.value.isStreamingImages) {
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

    return Screenshot(
        controller: _screenshotController,
        child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              if (_cameraController != null &&
                  _cameraController!.value.isStreamingImages) {
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
                  ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.center,
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: previewWidth,
                          height: previewHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CameraPreview(_cameraController!),
                              if (_detectedPoses.isNotEmpty)
                                CustomPaint(
                                  painter: PosePainter(
                                    _detectedPoses,
                                    Size(previewWidth, previewHeight),
                                    isLandscape: widget.requiresLandscape,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  uiOverlay,
                ],
              ),
            )));
  }
}
