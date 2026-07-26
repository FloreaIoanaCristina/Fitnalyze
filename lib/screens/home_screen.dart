import 'package:flutter/material.dart';
import '../data/isar_service.dart';
import '../data/models/exercise_badge.dart';
import '../data/models/workout_plan.dart';
import '../services/badge_service.dart';
import '../theme/app_colors.dart';
import '../utils/icon_mapper.dart';
import '../utils/workout_stats_data.dart';
import 'workout_runner_screen.dart';
import '../widgets/statistics_module.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WorkoutStatsData? _statsData;
  List<ExerciseBadge> _recentBadges = [];
  List<WorkoutPlan> _plans = [];
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final stats = await IsarService.instance.getWorkoutStatistics();
    final badges = await IsarService.instance.getRecentUnlockedBadges(limit: 5);
    final plans = await IsarService.instance.getAllWorkoutPlans();

    setState(() {
      _statsData = stats;
      _recentBadges = badges;
      _plans = plans;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Statistici & Progres', Icons.bar_chart),
                const SizedBox(height: 12),
                if (_statsData != null)
                  StatisticsModule(stats: _statsData!)
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text("Nu există suficiente date pentru statistici.")),
                    ),
                    color: AppColors.card,
                  ),

                const SizedBox(height: 24),

                // 2. MODUL PLANURI DE ANTRENAMENT
                _buildSectionHeader('Planurile Tale', Icons.fitness_center),
                const SizedBox(height: 12),
                _buildWorkoutPlansModule(),

                const SizedBox(height: 24),

                // 3. MODUL BADGE-URI RECENT CÂȘTIGATE
                _buildSectionHeader('Badge-uri Recente', Icons.emoji_events),
                const SizedBox(height: 12),
                _buildRecentBadgesModule(),
              ],
            ),
          ),
        ),
      )
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Modul 2: Lista de Planuri de Antrenament
  Widget _buildWorkoutPlansModule() {
    if (_plans.isEmpty) {
      return Card(
        color: AppColors.card,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              "Nu ai creat încă niciun plan de antrenament.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _plans.length,
        itemBuilder: (context, index) {
          final plan = _plans[index];
          return Container(
            width: 220,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: AppColors.card,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${plan.items.length} exerciții',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow, size: 18, color: AppColors.textPrimary,),
                        label: const Text('Start', style: TextStyle(color: AppColors.textPrimary),),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkoutRunnerScreen(plan: plan),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Modul 3: Badge-uri Recente Câștigate
  Widget _buildRecentBadgesModule() {
    if (_recentBadges.isEmpty) {
      return Card(
        color: AppColors.card,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              "Încă nu ai deblocat niciun badge. Completează antrenamente pentru a câștiga trofee!",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentBadges.length,
        itemBuilder: (context, index) {
          final badge = _recentBadges[index];
          return InkWell(
            onTap: () => BadgeService.showBadgeDetailDialog(context, badge),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 90,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.warning,
                    child: Icon(
                      IconMapper.getIcon(badge.iconName),
                      color: Colors.amber.shade900,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      badge.title,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}