import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../calculate_angles.dart';

class SquatTracker {
  int counter = 0;
  String stage = "UP";

  void reset() {
    counter = 0;
    stage = "UP";
  }

  String analyze(Pose pose) {
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (hip == null || knee == null || ankle == null) {
      return "Poziționează-te din profil.\nAparatul nu vede tot piciorul stâng.";
    }

    double angle = calculareUnghi(hip, knee, ankle);

    if (angle < 110.0 && stage == "UP") stage = "DOWN";
    if (angle > 160.0 && stage == "DOWN") {
      stage = "UP";
      counter++;
    }

    return "REPETĂRI: $counter\nUnghi: ${angle.toStringAsFixed(0)}° | Stare: $stage";
  }
}