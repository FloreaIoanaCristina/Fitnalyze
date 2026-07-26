import 'package:fitnalyzer/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/isar_service.dart';
import '../data/models/workout_plan.dart';
import '../data/models/exercise_schema.dart';
import '../services/notification_service.dart';
import '../widgets/workout_schedule_selector.dart';

class CreateWorkoutWizardScreen extends StatefulWidget {
  final WorkoutPlan? existingPlan;

  const CreateWorkoutWizardScreen({Key? key, this.existingPlan}) : super(key: key);

  @override
  State<CreateWorkoutWizardScreen> createState() => _CreateWorkoutWizardScreenState();
}

class _CreateWorkoutWizardScreenState extends State<CreateWorkoutWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final TextEditingController _titleController = TextEditingController();

  List<int> _selectedDays = [];
  TimeOfDay _notificationTime = const TimeOfDay(hour: 8, minute: 0);

  List<WorkoutItem> _selectedItems = [];
  List<ExerciseSchema> _availableSchemas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableExercises();

    if (widget.existingPlan != null) {
      _titleController.text = widget.existingPlan!.title;
      _selectedDays = List.from(widget.existingPlan!.selectedDays);
      _notificationTime = TimeOfDay(
        hour: widget.existingPlan!.notificationHour,
        minute: widget.existingPlan!.notificationMinute,
      );
      _selectedItems = List.from(widget.existingPlan!.items);
    }
  }

  Future<void> _loadAvailableExercises() async {
    final exercises = await IsarService.instance.getAllExercises();
    setState(() {
      _availableSchemas = exercises;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingPlan == null ? "Creează Antrenament" : "Editează Antrenament",
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              "Pasul ${_currentStep + 1} din 3",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            color: AppColors.primary,
            backgroundColor: AppColors.textSecondary
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1Metadata(),
          _buildStep2SelectExercises(),
          _buildStep3ConfigureRestAndOrder(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ==========================================
  // PASUL 1: Nume & Frecvență
  // ==========================================
  Widget _buildStep1Metadata() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Denumire Workout",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: "ex: Antrenament Picioare / Morning Flow",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.fitness_center),
            ),
          ),
          const SizedBox(height: 20),

          WorkoutScheduleSelector(
            initialTime: _notificationTime,
            initialSelectedDays: _selectedDays,
            onTimeChanged: (newTime) {
              _notificationTime = newTime;
            },
            onDaysChanged: (newDays) {
              _selectedDays = newDays;
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PASUL 2: Selectare & Editare Exerciții
  // ==========================================
  Widget _buildStep2SelectExercises() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _showAddExerciseBottomSheet,
            icon: const Icon(Icons.add, color: AppColors.textPrimary),
            label: const Text("Adaugă Exercițiu", style: TextStyle(color: AppColors.textPrimary),),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedItems.isEmpty
                ? const Center(
              child: Text(
                "Nu ai adăugat niciun exercițiu încă.\nApasă butonul de mai sus pentru a începe.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ReorderableListView.builder(
              itemCount: _selectedItems.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _selectedItems.removeAt(oldIndex);
                  _selectedItems.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final item = _selectedItems[index];
                final isRest = item.type == "REST";

                return Card(
                  key: ValueKey("item_${index}_${item.displayTitle}"),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: AppColors.card,
                  child: ListTile(
                    leading: Icon(
                      isRest ? Icons.timer : Icons.directions_run,
                      color: isRest ? AppColors.warning : AppColors.accent,
                    ),
                    title: Text(item.displayTitle ?? "Element"),
                    subtitle: Text(_getItemSummaryText(item)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.accent),
                          onPressed: () => _showEditItemDialog(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.error),
                          onPressed: () {
                            setState(() => _selectedItems.removeAt(index));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper text rezumat pentru fiecare card
  String _getItemSummaryText(WorkoutItem item) {
    if (item.type == "REST") {
      return "Durată pauză: ${item.targetDurationSeconds} secunde";
    }
    if (item.targetDurationSeconds > 0) {
      return "Durată: ${item.targetDurationSeconds} secunde";
    }
    return "Repetări: ${item.targetReps}";
  }

  // Dialog pentru configurarea numărului de repetări și a timpului
  void _showEditItemDialog(int index) {
    final item = _selectedItems[index];

    // Identificăm schema tehnică dacă este de tip exercițiu
    ExerciseSchema? schema;
    if (item.type != "REST") {
      schema = _availableSchemas.firstWhere(
            (s) => s.exerciseId == item.exerciseId,
        orElse: () => ExerciseSchema(),
      );
    }

    final bool isNativelyTimerBased = schema?.isTimerBased ?? false;
    final bool isRest = item.type == "REST";
    // Modul inițial: dacă este nativ pe timp sau dacă are secunde setate
    bool isTimedMode = isRest || isNativelyTimerBased || (item.targetDurationSeconds > 0 && item.targetReps == 0);
    int reps = item.targetReps > 0 ? item.targetReps : 10;
    int duration = item.targetDurationSeconds > 0 ? item.targetDurationSeconds : 30;
    final TextEditingController durationTextController =
    TextEditingController(text: duration.toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Configurare ${item.displayTitle}"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dacă nu e pauză și nici nativ temporizat, oferim opțiunea de comutare
                  if (!isRest && !isNativelyTimerBased) ...[
                    const Text(
                      "Tip măsurare:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text("Repetări"),
                          icon: Icon(Icons.repeat),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text("Secunde"),
                          icon: Icon(Icons.timer),
                        ),
                      ],
                      selected: {isTimedMode},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setDialogState(() {
                          isTimedMode = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Cazul 1: Configurare REPETĂRI
                  if (!isTimedMode) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Număr Repetări:"),
                        Row(
                          children: [
                            IconButton(
                              onPressed: reps > 1 ? () => setDialogState(() => reps--) : null,
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
                            ),
                            Text("$reps", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            IconButton(
                              onPressed: () => setDialogState(() => reps++),
                              icon: const Icon(Icons.add_circle_outline,color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ]
                  // Cazul 2: Configurare SECUNDE (Câmp de text numeric)
                  else ...[
                    TextField(
                      controller: durationTextController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isRest ? "Durată Pauză (secunde)" : "Durată Exercițiu (secunde)",
                        hintText: "ex: 30",
                        border: const OutlineInputBorder(),
                        suffixText: "sec",
                        prefixIcon: const Icon(Icons.timer, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Anulează"),
              ),
              ElevatedButton(
                onPressed: () {
                  final parsedDuration = int.tryParse(durationTextController.text.trim()) ?? 30;
                  setState(() {
                    if (isTimedMode) {
                      item.targetDurationSeconds = parsedDuration > 0 ? parsedDuration : 30;
                      item.targetReps = 0;
                    } else {
                      item.targetReps = reps;
                      item.targetDurationSeconds = 0;
                    }
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    textStyle: const TextStyle(color:AppColors.textPrimary)
                ),
                child: const Text("Salvează"),
              )
            ],
          );
        },
      ),
    );
  }

  void _showAddExerciseBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: _availableSchemas.length,
        itemBuilder: (context, i) {
          final s = _availableSchemas[i];
          final isTimer = s.isTimerBased ?? false;

          return SafeArea(
              child: ListTile(
            leading: Icon(
              isTimer ? Icons.timer : Icons.fitness_center,
              color: AppColors.primary,
            ),
            title: Text(s.title ?? "Exercițiu"),
            subtitle: Text(isTimer ? "Exercițiu temporizat" : "Exercițiu cu repetări"),
            onTap: () {
              setState(() {
                _selectedItems.add(
                  WorkoutItem()
                    ..type = "EXERCISE"
                    ..exerciseId = s.exerciseId
                    ..displayTitle = s.title
                    ..targetReps = isTimer ? 0 : 10
                    ..targetDurationSeconds = isTimer ? 30 : 0,
                );
              });
              Navigator.pop(ctx);
            },
           ),
          );
        },
      ),
    );
  }

  // ==========================================
  // PASUL 3: Adăugare Pauze Intermediare
  // ==========================================
  Widget _buildStep3ConfigureRestAndOrder() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Ajustare Pauze între Exerciții",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 6),
        const Text(
          "Puteți adăuga pauze dedicate între oricare două exerciții din rutină.",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < _selectedItems.length; i++) ...[
          Card(
            color: AppColors.card,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _selectedItems[i].type == "REST" ? AppColors.warning : AppColors.success,
                foregroundColor: AppColors.accent,
                child: Text("${i + 1}"),
              ),
              title: Text(_selectedItems[i].displayTitle ?? ""),
              subtitle: Text(_getItemSummaryText(_selectedItems[i])),
              trailing: _selectedItems[i].type == "REST"
                  ? IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: () => setState(() => _selectedItems.removeAt(i)),
              )
                  : null,
            ),
          ),
          // Oferim opțiunea de a adăuga pauză între 2 exerciții
          if (i < _selectedItems.length - 1 && _selectedItems[i].type != "REST")
            Center(
              child: TextButton.icon(
                onPressed: () => _insertRestAfter(i),
                icon: const Icon(Icons.add_alarm, size: 18, color: AppColors.textSecondary),
                label: const Text("Adaugă pauză aici",style: TextStyle(color:AppColors.textSecondary ),),
              ),
            ),
        ]
      ],
    );
  }

  void _insertRestAfter(int index) {
    setState(() {
      _selectedItems.insert(
        index + 1,
        WorkoutItem()
          ..type = "REST"
          ..displayTitle = "Pauză Reorganizare"
          ..targetReps = 0
          ..targetDurationSeconds = 30,
      );
    });
  }

  Widget _buildBottomNav() {
    return SafeArea( // 👈 Adaugă SafeArea aici!
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentStep > 0)
              OutlinedButton(
                onPressed: () {
                  setState(() => _currentStep--);
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text("Înapoi"),
              )
            else
              const SizedBox.shrink(),
            ElevatedButton(
              onPressed: () {
                if (_currentStep == 0 && _titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Te rugăm să introduci o denumire pentru workout.")),
                  );
                  return;
                }

                if (_currentStep == 1 && _selectedItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Adaugă cel puțin un exercițiu în rutină.")),
                  );
                  return;
                }

                if (_currentStep < 2) {
                  setState(() => _currentStep++);
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _saveWorkoutPlan();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                textStyle: const TextStyle(color:AppColors.textPrimary)
              ),
              child: Text(_currentStep == 2 ? "Salvează Workout" : "Înainte"),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _saveWorkoutPlan() async {
    final plan = widget.existingPlan ?? WorkoutPlan();
    plan.title = _titleController.text.trim();
    plan.notificationHour = _notificationTime.hour;
    plan.notificationMinute = _notificationTime.minute;
    plan.selectedDays = _selectedDays;
    plan.items = _selectedItems;

    await IsarService.instance.saveWorkoutPlan(plan);

    final prefs = await SharedPreferences.getInstance();
    final bool isNotificationsGlobalOn = prefs.getBool('notifications_enabled') ?? true;

    if (isNotificationsGlobalOn) {
      await NotificationService.instance.scheduleWorkoutNotifications(plan);
    } else {
      await NotificationService.instance.cancelWorkoutNotifications(plan.id);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
