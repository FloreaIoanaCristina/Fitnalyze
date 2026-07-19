import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_result.dart';
import '../calculate_angles.dart';

class SingleArmShoulderCirclesTracker {
  final String targetSide;
  int counter = 0;

  String stage = "START";
  String _lastFeedback = "Începe rotirea brațului spre înainte sau înapoi.";

  SingleArmShoulderCirclesTracker({required this.targetSide});

  void reset() {
    counter = 0;
    stage = "START";
    _lastFeedback = "Începe rotirea brațului spre înainte sau înapoi.";
  }

  String get _sideLabel => targetSide == "left" ? "Stâng" : "Drept";

  ExerciseResult analyze(Pose pose) {
    final landmarks = pose.landmarks;

    final shoulder = targetSide == "left" ? landmarks[PoseLandmarkType.leftShoulder] : landmarks[PoseLandmarkType.rightShoulder];
    final elbow = targetSide == "left" ? landmarks[PoseLandmarkType.leftElbow] : landmarks[PoseLandmarkType.rightElbow];
    final wrist = targetSide == "left" ? landmarks[PoseLandmarkType.leftWrist] : landmarks[PoseLandmarkType.rightWrist];

    if (shoulder == null || elbow == null || wrist == null) {
      return ExerciseResult(
        displayValue: "--",
        feedback: "Stai cu fața la cameră.\nAsigură-te că brațul $_sideLabel este vizibil.",
      );
    }

    double elbowAngle = calculareUnghi(shoulder, elbow, wrist);
    double dy = wrist.y - shoulder.y;
    double dx = wrist.x - shoulder.x;

    if (targetSide == "right") {
      dx = -dx;
    }

    if (stage == "START" && dy > 40) {
    }

    else if (stage == "START" && dy < 20 && dx > 40) {
      stage = "FRONT";
      _lastFeedback = "Brațul trece prin față...";
    }

    else if (stage == "FRONT" && dy < -50) {
      stage = "TOP";
      _lastFeedback = "Excelent! Sus deasupra capului...";
    }

    else if (stage == "TOP" && dy > -20 && dx < -30) {
      stage = "BACK";
      _lastFeedback = "Coboară brațul prin spate...";
    }

    else if (stage == "BACK" && dy > 50) {
      stage = "START";
      counter++;
      _lastFeedback = "Rotire completă reușită!";
    }

    String warning = "";
    if (elbowAngle < 140.0 && stage != "START") {
      warning = "\n⚠️ Întinde brațul! Nu îndoi cotul în timpul rotației.";
    }

    return ExerciseResult(
      displayValue: "$counter",
      feedback: "Braț $_sideLabel | Fază: ${stage.toUpperCase()}$warning\n$_lastFeedback",
    );
  }
}