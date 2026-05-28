import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;

  PosePainter(this.poses, this.absoluteImageSize);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {

    if (oldDelegate is PosePainter) {
      return oldDelegate.poses != poses;
    }
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty) return;

    final paintPoint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill
      ..strokeWidth = 6.0;

    final paintLine = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Calculăm raportul de transformare a coordonatelor de la dimensiunea pozei la dimensiunea ecranului
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    for (final pose in poses) {
      // 1. Desenăm punctele (Landmarks)
      pose.landmarks.forEach((type, landmark) {
        final Offset position = Offset(landmark.x * scaleX, landmark.y * scaleY);
        canvas.drawCircle(position, 5, paintPoint);
      });

      // 2. Desenăm liniile scheletului (Funcție ajutătoare)
      void drawLine(PoseLandmarkType start, PoseLandmarkType end) {
        final startLandmark = pose.landmarks[start];
        final endLandmark = pose.landmarks[end];
        if (startLandmark != null && endLandmark != null) {
          canvas.drawLine(
            Offset(startLandmark.x * scaleX, startLandmark.y * scaleY),
            Offset(endLandmark.x * scaleX, endLandmark.y * scaleY),
            paintLine,
          );
        }
      }

      // Conectăm umerii, brațele și toracele
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

      // Conectăm trunchiul și picioarele
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
      drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
      drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
      drawLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
      drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
      drawLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    }
  }
}