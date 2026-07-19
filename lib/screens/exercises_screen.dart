import 'package:fitnalyzer/pose-estimation-helpers/exercise_logic/lunge_logic.dart';
import 'package:flutter/material.dart';
import '../pose-estimation-helpers/exercise_logic/biceps_curl_logic.dart';
import '../pose-estimation-helpers/exercise_logic/jumping_jack_logic.dart';
import '../pose-estimation-helpers/exercise_logic/lateral_arm_raise_logic.dart';
import '../pose-estimation-helpers/exercise_logic/lateral_neck_stretch_logic.dart';
import '../pose-estimation-helpers/exercise_logic/plank_logic.dart';
import '../pose-estimation-helpers/exercise_logic/pushup_logic.dart';
import '../pose-estimation-helpers/exercise_logic/single_arm_shoulder_circles_logic.dart';
import '../pose-estimation-helpers/exercise_logic/squat_logic.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0, top: 20.0),
                child: Text(
                  "Alege un exercițiu modular pentru a începe:",
                  style: TextStyle(fontSize: 18, color: Colors.grey[400], fontWeight: FontWeight.w500),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                 ExerciseCard(
                  title: "Genoflexiuni (Squats)",
                  description: "Antrenament pentru picioare și fesieri. Monitorizare unghi genunchi.",
                  icon: Icons.airline_seat_legroom_normal,
                  accentColor: Colors.blueAccent,
                  analyzer: squatTracker.analyze,
                  onReset: squatTracker.reset,
                  requiresLandscape:  false,
                   isTimerBased: false,
                ),
                const SizedBox(height: 12),
                ExerciseCard(
                  title: "Flexii Biceps - Braț Stâng",
                  description: "Antrenament pentru brațe. Monitorizare unghi cot și fază de contracție.",
                  icon: Icons.fitness_center_outlined,
                  accentColor: Colors.amber,
                  analyzer: leftBicepTracker.analyze,
                  onReset: leftBicepTracker.reset,
                  requiresLandscape:  false,
                  isTimerBased: false,
                ),
                const SizedBox(height: 12),
                ExerciseCard(
                  title: "Flexii Biceps - Braț Drept",
                  description: "Antrenament pentru brațe. Monitorizare unghi cot și fază de contracție.",
                  icon: Icons.fitness_center_outlined,
                  accentColor: Colors.deepOrangeAccent,
                  analyzer: rightBicepTracker.analyze,
                  onReset: rightBicepTracker.reset,
                  requiresLandscape:  false,
                  isTimerBased: false,
                ),
                const SizedBox(height: 12),
                ExerciseCard(
                  title: "Jumping Jacks",
                  description: "Antrenament cardio excelent pentru tot corpul. Monitorizare coordonate mâini și picioare.",
                  icon: Icons.sports_gymnastics,
                  accentColor: Colors.greenAccent,
                  analyzer: jumpingJackTracker.analyze,
                  onReset: jumpingJackTracker.reset,
                  requiresLandscape:  false,
                  isTimerBased: false,
                ),
                const SizedBox(height: 12),
                ExerciseCard(
                  title: "Flotări (Push-ups)",
                  description: "Antrenament pentru piept, umeri și stabilitate core. Monitorizare unghi cot și aliniere spate.",
                  icon: Icons.straighten,
                  accentColor: Colors.redAccent,
                  analyzer: pushUpTracker.analyze,
                  onReset: pushUpTracker.reset,
                  requiresLandscape:  true,
                  isTimerBased: false,
                ),
                const SizedBox(height: 12),
                ExerciseCard(
                  title: "Plank (Scândură)",
                  description: "Exercițiu izometric pentru forța abdominală. Menține spatele drept și bazinul aliniat.",
                  icon: Icons.hourglass_empty,
                  accentColor: Colors.amber,
                  analyzer: plankTracker.analyze,
                  onReset: plankTracker.reset,
                  requiresLandscape: true,
                  isTimerBased: true,
                ),
                const SizedBox(height: 12),
                ExerciseCard(
                  title: "Fandări (Lunges)",
                  description: "Antrenament intens pentru picioare și echilibru",
                  icon: Icons.directions_walk,
                  accentColor: Colors.greenAccent,
                  requiresLandscape: true,
                  analyzer: lungeTracker.analyze,
                  onReset: lungeTracker.reset,
                  isTimerBased: false,
                ),
                const SizedBox(height: 12),
                ExerciseCard(
                  title: "Întinderi Gât",
                  description: "Eliberează tensiunea cervicală",
                  icon: Icons.person,
                  accentColor: Colors.pinkAccent,
                  requiresLandscape: false,
                  analyzer: neckStretchTracker.analyze,
                  onReset: neckStretchTracker.reset,
                  isTimerBased: false,
                ),
                const SizedBox(height: 12),
                ExerciseCard(
                  title: "Rotiri Braț - Stâng",
                  description: "Mobilitate completă pentru umărul stâng",
                  icon: Icons.sync,
                  accentColor: Colors.yellowAccent,
                  requiresLandscape: false,
                  analyzer: leftShoulderCircleTracker.analyze,
                  onReset: leftShoulderCircleTracker.reset,
                  isTimerBased: false,
                ),
                const SizedBox(height: 12),
                ExerciseCard(
                  title: "Rotiri Braț - Drept",
                  description: "Mobilitate completă pentru umărul drept",
                  icon: Icons.sync,
                  accentColor: Colors.purpleAccent,
                  requiresLandscape: false,
                  analyzer: rightShoulderCircleTracker.analyze,
                  onReset: rightShoulderCircleTracker.reset,
                  isTimerBased: false,
                ),
                const SizedBox(height: 12),
                ExerciseCard(
                  title: "Ridicări Laterale - Braț Stâng",
                  description: "Tonifiere și mobilitate pentru deltoidul stâng",
                  icon: Icons.accessibility,
                  accentColor: Colors.lightBlueAccent,
                  requiresLandscape: false,
                  analyzer: leftArmRaiseTracker.analyze,
                  onReset: leftArmRaiseTracker.reset,
                  isTimerBased: false,
                ),
                const SizedBox(height: 12),
                ExerciseCard(
                  title: "Ridicări Laterale - Braț Drept",
                  description: "Tonifiere și mobilitate pentru deltoidul drept",
                  icon: Icons.accessibility,
                  accentColor: Colors.lime,
                  requiresLandscape: false,
                  analyzer: rightArmRaiseTracker.analyze,
                  onReset: rightArmRaiseTracker.reset,
                  isTimerBased: false,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}