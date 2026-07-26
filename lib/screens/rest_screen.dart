import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RestScreen extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback onRestComplete;

  const RestScreen({Key? key, required this.durationSeconds, required this.onRestComplete}) : super(key: key);

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> {
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.durationSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        widget.onRestComplete();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.coffee, size: 80, color: AppColors.warning),
            const SizedBox(height: 20),
            const Text("PAUZĂ", style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("$_secondsLeft s", style: const TextStyle(color: AppColors.warning, fontSize: 60, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _timer?.cancel();
                widget.onRestComplete();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  textStyle: const TextStyle(color:AppColors.textPrimary)
              ),
              child: const Text("Sari peste pauză"),
            )
          ],
        ),
      ),
    );
  }
}