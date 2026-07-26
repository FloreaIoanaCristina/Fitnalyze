import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

class WorkoutScheduleSelector extends StatefulWidget {
  final TimeOfDay? initialTime;
  final List<int> initialSelectedDays;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final ValueChanged<List<int>> onDaysChanged;

  const WorkoutScheduleSelector({
    super.key,
    this.initialTime,
    required this.initialSelectedDays,
    required this.onTimeChanged,
    required this.onDaysChanged,
  });

  @override
  State<WorkoutScheduleSelector> createState() => _WorkoutScheduleSelectorState();
}

class _WorkoutScheduleSelectorState extends State<WorkoutScheduleSelector> {
  late TimeOfDay _selectedTime;
  late List<int> _selectedDays;
  bool _areNotificationsEnabledInSettings = true;

  final Map<int, String> _weekDays = {
    1: 'L',
    2: 'M',
    3: 'M',
    4: 'J',
    5: 'V',
    6: 'S',
    7: 'D',
  };

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime ?? const TimeOfDay(hour: 08, minute: 00);
    _selectedDays = List.from(widget.initialSelectedDays);
    _checkSettingsNotificationStatus();
  }

  Future<void> _checkSettingsNotificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _areNotificationsEnabledInSettings = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
      widget.onTimeChanged(picked);
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
    widget.onDaysChanged(_selectedDays);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header cu Titlu + Oră (folosim Expanded pe titlu ca să nu dea overflow)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.alarm, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Programare Antrenament',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _pickTime,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.primary,
                  ),
                  child: Text(
                    _selectedTime.format(context),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Alege zilele de repetare:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            // 2. Zilele Săptămânii într-un FittedBox / LayoutBuilder
            // Garantează că cele 7 cercuri se scalează perfect indiferent de lățimea ecranului
            LayoutBuilder(
              builder: (context, constraints) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _weekDays.entries.map((entry) {
                        final dayIndex = entry.key;
                        final dayLabel = entry.value;
                        final isSelected = _selectedDays.contains(dayIndex);

                        return FilterChip(
                          padding: const EdgeInsets.all(4),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          label: Text(dayLabel),
                          selected: isSelected,
                          showCheckmark: false,
                          shape: const CircleBorder(),
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.transparent,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => _toggleDay(dayIndex),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),

            // 3. Atenționare Notificări Dezactivate
            if (!_areNotificationsEnabledInSettings) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notificările sunt dezactivate din Setări. Nu vei primi alarme până nu le bifezi.',
                        style: TextStyle(fontSize: 12, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}