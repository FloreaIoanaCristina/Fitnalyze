import 'package:fitnalyzer/data/isar_service.dart';
import 'package:fitnalyzer/screens/rest_screen.dart';
import 'package:flutter/material.dart';
import '../data/models/exercise_schema.dart';
import '../data/models/workout_plan.dart';
import '../pose-estimation-helpers/exercise_result.dart';
import '../pose-estimation-helpers/generic_exercise_analyzer.dart';
import '../theme/app_colors.dart';
import 'camera_screen.dart';

typedef ExerciseAnalyzer = ExerciseResult Function(dynamic pose);

class WorkoutRunnerScreen extends StatefulWidget {
  final WorkoutPlan plan;

  const WorkoutRunnerScreen({Key? key, required this.plan}) : super(key: key);

  @override
  State<WorkoutRunnerScreen> createState() => _WorkoutRunnerScreenState();
}

class _WorkoutRunnerScreenState extends State<WorkoutRunnerScreen> {
  int _currentItemIndex = 0;

  GenericExerciseAnalyzer? _currentAnalyzer;
  String? _lastExerciseId;

  void _nextStep() {
    final currentItem = widget.plan.items[_currentItemIndex];
    final restDuration = currentItem.targetDurationSeconds ?? 0;

    if (_currentItemIndex < widget.plan.items.length - 1) {
      setState(() {
        _currentItemIndex++;
        _currentAnalyzer = null;
        _lastExerciseId = null;
      });
    } else {
      _showSuccessScreen();
    }
  }

  Future<ExerciseSchema?> _getSchemaFromIsar(String? exerciseId) async {
    if (exerciseId == null) return null;
    return await IsarService.instance.getExerciseById(exerciseId);
  }

  void _showSuccessScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (ctx) =>
            Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                        Icons.emoji_events, size: 100, color: AppColors.warning),
                    const SizedBox(height: 20),
                    const Text("Felicitări!", style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32, fontWeight: FontWeight.bold)),
                    const Text("Ai finalizat antrenamentul cu succes.",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textPrimary,
                          textStyle: const TextStyle(color:AppColors.textPrimary)
                      ),
                      child: const Text("Înapoi la Workout Planner"),
                    )
                  ],
                ),
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.plan.items[_currentItemIndex];

    // 1. Pas de Pauză
    if (currentItem.type == "REST") {
      return RestScreen(
        durationSeconds: currentItem.targetDurationSeconds,
        onRestComplete: _nextStep,
      );
    }

    // 2. Pas de Exercițiu -> Așteptăm încărcarea asincronă a schemei din Isar
    return FutureBuilder<ExerciseSchema?>(
      key: ValueKey("future_${_currentItemIndex}_${currentItem.exerciseId}"),
      future: _getSchemaFromIsar(currentItem.exerciseId),
      builder: (context, snapshot) {
        // Cât timp se citește schema din baza de date
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Dacă nu s-a găsit schema în Isar
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Schema nu a fost găsită pentru: ${currentItem
                      .exerciseId}"),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                        textStyle: const TextStyle(color:AppColors.textPrimary)
                    ),
                    child: const Text("Sari peste exercițiu"),
                  ),
                ],
              ),
            ),
          );
        }

        // Schema a fost găsită cu succes!
        final schema = snapshot.data!;

        // Instanțiem o singură dată analizorul generic pentru exercițiul curent
        if (_currentAnalyzer == null ||
            _lastExerciseId != currentItem.exerciseId) {
          _lastExerciseId = currentItem.exerciseId;
          _currentAnalyzer = GenericExerciseAnalyzer(schema: schema);
        }

        return CameraScreen(
          key: ValueKey(
              "exercise_${_currentItemIndex}_${currentItem.exerciseId}"),
          exerciseId: currentItem.exerciseId!,
          exerciseName: currentItem.displayTitle ?? "Exercițiu",
          analyzer: (pose) => _currentAnalyzer!.analyze(pose),
          targetReps: currentItem.targetReps,
          targetDurationSeconds: currentItem.targetDurationSeconds,
          requiresLandscape: schema.requiresLandscape,
          onCompleted: _nextStep,
          isFreeMode: false,
        );
      },
    );
  }
}
//   void _confirmExit() {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Părăsești antrenamentul?"),
//         content: const Text("Progresul din acest antrenament nu va fi salvat."),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Continuă")),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               Navigator.pop(context);
//             },
//             child: const Text("Ieși", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }
// }