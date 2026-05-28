import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

double calculareUnghi(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
  double radians = math.atan2(p3.y - p2.y, p3.x - p2.x) - math.atan2(p1.y - p2.y, p1.x - p2.x);
  double angle = (radians * 180.0 / math.pi).abs();
  if (angle > 180.0) angle = 360.0 - angle;
  return angle;
}