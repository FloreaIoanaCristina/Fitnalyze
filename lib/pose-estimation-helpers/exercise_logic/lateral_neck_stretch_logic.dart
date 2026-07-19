import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_result.dart';
import '../calculate_angles.dart';

class LateralNeckStretchTracker {
  int leftCounter = 0;
  int rightCounter = 0;

  String stage = "CENTER";
  String _lastFeedback = "Stai drept cu fața la cameră și înclină capul spre un umăr.";

  void reset() {
    leftCounter = 0;
    rightCounter = 0;
    stage = "CENTER";
    _lastFeedback = "Stai drept cu fața la cameră și înclină capul spre un umăr.";
  }

  ExerciseResult analyze(Pose pose) {
    final landmarks = pose.landmarks;

    final leftEar = landmarks[PoseLandmarkType.leftEar];
    final rightEar = landmarks[PoseLandmarkType.rightEar];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final nose = landmarks[PoseLandmarkType.nose];

    if (leftEar == null || rightEar == null || leftShoulder == null || rightShoulder == null || nose == null) {
      return const ExerciseResult(
        displayValue: "--",
        feedback: "Stai cu fața la cameră.\nAsigură-te că fața și umerii sunt vizibili.",
      );
    }

    double shoulderDiff = (leftShoulder.y - rightShoulder.y).abs();

    double leftNeckAngle = calculareUnghi(leftEar, nose, leftShoulder);
    double rightNeckAngle = calculareUnghi(rightEar, nose, rightShoulder);

    const double activationThreshold = 45.0;
    const double returnThreshold = 65.0;

    String warning = "";

    if (shoulderDiff > 35) {
      warning = "\n⚠️ Relaxează umerii! Nu îi ridica spre urechi.";
    }

    if (stage == "CENTER") {
      if (leftNeckAngle < activationThreshold) {
        stage = "LEFT";
      } else if (rightNeckAngle < activationThreshold) {
        stage = "RIGHT";
      }
      _lastFeedback = "Menține umerii jos și întinde gâtul...";
    }

    else if (stage == "LEFT") {
      if (leftNeckAngle > returnThreshold) {
        stage = "CENTER";
        leftCounter++;
      }
      _lastFeedback = "Întindere pe Stânga detectată.";
    }

    else if (stage == "RIGHT") {
      if (rightNeckAngle > returnThreshold) {
        stage = "CENTER";
        rightCounter++;
      }
      _lastFeedback = "Întindere pe Dreapta detectată.";
    }

    String totalRepetitions = "S:$leftCounter | D:$rightCounter";

    return ExerciseResult(
      displayValue: totalRepetitions,
      feedback: "Stare gât: ${stage.toUpperCase()}$warning\n$_lastFeedback",
    );
  }
}