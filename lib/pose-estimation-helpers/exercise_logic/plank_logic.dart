import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../calculate_angles.dart';
import '../exercise_result.dart';

class PlankTracker {
  int _seconds = 0;
  DateTime? _lastCorrectTimestamp;
  String _lastFeedback = "Așază-te în poziție...";

  void reset() {
    _seconds = 0;
    _lastCorrectTimestamp = null;
    _lastFeedback = "Așază-te în poziție...";
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  ExerciseResult analyze(Pose pose) {
    final landmarks = pose.landmarks;
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];

    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];

    if (leftShoulder == null || leftHip == null || leftKnee == null ||
        rightShoulder == null || rightHip == null || rightKnee == null) {
      _lastCorrectTimestamp = null;
      _lastFeedback = "Așază-te complet în cadru...";
      return ExerciseResult(displayValue: _formatTime(_seconds), feedback: _lastFeedback);
    }

    final isLeftVisible = leftHip.likelihood > rightHip.likelihood;
    final shoulder = isLeftVisible ? leftShoulder : rightShoulder;
    final hip = isLeftVisible ? leftHip : rightHip;
    final knee = isLeftVisible ? leftKnee : rightKnee;

    if (shoulder.likelihood < 0.5 || hip.likelihood < 0.5 || knee.likelihood < 0.5) {
      _lastCorrectTimestamp = null;
      _lastFeedback = "Repoziționează-te în cadru!";
      return ExerciseResult(displayValue: _formatTime(_seconds), feedback: _lastFeedback);
    }

    final hipAngle = calculareUnghi(shoulder, hip, knee);

    if (hipAngle >= 160 && hipAngle <= 180) {
      _lastFeedback = "Postură excelentă! Menține...";
      final acum = DateTime.now();
      if (_lastCorrectTimestamp == null) {
        _lastCorrectTimestamp = acum;
      } else {
        final diferenta = acum.difference(_lastCorrectTimestamp!).inSeconds;
        if (diferenta >= 1) {
          _seconds += diferenta;
          _lastCorrectTimestamp = acum;
        }
      }
    } else {
      _lastCorrectTimestamp = null;
      double midY = (shoulder.y + knee.y) / 2;
      if (hip.y < midY - 20) {
        _lastFeedback = "⚠️ Coboară bazinul!";
      } else {
        _lastFeedback = "⚠️ Ridică bazinul! Ține spatele drept!";
      }
    }

    return ExerciseResult(
      displayValue: _formatTime(_seconds),
      feedback: "$_lastFeedback\nUnghi șold: ${hipAngle.toStringAsFixed(0)}°",
    );
  }
}