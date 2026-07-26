import 'package:isar/isar.dart';

part 'workout_log.g.dart';

@collection
class WorkoutLog {
  Id id = Isar.autoIncrement;

  @Index()
  late String exerciseId;

  late int completedReps;
  late int durationSeconds;

  @Index()
  late DateTime timestamp;
}