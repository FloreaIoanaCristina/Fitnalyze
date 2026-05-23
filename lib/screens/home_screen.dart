import 'package:flutter/material.dart';
import '../widgets/exercise_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0, top: 10.0),
                child: Text(
                  "Alege un exercițiu modular pentru a începe:",
                  style: TextStyle(fontSize: 18, color: Colors.grey[400], fontWeight: FontWeight.w500),
                ),
              ),
            ),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisExtent: 140,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildListDelegate([
                const ExerciseCard(
                  title: "Genoflexiuni (Squats)",
                  description: "Antrenament pentru picioare și fesieri. Monitorizare unghi genunchi.",
                  icon: Icons.fitness_center,
                  accentColor: Colors.blueAccent,
                ),
                const ExerciseCard(
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