import 'package:fitnalyzer/screens/main_navigation_screen.dart';
import 'package:fitnalyzer/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import 'data/isar_service.dart';
import 'theme/app_colors.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inițializare unică și completă a Serviciului de Notificări
  await NotificationService.instance.init();

  // 2. Permisiuni Cameră
  await Permission.camera.request();

  // 3. Inițializare Bază de date Isar
  try {
    final isarService = IsarService.instance;
    await isarService.init();
    print("Isar Database inițializată cu succes!");
  } catch (e) {
    print("Eroare critică la inițializarea Isar: $e");
  }

  // 4. Inițializare Camere
  try {
    cameras = await availableCameras();
  } catch (e) {
    print("Eroare la inițializarea camerelor: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitnalyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor:  AppColors.surface,
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,       // culoarea principală
          secondary: AppColors.secondary,   // accent
          surface: AppColors.surface,       // fundal dialog
          onSurface: AppColors.textPrimary, // text
          onPrimary: AppColors.textPrimary,          // text pe butoane
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.primary,
          selectionColor: AppColors.primary,
          selectionHandleColor: AppColors.primary,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.secondary),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}