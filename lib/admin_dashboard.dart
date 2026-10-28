import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'settings_screen.dart';
import 'customers_screen.dart';
import 'eye_exams_screen.dart';
import 'frames_screen.dart';
import 'lenses_screen.dart';
import 'sunglasses_screen.dart';
import 'orders_screen.dart';
import 'employees_screen.dart';
import 'reports_screen.dart';
import 'suppliers_screen.dart'; // <-- اضافه شد
import 'app_utils.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _dailyTip = '';
  String _todayDate = '';

  @override
  void initState() {
    super.initState();
    _dailyTip = getRandomDailyTip();
    final now = Jalali.now();
    const weekDays = ['دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه', 'شنبه', 'یکشنبه'];
    const monthNames = ['', 'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'];
    _todayDate = '${weekDays[now.weekDay - 1]} ${toPersianDigits(now.day.toString())} ${monthNames[now.month]} ${toPersianDigits(now.year.toString())}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Homa_Glass'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: AppTheme.yellow), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppTheme.cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.yellow, width: 1)),
                child: Row(children: [const Icon(Icons.calendar_today, color: AppTheme.yellow, size: 20), const SizedBox(width: 12), Text(_todayDate, style: const TextStyle(color: AppTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold))]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.yellow.withOpacity(0.3), AppTheme.yellow.withOpacity(0.1)]), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.yellow, width: 2)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [Icon(Icons.lightbulb, color: AppTheme.yellow), SizedBox(width: 8), Text('نکته روزانه سلامت چشم', style: TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.bold, fontSize: 16))]),
                  const SizedBox(height: 12),
                  Text(_dailyTip, style: const TextStyle(color: AppTheme.textWhite, fontSize: 15, height: 1.6)),
                ]),
              ),
              const SizedBox(height: 24),
              const Text('بخش‌های اصلی', style: TextStyle(color: AppTheme.yellow, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildCard(Icons.people, 'مشتریان', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen()))),
                  _buildCard(Icons.visibility, 'معاینات چشم', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EyeExamsScreen()))),
                  _buildCard(Icons.style, 'فریم‌ها', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FramesScreen()))),
                  _buildCard(Icons.lens_blur, 'عدسی‌ها', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LensesScreen()))),
                  _buildCard(Icons.wb_sunny, 'عینک آفتابی', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SunglassesScreen()))),
                  _buildCard(Icons.receipt_long, 'سفارشات', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))),
                  _buildCard(Icons.business, 'تامین‌کنندگان', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuppliersScreen()))), // <-- کارت جدید
                  _buildCard(Icons.people_alt, 'کارمندان', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeesScreen()))),
                  _buildCard(Icons.bar_chart, 'گزارشات', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(IconData icon, String title, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 40, color: AppTheme.yellow),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
        ]),
      ),
    );
  }
}