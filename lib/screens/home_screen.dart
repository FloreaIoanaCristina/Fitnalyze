import 'package:flutter/material.dart';
import '../pose-estimation-helpers/exercise_logic/biceps_curl_logic.dart';
import '../pose-estimation-helpers/exercise_logic/squat_logic.dart';
import '../widgets/exercise_card.dart';

class HomeScreen extends StatelessWidget {
  final squatTracker = SquatTracker();
  final bicepTracker = BicepCurlTracker();

  HomeScreen({super.key});

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
                  icon: Icons.fitness_center,
                  accentColor: Colors.blueAccent,
                  analyzer: squatTracker.analyze,
                  onReset: squatTracker.reset,
                ),
                const SizedBox(height: 12),
                ExerciseCard(
                  title: "Flexii Biceps (Bicep Curls)",
                  description: "Antrenament pentru brațe. Monitorizare unghi cot și fază de contracție.",
                  icon: Icons.fitness_center_outlined,
                  accentColor: Colors.amber,
                  analyzer: bicepTracker.analyze,
                  onReset: bicepTracker.reset,
                ),
                const SizedBox(height: 12),
                 ExerciseCard(
                  title: "Flotări (Push-ups)",
                  description: "În curând. Modul pentru piept, umeri și stabilitatea trunchiului.",
                  icon: Icons.accessibility_new,
                  accentColor: Colors.grey,
                  isEnabled: false,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}