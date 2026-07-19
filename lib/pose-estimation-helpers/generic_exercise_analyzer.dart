import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../data/models/exercise_schema.dart';


class ExerciseResult {
  final String displayValue;
  final String feedback;
  const ExerciseResult({required this.displayValue, required this.feedback});
}

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

    return ExerciseResult(displayValue: displayValue, feedback: feedbackFinal);
  }

  double _executeGeometry(GeometryConfig geo, Pose pose, String activeSide) {
    final pts = geo.inputPoints.map((p) => pose.landmarks[_resolveLandmarkType(p, activeSide)]!).toList();

    switch (geo.type) {
      case "ANGLE":
        if (pts.length < 3) return 0.0;
        return _calculareUnghi(pts[0], pts[1], pts[2]);

      case "RELATIVE_X":
        if (pts.length < 2) return 0.0;
        double dx = pts[0].x - pts[1].x;
        if (geo.invertXOnRightSide && activeSide == "right") dx = -dx;
        return dx;

      case "RELATIVE_Y":
        if (pts.length < 2) return 0.0;
        return pts[0].y - pts[1].y;

      case "ABS_DIFF_Y":
        if (pts.length < 2) return 0.0;
        return (pts[0].y - pts[1].y).abs();

      case "MID_POINT_Y_DIST":
        if (pts.length < 3) return 0.0;
        double midY = (pts[0].y + pts[2].y) / 2;
        return pts[1].y - midY;

      default:
        return 0.0;
    }
  }

  double _calculareUnghi(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
    double radians = atan2(p3.y - p2.y, p3.x - p2.x) - atan2(p1.y - p2.y, p1.x - p2.x);
    double angle = (radians * 180.0 / pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
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