class WorkoutStatsData {
  final int totalReps;
  final String topExerciseName;
  final Map<String, int> repsPerExercise;
  final Map<DateTime, int> dailyReps;

  WorkoutStatsData({
    required this.totalReps,
    required this.topExerciseName,
    required this.repsPerExercise,
    required this.dailyReps,
  });
}