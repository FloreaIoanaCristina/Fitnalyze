import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final bool isLandscape;

  PosePainter(
      this.poses,
      this.absoluteImageSize, {
        this.isLandscape = false,
      });

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses ||
        oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.isLandscape != isLandscape;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty) return;

    final pointPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    Offset mapPoint(PoseLandmark landmark) {
      double x = landmark.x;
      double y = landmark.y;

      if (!isLandscape) {
        return Offset(
          size.width -
              (x * size.width / absoluteImageSize.width),
          y * size.height / absoluteImageSize.height,
        );
      }

      final rotatedX = y;
      final rotatedY = absoluteImageSize.width - x;

      return Offset(
        size.width -
            (rotatedX * size.width / absoluteImageSize.height),
        rotatedY * size.height / absoluteImageSize.width,
      );
    }

    void drawConnection(
        Pose pose,
        PoseLandmarkType start,
        PoseLandmarkType end,
        ) {
      final a = pose.landmarks[start];
      final b = pose.landmarks[end];

      if (a == null || b == null) return;

      canvas.drawLine(
        mapPoint(a),
        mapPoint(b),
        linePaint,
      );
    }

    for (final pose in poses) {
      pose.landmarks.forEach((type, landmark) {
        canvas.drawCircle(
          mapPoint(landmark),
          5,
          pointPaint,
        );
      });

      drawConnection(
          pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);

      drawConnection(
          pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);

      drawConnection(
          pose, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);

      drawConnection(
          pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);

      drawConnection(
          pose, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

      drawConnection(
          pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);

      drawConnection(
          pose, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);

      drawConnection(
          pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);

      drawConnection(
          pose, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);

      drawConnection(
          pose, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);

      drawConnection(
          pose, PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);

      drawConnection(
          pose, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    }
  }
}