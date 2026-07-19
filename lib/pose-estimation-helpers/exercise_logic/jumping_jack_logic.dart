import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../exercise_result.dart';

class JumpingJackTracker {
  int counter = 0;
  String stage = "CLOSED";

  void reset() {
    counter = 0;
    stage = "CLOSED";
  }

  ExerciseResult analyze(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftShoulder == null || rightShoulder == null ||
        leftWrist == null || rightWrist == null ||
        leftAnkle == null || rightAnkle == null) {
      return const ExerciseResult(
        displayValue: "--",
        feedback: "Poziționează-te cu fața la cameră.\nAparatul trebuie să îți vadă tot corpul.",
      );
    }

    double shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
    double ankleDistance = (leftAnkle.x - rightAnkle.x).abs();

    bool handsAreUp = (leftWrist.y < leftShoulder.y) && (rightWrist.y < rightShoulder.y);
    bool legsAreOpen = ankleDistance > (shoulderWidth * 1.3);

    if (handsAreUp && legsAreOpen && stage == "CLOSED") {
      stage = "OPEN";
    }

    if (!handsAreUp && !legsAreOpen && stage == "OPEN") {
      stage = "CLOSED";
      counter++;
    }

    double expansionRatio = (ankleDistance / shoulderWidth) * 100;

    return ExerciseResult(
      displayValue: "$counter",
      feedback: "Depărtare picioare: ${expansionRatio.toStringAsFixed(0)}% | Stare: $stage",
    );
  }
}