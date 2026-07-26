import 'package:fitnalyzer/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../data/isar_service.dart';
import '../data/models/workout_plan.dart';
import 'create_workout_screen.dart';
import 'workout_runner_screen.dart';

class WorkoutPlannerScreen extends StatefulWidget {
  const WorkoutPlannerScreen({super.key});

  @override
  State<WorkoutPlannerScreen> createState() => _WorkoutPlannerScreenState();
}

class _WorkoutPlannerScreenState extends State<WorkoutPlannerScreen> {
  List<WorkoutPlan> _workoutPlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkoutPlans();
  }

  String _formatScheduleText(WorkoutPlan plan) {
    if (plan.selectedDays.isEmpty) {
      return "Fără programare";
    }

    final formattedTime =
        '${plan.notificationHour.toString().padLeft(2, '0')}:${plan.notificationMinute.toString().padLeft(2, '0')}';

    if (plan.selectedDays.length == 7) {
      return 'Zilnic la $formattedTime';
    }

    final dayMap = {
      1: 'Lun',
      2: 'Mar',
      3: 'Mie',
      4: 'Joi',
      5: 'Vin',
      6: 'Sâm',
      7: 'Dum',
    };

    final sortedDays = List<int>.from(plan.selectedDays)..sort();
    final dayNames = sortedDays.map((d) => dayMap[d] ?? '').join(', ');

    return '$dayNames la $formattedTime';
  }

  // Încărcarea planurilor salvate din Isar
  Future<void> _loadWorkoutPlans() async {
    setState(() => _isLoading = true);
    final plans = await IsarService.instance.getAllWorkoutPlans();
    setState(() {
      _workoutPlans = plans;
      _isLoading = false;
    });
  }

  // 1. Deschide Wizard-ul pentru creare plan nou
  Future<void> _addNewWorkout() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateWorkoutWizardScreen(),
      ),
    );
    // Reîncărcăm lista la întoarcere
    _loadWorkoutPlans();
  }

  // 2. Deschide Wizard-ul pentru editarea unui plan existent
  Future<void> _editWorkout(WorkoutPlan plan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateWorkoutWizardScreen(existingPlan: plan),
      ),
    );
    _loadWorkoutPlans();
  }

  // 3. Șterge planul din baza de date
  Future<void> _deleteWorkout(WorkoutPlan plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge Planul?'),
        content: Text('Ești sigur că vrei să ștergi "${plan.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Șterge', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await IsarService.instance.deleteWorkoutPlan(plan.id);
      _loadWorkoutPlans();
    }
  }

  // 4. Pornește antrenamentul cu WorkoutRunnerScreen
  void _startWorkout(WorkoutPlan plan) {
    if (plan.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acest plan nu are exerciții adăugate!'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutRunnerScreen(plan: plan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _workoutPlans.isEmpty
          ? _buildEmptyState()
          : _buildWorkoutList(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        hoverColor: AppColors.surface,
        onPressed: _addNewWorkout,
        icon: const Icon(Icons.add),
        label: const Text('Workout Nou'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Nu ai niciun plan creat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Apasă pe butonul de mai jos pentru a-ți crea primul antrenament customizat.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutList() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.secondary,
      onRefresh: _loadWorkoutPlans,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _workoutPlans.length,
        itemBuilder: (context, index) {
          final plan = _workoutPlans[index];
          final exerciseCount = plan.items.where((i) => i.type != 'REST').length;
          final scheduleText = _formatScheduleText(plan);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppColors.secondary,
                child: Icon(
                  Icons.fitness_center,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                plan.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '$exerciseCount exerciții',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.alarm, size: 14, color:  AppColors.accent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          scheduleText,
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_fill, color: AppColors.primary, size: 36),
                    onPressed: () => _startWorkout(plan),
                    tooltip: 'Start Workout',
                  ),
                  PopupMenuButton<String>(
                    color: AppColors.background,
                    icon: Icon(Icons.adaptive.more, color: AppColors.textSecondary),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editWorkout(plan);
                      } else if (value == 'delete') {
                        _deleteWorkout(plan);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, color: AppColors.accent),
                            SizedBox(width: 8),
                            Text('Editează', style: TextStyle(color: AppColors.textPrimary),),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Șterge', style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}