import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_result.dart';
import '../calculate_angles.dart';

class LateralArmRaisesTracker {
  final String targetSide;
  int counter = 0;
  String stage = "DOWN";
  String _lastFeedback = "Ține spatele drept și ridică brațul lateral.";

  LateralArmRaisesTracker({required this.targetSide});

  void reset() {
    counter = 0;
    stage = "DOWN";
    _lastFeedback = "Ține spatele drept și ridică brațul lateral.";
  }

  String get _sideLabel => targetSide == "left" ? "Stâng" : "Drept";

  ExerciseResult analyze(Pose pose) {
    final landmarks = pose.landmarks;

    final hip = targetSide == "left" ? landmarks[PoseLandmarkType.leftHip] : landmarks[PoseLandmarkType.rightHip];
    final shoulder = targetSide == "left" ? landmarks[PoseLandmarkType.leftShoulder] : landmarks[PoseLandmarkType.rightShoulder];
    final elbow = targetSide == "left" ? landmarks[PoseLandmarkType.leftElbow] : landmarks[PoseLandmarkType.rightElbow];
    final wrist = targetSide == "left" ? landmarks[PoseLandmarkType.leftWrist] : landmarks[PoseLandmarkType.rightWrist];

    if (hip == null || shoulder == null || elbow == null || wrist == null) {
      return ExerciseResult(
        displayValue: "--",
        feedback: "Stai cu fața la cameră.\nAsigură-te că brațul $_sideLabel este complet vizibil.",
      );
    }

    double raiseAngle = calculareUnghi(hip, shoulder, wrist);
    double elbowAngle = calculareUnghi(shoulder, elbow, wrist);

    if (raiseAngle > 80.0 && stage == "DOWN") {
      stage = "UP";
      _lastFeedback = "Braț ridicat! Coboară controlat...";
    }

    if (raiseAngle < 25.0 && stage == "UP") {
      stage = "DOWN";
      counter++;
      _lastFeedback = "Repetare corectă!";
    }

    String warning = "";

    if (stage == "UP" && raiseAngle > 110.0) {
      warning = "\n⚠️ Oprește brațul la nivelul umărului (la 90°)!";
    }

    else if (elbowAngle < 150.0 && raiseAngle > 45.0) {
      warning = "\n⚠️ Întinde brațul! Nu folosi doar antebrațul.";
    }

    return ExerciseResult(
      displayValue: "$counter",
      feedback: "Braț $_sideLabel | Stare: ${stage.toUpperCase()}$warning\n$_lastFeedback",
    );
  }
}