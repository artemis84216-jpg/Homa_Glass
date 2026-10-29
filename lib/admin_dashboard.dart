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
import 'suppliers_screen.dart';
import 'license_input_screen.dart';
import 'license_helper.dart';
import 'app_utils.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _dailyTip = '';
  String _todayDate = '';
  Map<String, dynamic>? _license;
  String _planName = 'بدون لایسنس';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dailyTip = getRandomDailyTip();
    final now = Jalali.now();
    const weekDays = ['دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه', 'شنبه', 'یکشنبه'];
    const monthNames = ['', 'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'];
    _todayDate = '${weekDays[now.weekDay - 1]} ${toPersianDigits(now.day.toString())} ${monthNames[now.month]} ${toPersianDigits(now.year.toString())}';
    _loadLicense();
  }

  Future<void> _loadLicense() async {
    final license = await LicenseHelper.getLicense();
    String planName = 'بدون لایسنس';
    if (license != null && license['isActive'] == true) {
      final plans = await DatabaseHelper.instance.getAllPlans();
      final plan = plans.firstWhere((p) => p['id'] == license['planId'], orElse: () => {});
      if (plan.isNotEmpty) planName = plan['name'] ?? 'پلن نامشخص';
    }
    setState(() {
      _license = license;
      _planName = planName;
      _isLoading = false;
    });
  }

  bool get _isLicenseActive => _license != null && _license!['isActive'] == true;

  Color _getLicenseColor() {
    if (!_isLicenseActive) return Colors.red;
    final days = _license!['daysRemaining'];
    if (days <= 7) return Colors.orange;
    return Colors.green;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.yellow))
          : Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // تاریخ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: AppTheme.cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.yellow, width: 1)),
                      child: Row(children: [const Icon(Icons.calendar_today, color: AppTheme.yellow, size: 20), const SizedBox(width: 12), Text(_todayDate, style: const TextStyle(color: AppTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold))]),
                    ),
                    const SizedBox(height: 12),

                    // وضعیت لایسنس
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: _getLicenseColor(), width: 2)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.security, color: _getLicenseColor(), size: 24),
                          const SizedBox(width: 8),
                          Expanded(child: Text('لایسنس: $_planName', style: TextStyle(color: _getLicenseColor(), fontWeight: FontWeight.bold, fontSize: 16))),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _getLicenseColor().withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(_isLicenseActive ? 'فعال' : 'غیرفعال', style: TextStyle(color: _getLicenseColor(), fontSize: 12, fontWeight: FontWeight.bold))),
                        ]),
                        const SizedBox(height: 8),
                        if (_isLicenseActive)
                          Text('${toPersianDigits(_license!['daysRemaining'].toString())} روز باقی‌مانده', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12))
                        else
                          const Text('برای استفاده از تمام قابلیت‌ها، لایسنس را فعال کنید', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LicenseInputScreen()));
                              if (result == true) _loadLicense();
                            },
                            icon: const Icon(Icons.key, size: 18),
                            label: Text(_isLicenseActive ? 'ارتقا لایسنس' : 'فعال‌سازی لایسنس', style: const TextStyle(fontSize: 14)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, foregroundColor: Colors.black),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // نکته روزانه
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
                        _buildCard(Icons.business, 'تامین‌کنندگان', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuppliersScreen()))),
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
        onTap: _isLicenseActive ? onTap : () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ابتدا لایسنس را فعال کنید'), backgroundColor: Colors.red));
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 40, color: _isLicenseActive ? AppTheme.yellow : Colors.grey),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _isLicenseActive ? AppTheme.textWhite : Colors.grey)),
          if (!_isLicenseActive) ...[const SizedBox(height: 4), const Icon(Icons.lock, size: 14, color: Colors.red)],
        ]),
      ),
    );
  }
}