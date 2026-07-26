import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

class ScreenshotService {
  static Future<String?> captureAndSave(String badgeId,ScreenshotController? controller) async {
    if (controller == null) return null;
    try {
      final imageBytes = await controller.capture();
      if (imageBytes == null) return null;

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/badge_$badgeId\_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File(imagePath);
      await file.writeAsBytes(imageBytes);

      return imagePath;
    } catch (e) {
      print("Eroare la realizarea screenshot-ului: $e");
      return null;
    }
  }
}