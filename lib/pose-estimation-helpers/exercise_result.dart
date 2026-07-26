class ExerciseResult {
  final String displayValue;
  final String feedback;
  final int currentProgress;

  const ExerciseResult({
    required this.displayValue,
    required this.feedback,
    this.currentProgress = 0,
  });
}