import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_utils.dart';
import 'splash_screen.dart';
import 'database_helper.dart'; // اضافه شد برای دسترسی به دیتابیس

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ⚠️ راه حل اضطراری: حذف کامل دیتابیس قدیمی در شروع برنامه
  try {
    await DatabaseHelper.instance.resetDatabaseCompletely();
    print('✅ دیتابیس قدیمی با موفقیت حذف شد. برنامه از صفر شروع می‌شود.');
  } catch (e) {
    print('⚠️ خطا در حذف دیتابیس (احتمالاً فایل جدید است): $e');
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homa Glass',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkYellowTheme,
      home: const SplashScreen(),
    );
  }
}