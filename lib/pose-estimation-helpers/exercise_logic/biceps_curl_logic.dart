import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../calculate_angles.dart';

class BicepCurlTracker {
  int counter = 0;
  String stage = "EXTENDED";

  void reset() {
    counter = 0;
    stage = "EXTENDED";
  }

  String analyze(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];

    if (shoulder == null || elbow == null || wrist == null) {
      return "Asigură-te că brațul stâng este vizibil.";
    }

    double angle = calculareUnghi(shoulder, elbow, wrist);

    if (angle < 45.0 && stage == "EXTENDED") stage = "FLEXED";
    if (angle > 150.0 && stage == "FLEXED") {
      stage = "EXTENDED";
      counter++;
    }

    return "REPETĂRI: $counter\nUnghi cot: ${angle.toStringAsFixed(0)}°";
  }
}