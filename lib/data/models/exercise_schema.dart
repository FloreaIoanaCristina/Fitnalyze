import 'package:isar/isar.dart';

part 'exercise_schema.g.dart';

@collection
class ExerciseSchema {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String exerciseId; // ex: "squats", "push_ups", "shoulder_circles_left", "plank"

  late String title;
  late String description;
  late String iconName;
  late int accentColorHex;
  late bool requiresLandscape;
  late bool isTimerBased;

  late String sideStrategy; // "LEFT_ONLY", "RIGHT_ONLY", "DYNAMIC_BEST_SIDE", "BOTH_SIDES"
  late List<String> requiredLandmarks; // ex: ["shoulder", "hip", "knee"] (fără prefix stânga/dreapta dacă e dinamic)
  late String fallbackFeedback; // feedback afișat dacă lipsesc punctele din cadru

  late String trackingType; // "REPETARI_SIMPLE", "REPETARI_SPLIT", "IZOMETRIC_TIMP"
  late List<GeometryConfig> geometries;
  late List<TransitionRule> transitions;
  late List<WarningRule> warnings;
}

@embedded
class GeometryConfig {
  late String id; // ex: "elbow_angle", "dx_wrist", "dy_wrist", "body_alignment", "shoulder_diff", "knee_drift"
  late String type; // "ANGLE", "RELATIVE_X", "RELATIVE_Y", "ABS_DIFF_Y", "MID_POINT_Y_DIST"
  late List<String> inputPoints; // ex: ["shoulder", "elbow", "wrist"] sau ["wrist", "shoulder"] pentru relative
  late bool invertXOnRightSide; // true pentru exerciții ca shoulder circles
}

@embedded
class TransitionRule {
  late String fromState;
  late String toState;

  late String geometryId;
  late String operatorType; // "LESS_THAN", "GREATER_THAN", "BETWEEN"
  late double thresholdMin;
  late double thresholdMax;

  late String? gateGeometryId;
  late String? gateOperatorType;
  late double? gateThreshold;

  late String action; // "INCREMENT", "INCREMENT_LEFT", "INCREMENT_RIGHT", "NONE"
  late String feedback;
}

@embedded
class WarningRule {
  late String geometryId;
  late String operatorType; // "GREATER_THAN", "LESS_THAN", "BETWEEN", "OUTSIDE_INTERVAL"
  late double thresholdMin;
  late double thresholdMax;
  late String activeInState; // "ANY", "UP", "DOWN", "TOP", etc.
  late String warningMessage;
}