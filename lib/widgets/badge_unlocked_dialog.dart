import 'dart:io';
import 'package:flutter/material.dart';
import '../data/models/exercise_badge.dart';
import '../theme/app_colors.dart';
import '../utils/icon_mapper.dart';

class BadgeUnlockedDialog extends StatelessWidget {
  final ExerciseBadge badge;

  const BadgeUnlockedDialog({Key? key, required this.badge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, color: AppColors.warning, size: 60),
            const SizedBox(height: 12),
            const Text(
              "BADGE DEBLOCAT!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Iconița Badge-ului
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.amber.shade100,
              child: Icon(
                IconMapper.getIcon(badge.iconName),
                size: 40,
                color: Colors.amber.shade900,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              badge.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Afișarea capturii de ecran făcute în momentul deblocării
            if (badge.screenshotPath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textPrimary),
                  ),
                  child: Image.file(
                    File(badge.screenshotPath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Excelent!", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}