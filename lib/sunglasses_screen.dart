import 'package:flutter/material.dart';
import 'app_utils.dart';

class SunglassesScreen extends StatelessWidget {
  const SunglassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('عینک آفتابی'), centerTitle: true),
      body: const Center(child: Text('در فاز ۳ تکمیل می‌شود', style: TextStyle(color: AppTheme.textGrey))),
    );
  }
}