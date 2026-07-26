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
  List<GeometryConfig> geometries = [];
  List<TransitionRule> transitions = [];
  List<WarningRule> warnings = [];
}

@embedded
class GeometryConfig {
  String id = '';
  String type = '';
  List<String> inputPoints = [];
  bool invertXOnRightSide = false;
}

@embedded
class TransitionRule {
  String fromState = '';
  String toState = '';

  String geometryId = '';
  String operatorType = '';
  double thresholdMin = 0.0;
  double thresholdMax = 0.0;

  // SCOATE 'late' DE AICI - lasă-le opționale simple (nullable):
  String? gateGeometryId;
  String? gateOperatorType;
  double? gateThreshold;

  String action = '';
  String feedback = '';
}

@embedded
class WarningRule {
  String geometryId = '';
  String operatorType = '';
  double thresholdMin = 0.0;
  double thresholdMax = 0.0;
  String activeInState = '';
  String warningMessage = '';
}