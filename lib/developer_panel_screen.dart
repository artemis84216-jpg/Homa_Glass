import 'package:flutter/material.dart';
import 'app_utils.dart';

class DeveloperPanelScreen extends StatelessWidget {
  const DeveloperPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('پنل توسعه‌دهنده'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppTheme.yellow.withOpacity(0.3), AppTheme.yellow.withOpacity(0.1)]),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.yellow, width: 2),
                  ),
                  child: const Icon(Icons.developer_mode, color: AppTheme.yellow, size: 60),
                ),
                const SizedBox(height: 24),
                const Text('پنل توسعه‌دهنده', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.yellow)),
                const SizedBox(height: 16),
                const Text(
                  'Homa_Glass\nنسخه ۱.۰.۰\n\nتوسعه‌دهنده: حسین معصومی\nگروه نرم‌افزاری هما',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textWhite, fontSize: 14, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}