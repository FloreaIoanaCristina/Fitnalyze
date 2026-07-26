import 'package:fitnalyzer/screens/settings_screen.dart';
import 'package:fitnalyzer/screens/workout_planner_screen.dart';
import 'package:fitnalyzer/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _userName = 'Atlet';

  final List<Widget> _screens = [
    const HomeScreen(),
    const WorkoutPlannerScreen(),
    ExercisesScreen(),
    const BadgesScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name')?.trim().isNotEmpty == true
          ? prefs.getString('user_name')!
          : 'Atlet';
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        elevation: 2,
      ),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _loadUserName();
        }
      },
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.primary,
              ),
              child:  Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: const AssetImage(
                      'assets/icon/app_icon.png',
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Salut, $_userName!',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Ești gata de antrenament?',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
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
            const Divider(
              color: AppColors.textSecondary,
            ),
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Setări',
              index: 4,
            ),
          ],
        ),
        backgroundColor: AppColors.background,
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
        color: isSelected ? AppColors.background : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.background : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary,
      onTap: () {
        setState(() {
          _currentIndex = index; // Schimbă ecranul central
        });
        Navigator.pop(context); // Închide meniul glisant automat
      },
    );
  }
}