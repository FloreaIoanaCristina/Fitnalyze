import 'dart:io';

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

import '../data/isar_service.dart';
import '../data/models/exercise_badge.dart';
import '../theme/app_colors.dart';
import '../utils/icon_mapper.dart';
import 'screenshot_service.dart';

class BadgeService {
  static final BadgeService instance = BadgeService._();
  BadgeService._();

  Future<List<ExerciseBadge>> checkAndAwardBadges({
    required String exerciseId,
    required int completedReps,
    required int durationSeconds,
    required bool isTimerBased,
    ScreenshotController? screenshotController,
  }) async {
    final unlockedNow = <ExerciseBadge>[];
    final badges = await IsarService.instance.getBadgesForExercise(exerciseId);

    for (var badge in badges) {
      if (badge.isUnlocked) continue;

      bool shouldUnlock = false;

      if (badge.requiredDaysStreak == 0) {
        // --- BADGE-URI INSTANT (O singură sesiune) ---
        if (isTimerBased) {
          if (durationSeconds >= badge.targetValue) {
            shouldUnlock = true;
          }
        } else {
          if (completedReps >= badge.targetValue) {
            shouldUnlock = true;
          }
        }
      } else {
        // --- BADGE-URI DE TIP STREAK (7 Zile Consecutive) ---
        final hasStreak = await _checkStreakForPastDays(
          exerciseId: exerciseId,
          requiredValue: badge.targetValue,
          days: badge.requiredDaysStreak, // 7 zile
          isTimerBased: isTimerBased,
        );
        if (hasStreak) {
          shouldUnlock = true;
        }
      }

      if (shouldUnlock) {
        // 1. Facem captura de ecran
        final path = await ScreenshotService.captureAndSave(badge.badgeId,
          screenshotController,
        );

        // 2. Marcăm ca deblocat
        badge.isUnlocked = true;
        badge.unlockedAt = DateTime.now();
        badge.screenshotPath = path;

        await IsarService.instance.saveBadge(badge);
        unlockedNow.add(badge);
      }
    }

    return unlockedNow;
  }

  Future<bool> _checkStreakForPastDays({
    required String exerciseId,
    required int requiredValue,
    required int days,
    required bool isTimerBased,
  }) async {
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final dayToCheck = now.subtract(Duration(days: i));
      final totalForDay = await IsarService.instance.getTotalStatsForDay(
        exerciseId,
        dayToCheck,
      );

      final val = isTimerBased ? totalForDay.durationSeconds : totalForDay.reps;
      if (val < requiredValue) {
        return false; // O zi a lipsit, streak-ul e întrerupt
      }
    }
    return true;
  }

  static void showBadgeDetailDialog(BuildContext context, ExerciseBadge badge) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
              IconMapper.getIcon(badge.iconName),
              size: 50,
              color: badge.isUnlocked ? AppColors.warning : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (badge.isUnlocked) ...[
              if (badge.unlockedAt != null)
                Text(
                  "Deblocat pe: ${_formatDate(badge.unlockedAt!)}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 12),
              if (badge.screenshotPath != null && File(badge.screenshotPath!).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    width: double.infinity,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                    child: Image.file(File(badge.screenshotPath!), fit: BoxFit.cover),
                  ),
                ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: const Text(
                  "BLOCAT",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Închide')),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year} la ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}