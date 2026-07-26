import 'package:isar/isar.dart';

part 'workout_plan.g.dart';

@collection
class WorkoutPlan {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String planId = DateTime.now().millisecondsSinceEpoch.toString();

  late String title;
  int notificationHour = 8;
  int notificationMinute = 0;
  List<int> selectedDays = [];
  List<WorkoutItem> items = [];
  DateTime? createdAt;
}

@embedded
class WorkoutItem {
  String type = "EXERCISE";
  String? exerciseId;
  String? displayTitle;
  int targetReps = 10;
  int targetDurationSeconds = 30;

}