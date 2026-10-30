import 'package:flutter/material.dart';
import 'app_utils.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('درباره ما'), centerTitle: true),
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
                  child: const Icon(Icons.visibility, color: AppTheme.yellow, size: 60),
                ),
                const SizedBox(height: 24),
                const Text('Homa_Glass', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.yellow)),
                const SizedBox(height: 8),
                const Text('نسخه ۱.۰.۰', style: TextStyle(color: AppTheme.textGrey, fontSize: 16)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.yellow.withOpacity(0.3))),
                  child: const Column(
                    children: [
                      Text('توسعه‌دهنده:', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                      SizedBox(height: 4),
                      Text('حسین معصومی', style: TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Text('گروه نرم‌افزاری هما', style: TextStyle(color: AppTheme.yellow, fontSize: 16)),
                      SizedBox(height: 16),
                      Text('تمامی حقوق محفوظ است © ۱۴۰۳', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}