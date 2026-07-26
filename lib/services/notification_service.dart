import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../data/models/workout_plan.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// Inițializează fusul orar, plugin-ul, permisiunile și canalul Android
  Future<void> init() async {
    // 1. Configurarea fusului orar local
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      print('Eroare la setarea fusului orar: $e');
    }

    // 2. Setări de bază ale plugin-ului
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // 3. Permisiuni și creare canal nativ pentru Android
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Solicitare permisiuni afișare + alarme exacte
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();

      // Crearea canalului (Obligatoriu Android 8+)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'workout_channel',
        'Workout Reminders',
        description: 'Notificări pentru planul de antrenament',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await androidImplementation.createNotificationChannel(channel);
    }
  }

  /// Programează notificările săptămânale pentru un plan
  Future<void> scheduleWorkoutNotifications(WorkoutPlan plan) async {
    await cancelWorkoutNotifications(plan.id);

    if (plan.selectedDays.isEmpty) return;

    for (int dayOfWeek in plan.selectedDays) {
      final notificationId = _generateNotificationId(plan.id, dayOfWeek);

      final scheduledDate = _nextInstanceOfDayAndTime(
        dayOfWeek,
        plan.notificationHour,
        plan.notificationMinute,
      );

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Ora de antrenament! 💪',
        'Este timpul pentru planul tău: ${plan.title}',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'workout_channel',
            'Workout Reminders',
            icon: '@drawable/ic_notification',
            channelDescription: 'Notificări pentru planul de antrenament',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelWorkoutNotifications(int planId) async {
    for (int day = 1; day <= 7; day++) {
      await _notificationsPlugin.cancel(_generateNotificationId(planId, day));
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  int _generateNotificationId(int planId, int dayOfWeek) {
    return (planId * 10) + dayOfWeek;
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print('--------------------------------------------------');
    print('🔔 Notificare programată cu succes!');
    print('📅 Data & Ora: $scheduledDate');
    print('⏱ Peste: ${scheduledDate.difference(now).inMinutes} minute');
    print('--------------------------------------------------');

    return scheduledDate;
  }

  /// Verifică notificările înregistrate în sistemul Android
  Future<void> checkPendingNotifications() async {
    final pendingRequests =
    await _notificationsPlugin.pendingNotificationRequests();

    print('==================================================');
    print('📋 NOTIFICĂRI ACTIVE ÎN SISTEM (${pendingRequests.length}):');
    print('==================================================');

    if (pendingRequests.isEmpty) {
      print('❌ Nu există nicio notificare programată.');
      return;
    }

    for (var notification in pendingRequests) {
      print('🆔 ID: ${notification.id} | Titlu: ${notification.title} | Corp: ${notification.body}');
    }
  }
}