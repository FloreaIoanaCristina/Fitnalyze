import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../calculate_angles.dart';
import '../exercise_result.dart';

class LungeTracker {
  int counter = 0;
  String stage = "UP";
  String _lastFeedback = "Pășește înainte și coboară în fandare.";

  void reset() {
    counter = 0;
    stage = "UP";
    _lastFeedback = "Pășește înainte și coboară în fandare.";
  }

  ExerciseResult analyze(Pose pose) {
    final landmarks = pose.landmarks;
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    bool leftValid = leftHip != null && leftKnee != null && leftAnkle != null;
    bool rightValid = rightHip != null && rightKnee != null && rightAnkle != null;

    if (!leftValid && !rightValid) {
      return const ExerciseResult(
        displayValue: "--",
        feedback: "Poziționează-te din profil.\nAparatul trebuie să îți vadă șoldul, genunchiul și glezna.",
      );
    }

    bool useLeft = true;
    if (leftValid && rightValid) {
      useLeft = leftKnee!.likelihood > rightKnee!.likelihood;
    } else {
      useLeft = leftValid;
    }

    final hip = useLeft ? leftHip! : rightHip!;
    final knee = useLeft ? leftKnee! : rightKnee!;
    final ankle = useLeft ? leftAnkle! : rightAnkle!;

    double kneeAngle = calculareUnghi(hip, knee, ankle);

    if (kneeAngle < 100.0 && stage == "UP") {
      stage = "DOWN";
    }
    if (kneeAngle > 160.0 && stage == "DOWN") {
      stage = "UP";
      counter++;
    }

    String warning = "";
    if (stage == "DOWN") {
      double horizontalDrift = (knee.x - ankle.x).abs();
      if (horizontalDrift > 45) {
        warning = "\n⚠️ Nu duce genunchiul în fața degetelor!";
      }
    }

    _lastFeedback = isBackStraightText(landmarks, useLeft)
        ? "Formă bună! Menține spatele drept."
        : "⚠️ Încearcă să ții trunchiul mai vertical.";

    return ExerciseResult(
      displayValue: "$counter",
      feedback: "Stare: ${stage.toUpperCase()} | Genunchi: ${kneeAngle.toStringAsFixed(0)}°$warning\n$_lastFeedback",
    );
  }

  bool isBackStraightText(Map<PoseLandmarkType, PoseLandmark> landmarks, bool leftSide) {
    final shoulder = landmarks[leftSide ? PoseLandmarkType.leftShoulder : PoseLandmarkType.rightShoulder];
    final hip = landmarks[leftSide ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    final knee = landmarks[leftSide ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee];

    if (shoulder != null && hip != null && knee != null) {
      double torsoAngle = calculareUnghi(shoulder, hip, knee);
      return torsoAngle > 140.0;
    }
    return true;
  }
}