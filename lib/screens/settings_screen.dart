import 'package:fitnalyzer/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/isar_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController(text: "Atlet");
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _nameController.text = prefs.getString('user_name') ?? "Atlet";
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);

    // 1. Salvare în SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);

    // 2. Gestionare notificări în sistem
    if (!value) {
      await NotificationService.instance.cancelAllNotifications();
    } else {
      // Re-programăm notificările pentru toate planurile existente
      final plans = await IsarService.instance.getAllWorkoutPlans();
      for (var plan in plans) {
        await NotificationService.instance.scheduleWorkoutNotifications(plan);
      }
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Resetezi aplicația?'),
          content: const Text(
            'Ești sigur că vrei să faci asta? Vei pierde definitiv tot progresul, insignele și statisticile acumulate.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anulează'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                // Curățare date
                await NotificationService.instance.cancelAllNotifications();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                await IsarService.instance.resetAllUserData();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Toate datele au fost resetate!')),
                  );
                }
              },
              child: const Text('Da, șterge tot', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.primary),
            title: const Text('Profilul tău'),
            subtitle: TextField(
              cursorColor: AppColors.primary,
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Introdu numele tău'),
              onChanged: (val) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_name', val);
              },
            ),
          ),
          const Divider(color: AppColors.textSecondary,),
          SwitchListTile(
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.secondary,
            secondary: const Icon(Icons.notifications, color: AppColors.primary),
            title: const Text('Notificări zilnice'),
            subtitle: const Text('Amintește-mi să îmi fac antrenamentul'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          const Divider(color: AppColors.textSecondary,),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                overlayColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text(
                'Resetează complet aplicația',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _showResetDialog,
            ),
          ),
        ],
      ),
    );
  }
}