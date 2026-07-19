import 'package:flutter/material.dart';
import '../screens/camera_screen.dart';

class ExerciseCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool isEnabled;
  final ExerciseAnalyzer? analyzer;
  final bool requiresLandscape;
  final bool isTimerBased;
  final VoidCallback? onReset;

  ExerciseCard({
    super.key,
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
      color: const Color(0xFF1E1E1E),
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
                        color: isEnabled ? Colors.white : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isEnabled)
                const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent, size: 18)
            ],
          ),
        ),
      ),
    );
  }
}