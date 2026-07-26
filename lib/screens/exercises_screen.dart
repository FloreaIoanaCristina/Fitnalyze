import 'package:fitnalyzer/pose-estimation-helpers/exercise_logic/lunge_logic.dart';
import 'package:fitnalyzer/utils/icon_mapper.dart';
import 'package:flutter/material.dart';
import '../data/isar_service.dart';
import '../data/models/exercise_schema.dart';
import '../pose-estimation-helpers/exercise_logic/biceps_curl_logic.dart';
import '../pose-estimation-helpers/exercise_logic/jumping_jack_logic.dart';
import '../pose-estimation-helpers/exercise_logic/lateral_arm_raise_logic.dart';
import '../pose-estimation-helpers/exercise_logic/lateral_neck_stretch_logic.dart';
import '../pose-estimation-helpers/exercise_logic/plank_logic.dart';
import '../pose-estimation-helpers/exercise_logic/pushup_logic.dart';
import '../pose-estimation-helpers/exercise_logic/single_arm_shoulder_circles_logic.dart';
import '../pose-estimation-helpers/exercise_logic/squat_logic.dart';
import '../pose-estimation-helpers/generic_exercise_analyzer.dart';
import '../theme/app_colors.dart';
import '../widgets/exercise_card.dart';

class ExercisesScreen extends StatelessWidget {
  final squatTracker = SquatTracker();
  final leftBicepTracker = BicepsCurlsTracker(targetSide: "left");
  final rightBicepTracker = BicepsCurlsTracker(targetSide: "right");
  final jumpingJackTracker = JumpingJackTracker();
  final pushUpTracker = PushUpTracker();
  final plankTracker = PlankTracker();
  final lungeTracker = LungeTracker();
  final neckStretchTracker = LateralNeckStretchTracker();
  final leftShoulderCircleTracker = SingleArmShoulderCirclesTracker(targetSide: "left");
  final rightShoulderCircleTracker = SingleArmShoulderCirclesTracker(targetSide: "right");
  final leftArmRaiseTracker = LateralArmRaisesTracker(targetSide: "left");
  final rightArmRaiseTracker = LateralArmRaisesTracker(targetSide: "right");

  ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<List<ExerciseSchema>>(
            future: IsarService.instance.getAllExercises(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Eroare la încărcarea datelor: ${snapshot.error}",
                    style: const TextStyle(color: AppColors.error),
                  ),
                );
              }

              final exercises = snapshot.data ?? [];

              if (exercises.isEmpty) {
                return const Center(
                  child: Text(
                    "Nu s-au găsit exerciții în baza de date.",
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 8),
                      child: Text(
                        "Alege un exercițiu modular pentru a începe:",
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final exercise = exercises[index];

                        // 1. Preluăm analyzer-ul generic populat direct cu schema din baza de date
                        final dynamicAnalyzer = GenericExerciseAnalyzer(schema: exercise);

                        // 2. Convertim culoarea hex (int) din Isar în obiect Color
                        final Color cardColor = Color(exercise.accentColorHex);

                        // 3. Convertim numele iconiței (String) din Isar în IconData
                        final IconData cardIcon = IconMapper.getIcon(exercise.iconName);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ExerciseCard(
                            exerciseId: exercise.exerciseId,
                            // Toate proprietățile UI vin direct din obiectul salvat în Isar
                            title: exercise.title, // Folosește câmpul .title din schema ta
                            description: exercise.description,
                            icon: cardIcon,
                            accentColor: cardColor,
                            requiresLandscape: exercise.requiresLandscape,
                            isTimerBased: exercise.isTimerBased,

                            // Injectăm metodele analyzer-ului generic care rulează pe această schemă
                            analyzer: dynamicAnalyzer.analyze,
                            onReset: dynamicAnalyzer.reset,
                          ),
                        );
                      },
                      childCount: exercises.length,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}