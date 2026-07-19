import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../calculate_angles.dart';
import '../exercise_result.dart';

class PushUpTracker {
  int counter = 0;
  String stage = "UP";

  void reset() {
    counter = 0;
    stage = "UP";
  }

  ExerciseResult analyze(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];

    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];

    if (shoulder == null || elbow == null || wrist == null || hip == null || knee == null) {
      return const ExerciseResult(
        displayValue: "--",
        feedback: "Poziționează-te în planșă, din profil.\nAparatul trebuie să îți vadă tot corpul.",
      );
    }

    double elbowAngle = calculareUnghi(shoulder, elbow, wrist);
    double bodyAlignmentAngle = calculareUnghi(shoulder, hip, knee);

    bool isBackStraight = bodyAlignmentAngle > 145.0;

    if (isBackStraight) {
      if (elbowAngle < 95.0 && stage == "UP") {
        stage = "DOWN";
      }
      if (elbowAngle > 150.0 && stage == "DOWN") {
        stage = "UP";
        counter++;
      }
    }

    String postureFeedback = isBackStraight ? "Postură: Corectă (Spate drept)" : "⚠️ Îndreaptă spatele/bazinul!";

    return ExerciseResult(
      displayValue: "$counter",
      feedback: "Unghi cot: ${elbowAngle.toStringAsFixed(0)}° | $postureFeedback",
    );
  }
}