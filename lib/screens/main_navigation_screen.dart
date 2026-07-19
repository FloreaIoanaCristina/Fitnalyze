import 'package:fitnalyzer/screens/settings_screen.dart';
import 'package:fitnalyzer/screens/workout_planner_screen.dart';
import 'package:flutter/material.dart';

import 'badges_screen.dart';
import 'exercises_screen.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<String> _titles = [
    'Home & Statistici',
    'Workout Planner',
    'Exerciții',
    'Insigne & Recompense',
    'Setări',
  ];

  final List<Widget> _screens = [
    const HomeScreen(),
    const WorkoutPlannerScreen(),
    ExercisesScreen(),
    const BadgesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        elevation: 2,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: Colors.blue),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Salut, Atlet!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Ești gata de antrenament?',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            _buildDrawerItem(
              icon: Icons.bar_chart,
              title: 'Home & Statistici',
              index: 0,
            ),
            _buildDrawerItem(
              icon: Icons.calendar_month,
              title: 'Workout Planner',
              index: 1,
            ),
            _buildDrawerItem(
              icon: Icons.fitness_center,
              title: 'Exerciții',
              index: 2,
            ),
            _buildDrawerItem(
              icon: Icons.emoji_events,
              title: 'Insigne',
              index: 3,
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Setări',
              index: 4,
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final bool isSelected = _currentIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue.shade700 : Colors.white,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.shade50,
      onTap: () {
        setState(() {
          _currentIndex = index; // Schimbă ecranul central
        });
        Navigator.pop(context); // Închide meniul glisant automat
      },
    );
  }
}