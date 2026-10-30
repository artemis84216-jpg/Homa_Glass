import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'device_info_helper.dart';
import 'license_helper.dart';
import 'database_helper.dart';
import 'app_utils.dart';
import 'general_info_dev_screen.dart'; // فایل جدیدی که در مرحله بعد می‌سازیم

class DeveloperPanelScreen extends StatefulWidget {
  const DeveloperPanelScreen({super.key});

  @override
  State<DeveloperPanelScreen> createState() => _DeveloperPanelScreenState();
}

class _DeveloperPanelScreenState extends State<DeveloperPanelScreen> {
  String _deviceId = 'در حال دریافت...';
  final _planIdController = TextEditingController(text: '1');
  final _daysController = TextEditingController(text: '365');
  String _generatedCode = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final id = await DeviceInfoHelper.instance.getDeviceId();
    setState(() => _deviceId = id);
  }

  void _generateLicense() {
    final planId = int.tryParse(_planIdController.text) ?? 1;
    final days = int.tryParse(_daysController.text) ?? 365;
    final code = LicenseHelper.generateLicenseCode(_deviceId, planId, days);
    setState(() => _generatedCode = code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('پنل توسعه‌دهنده'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // بخش اطلاعات
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.yellow, width: 1)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Homa_Glass', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.yellow)),
                    const SizedBox(height: 8),
                    const Text('نسخه ۱.۰.۰', style: TextStyle(color: AppTheme.textGrey)),
                    const SizedBox(height: 8),
                    const Text('توسعه‌دهنده: حسین معصومی', style: TextStyle(color: AppTheme.textWhite)),
                    const Text('گروه نرم‌افزاری هما', style: TextStyle(color: AppTheme.textWhite)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // بخش تولید لایسنس
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.key, color: AppTheme.yellow), SizedBox(width: 8), Text('تولید کد لایسنس', style: TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.fingerprint, color: AppTheme.textGrey, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_deviceId, style: const TextStyle(color: AppTheme.textYellow, fontFamily: 'monospace', fontSize: 12))),
                            IconButton(icon: const Icon(Icons.copy, color: AppTheme.yellow, size: 20), onPressed: () {
                              Clipboard.setData(ClipboardData(text: _deviceId));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شناسه کپی شد'), backgroundColor: Colors.green));
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextField(controller: _planIdController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'شناسه پلن', hintText: '1'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _daysController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'مدت (روز)', hintText: '365'))),
                      ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _generateLicense,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('تولید کد لایسنس'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, foregroundColor: Colors.black),
                        ),
                      ),
                      if (_generatedCode.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.green.shade900, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('کد تولید شده:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(_generatedCode, style: const TextStyle(color: AppTheme.textWhite, fontFamily: 'monospace', fontSize: 12)),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _generatedCode));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کد لایسنس کپی شد'), backgroundColor: Colors.green));
                                  },
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('کپی کد'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                ),
                              )
                            ],
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // بخش مدیریت اطلاعات عمومی
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.library_books, color: AppTheme.yellow), SizedBox(width: 8), Text('مدیریت اطلاعات عمومی', style: TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 8),
                      const Text('افزودن، ویرایش یا حذف مقالات آموزشی درباره سلامت چشم', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GeneralInfoDevScreen())),
                          icon: const Icon(Icons.edit),
                          label: const Text('ورود به بخش مدیریت'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardBlack, foregroundColor: AppTheme.yellow, side: const BorderSide(color: AppTheme.yellow)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}