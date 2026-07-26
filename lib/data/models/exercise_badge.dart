import 'package:isar/isar.dart';

part 'exercise_badge.g.dart';

@collection
class ExerciseBadge {
  Id id = Isar.autoIncrement;

  @Index()
  late String badgeId; // Ex: "squat_10_reps", "plank_30s", "squat_10_reps_7days"

  @Index()
  late String exerciseId; // ID-ul exercițiului de care aparține (ex: "squat", "plank")

  late String title; // Ex: "Master of Squats"
  late String description; // Ex: "Ai executat 10 repetări de Squat"
  late String iconName; // Numele pictogramei sau asset-ului

  bool isUnlocked = false;
  DateTime? unlockedAt;
  String? screenshotPath; // Calea locală către imaginea salvată pe disc

  // Tipul de badge pentru a ști cum îl evaluăm
  // Ex: "TOTAL_REPS", "REPS_STREAK", "TOTAL_DURATION", "DURATION_STREAK"
  late String criteriaType;

  int targetValue = 0; // Ex: 10, 50, 100 repetări SAU 30, 90, 180 secunde
  int requiredDaysStreak = 0; // 0 pentru cele instant, 7 pentru cele de o săptămână
}