import 'package:flutter/material.dart';
import '../screens/camera_screen.dart';
import '../theme/app_colors.dart';

class ExerciseCard extends StatelessWidget {
  final String exerciseId;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool isEnabled;
  final dynamic analyzer;
  final bool requiresLandscape;
  final bool isTimerBased;
  final VoidCallback? onReset;

  const ExerciseCard({
    super.key,
    required this.exerciseId,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.isTimerBased,
    required this.requiresLandscape,
    this.analyzer,
    this.onReset,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Card(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: isEnabled && analyzer != null
            ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraScreen(
                exerciseId: exerciseId,
                exerciseName: title,
                analyzer: analyzer!,
                requiresLandscape: requiresLandscape,
              ),
            ),
          );
          if (onReset != null) {
            onReset!();
          }
        }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: 16.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 40, color: accentColor),
              ),
              const SizedBox(width: 16),
              Flexible(
                fit: FlexFit.loose,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isEnabled)
                const Icon(Icons.arrow_forward_ios, color: AppColors.accent, size: 18)
            ],
          ),
        ),
      ),
    );
  }
}