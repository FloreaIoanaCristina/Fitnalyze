import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../data/models/exercise_schema.dart';
import 'calculate_angles.dart';
import 'exercise_result.dart';

class GenericExerciseAnalyzer {
  final ExerciseSchema schema;

  int counter = 0;
  int leftCounter = 0;
  int rightCounter = 0;
  int seconds = 0;
  String currentState = "START";
  String lastFeedback = "Pregătește-te...";
  DateTime? lastCorrectTimestamp;

  GenericExerciseAnalyzer({required this.schema}) {
    reset();
  }

  void reset() {
    counter = 0;
    leftCounter = 0;
    rightCounter = 0;
    seconds = 0;
    currentState = schema.transitions.isNotEmpty ? schema.transitions.first.fromState : "START";
    lastFeedback = "Așază-te în poziție...";
    lastCorrectTimestamp = null;
  }

  ExerciseResult analyze(Pose pose) {
    String activeSide = "left";
    if (schema.sideStrategy == "RIGHT_ONLY") activeSide = "right";
    if (schema.sideStrategy == "DYNAMIC_BEST_SIDE") {
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
      if (leftHip != null && rightHip != null) {
        activeSide = leftHip.likelihood > rightHip.likelihood ? "left" : "right";
      }
    }

    for (var pName in schema.requiredLandmarks) {
      final resolvedType = _resolveLandmarkType(pName, activeSide);
      final landmark = pose.landmarks[resolvedType];
      if (landmark == null || landmark.likelihood < 0.5) {
        lastCorrectTimestamp = null;
        return ExerciseResult(
          displayValue: schema.isTimerBased ? _formatTime(seconds) : "--",
          feedback: schema.fallbackFeedback,
          currentProgress: schema.isTimerBased ? seconds : counter,
        );
      }
    }

    Map<String, double> computedValues = {};
    for (var geo in schema.geometries) {
      computedValues[geo.id] = _executeGeometry(geo, pose, activeSide);
    }

    String warningText = "";
    for (var warn in schema.warnings) {
      if (warn.activeInState == "ANY" || warn.activeInState == currentState) {
        double val = computedValues[warn.geometryId] ?? 0.0;
        bool trigger = false;
        if (warn.operatorType == "GREATER_THAN" && val > warn.thresholdMin) trigger = true;
        if (warn.operatorType == "LESS_THAN" && val < warn.thresholdMin) trigger = true;
        if (warn.operatorType == "OUTSIDE_INTERVAL" && (val < warn.thresholdMin || val > warn.thresholdMax)) trigger = true;

        if (trigger) {
          warningText += "\n${warn.warningMessage}";
        }
      }
    }

    if (schema.trackingType == "IZOMETRIC_TIMP") {
      if (warningText.isEmpty) {
        lastFeedback = "Postură excelentă! Menține...";
        final acum = DateTime.now();
        if (lastCorrectTimestamp == null) {
          lastCorrectTimestamp = acum;
        } else {
          final dif = acum.difference(lastCorrectTimestamp!).inSeconds;
          if (dif >= 1) {
            seconds += dif;
            lastCorrectTimestamp = acum;
          }
        }
      } else {
        lastCorrectTimestamp = null;
        lastFeedback = warningText.trim();
        warningText = "";
      }
    } else {
      for (var trans in schema.transitions) {
        if (trans.fromState == currentState) {
          double metric = computedValues[trans.geometryId] ?? 0.0;

          bool mainCondition = false;
          if (trans.operatorType == "LESS_THAN" && metric < trans.thresholdMin) mainCondition = true;
          if (trans.operatorType == "GREATER_THAN" && metric > trans.thresholdMin) mainCondition = true;
          if (trans.operatorType == "BETWEEN" && metric >= trans.thresholdMin && metric <= trans.thresholdMax) mainCondition = true;

          bool gatePassed = true;
          if (trans.gateGeometryId != null) {
            double gateMetric = computedValues[trans.gateGeometryId] ?? 0.0;
            if (trans.gateOperatorType == "GREATER_THAN" && gateMetric <= trans.gateThreshold!) gatePassed = false;
            if (trans.gateOperatorType == "LESS_THAN" && gateMetric >= trans.gateThreshold!) gatePassed = false;
          }

          if (mainCondition && gatePassed) {
            currentState = trans.toState;
            lastFeedback = trans.feedback;

            if (trans.action == "INCREMENT") counter++;
            if (trans.action == "INCREMENT_LEFT") leftCounter++;
            if (trans.action == "INCREMENT_RIGHT") rightCounter++;
            break;
          }
        }
      }
    }

    String displayValue = "${counter}";
    if (schema.trackingType == "IZOMETRIC_TIMP") {
      displayValue = _formatTime(seconds);
    } else if (schema.trackingType == "REPETARI_SPLIT") {
      displayValue = "S:$leftCounter | D:$rightCounter";
    }

    String infoLive = "";
    if (schema.geometries.isNotEmpty) {
      final primaGeo = schema.geometries.first;
      infoLive = "${primaGeo.id.replaceAll('_', ' ')}: ${(computedValues[primaGeo.id] ?? 0.0).toStringAsFixed(0)}° | ";
    }

    String feedbackFinal = "Stare: ${currentState.toUpperCase()} | $infoLive$lastFeedback$warningText";
    if (schema.trackingType == "IZOMETRIC_TIMP") {
      feedbackFinal = "$lastFeedback $warningText".trim();
    }

    int progressValue = counter;
    if (schema.trackingType == "IZOMETRIC_TIMP") {
      progressValue = seconds;
    } else if (schema.trackingType == "REPETARI_SPLIT") {
      progressValue = leftCounter + rightCounter;
    }

    return ExerciseResult(displayValue: displayValue, feedback: feedbackFinal,currentProgress: progressValue);
  }

  double _executeGeometry(GeometryConfig geo, Pose pose, String activeSide) {
    final pts = geo.inputPoints
        .map((p) => pose.landmarks[_resolveLandmarkType(p, activeSide)])
        .whereType<PoseLandmark>()
        .toList();

    if (pts.length < geo.inputPoints.length) return 0.0;

    switch (geo.type) {
      case "ANGLE":
        return calculareUnghi(pts[0], pts[1], pts[2]);

      case "DISTANCE_RATIO":
        if (pts.length < 4) return 0.0;
        double distPicioare = sqrt(pow(pts[0].x - pts[1].x, 2) + pow(pts[0].y - pts[1].y, 2));
        double distUmeri = sqrt(pow(pts[2].x - pts[3].x, 2) + pow(pts[2].y - pts[3].y, 2));
        if (distUmeri == 0) return 0.0;
        return distPicioare / distUmeri;

      case "VERTICAL_DISTANCE":
        if (pts.length < 2) return 0.0;
        return pts[0].y - pts[1].y;

      case "RELATIVE_X":
        double dx = pts[0].x - pts[1].x;
        if (geo.invertXOnRightSide && activeSide == "right") dx = -dx;
        return dx;

      case "RELATIVE_Y":
        return pts[0].y - pts[1].y;

      case "ABS_DIFF_Y":
        return (pts[0].y - pts[1].y).abs();

      case "MID_POINT_Y_DIST":
        double midY = (pts[0].y + pts[2].y) / 2;
        return pts[1].y - midY;

      default:
        return 0.0;
    }
  }

  PoseLandmarkType _resolveLandmarkType(String name, String side) {
    String prefix = "";
    if (name.startsWith("left") || name.startsWith("right") || name == "nose") {
      prefix = "";
    } else {
      prefix = side;
    }

    String finalName = prefix.isEmpty ? name : "$prefix${name.substring(0, 1).toUpperCase()}${name.substring(1)}";

    return PoseLandmarkType.values.firstWhere(
          (e) => e.toString().split('.').last == finalName,
      orElse: () => PoseLandmarkType.nose,
    );
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
}