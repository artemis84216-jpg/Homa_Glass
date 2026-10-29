import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'device_info_helper.dart';
import 'license_helper.dart';
import 'app_utils.dart';

class LicenseInputScreen extends StatefulWidget {
  const LicenseInputScreen({super.key});

  @override
  State<LicenseInputScreen> createState() => _LicenseInputScreenState();
}

class _LicenseInputScreenState extends State<LicenseInputScreen> {
  final _licenseController = TextEditingController();
  final _shopNameController = TextEditingController();
  bool _isLoading = false;
  String _deviceId = 'در حال دریافت...';
  Map<String, dynamic>? _currentLicense;
  String _currentPlanName = 'بدون لایسنس';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final id = await DeviceInfoHelper.instance.getDeviceId();
    final license = await LicenseHelper.getLicense();
    
    String planName = 'بدون لایسنس';
    if (license != null && license['isActive'] == true) {
      final plans = await DatabaseHelper.instance.getAllPlans();
      final plan = plans.firstWhere((p) => p['id'] == license['planId'], orElse: () => {});
      if (plan.isNotEmpty) planName = plan['name'] ?? 'پلن نامشخص';
    }
    setState(() { 
      _deviceId = id; 
      _currentLicense = license; 
      _currentPlanName = planName;
    });
  }

  Future<void> _activateLicense() async {
    if (_licenseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کد لایسنس را وارد کنید'), backgroundColor: Colors.red));
      return;
    }
    
    setState(() => _isLoading = true);
    
    // شبیه‌سازی اعتبارسنجی (در نسخه واقعی، این کد باید از سرور چک شود)
    // فرمت کد: GLASS-PLAN-DAYS (مثال: GLASS-1-365)
    final code = _licenseController.text.trim();
    final parts = code.split('-');
    
    if (parts.length != 3 || parts[0] != 'GLASS') {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فرمت کد لایسنس نامعتبر است'), backgroundColor: Colors.red));
      return;
    }

    final planId = int.tryParse(parts[1]);
    final days = int.tryParse(parts[2]);
    
    if (planId == null || days == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کد لایسنس نامعتبر است'), backgroundColor: Colors.red));
      return;
    }

    final plans = await DatabaseHelper.instance.getAllPlans();
    final plan = plans.firstWhere((p) => p['id'] == planId, orElse: () => {});
    
    if (plan.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پلن یافت نشد'), backgroundColor: Colors.red));
      return;
    }

    Jalali expiry = Jalali.now().addDays(days);
    await LicenseHelper.saveLicense(code, planId, expiry);
    
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✓ لایسنس فعال شد - ${plan['name']}'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
    ));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveLicense = _currentLicense != null && _currentLicense!['isActive'] == true;
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('فعال‌سازی لایسنس'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasActiveLicense ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: hasActiveLicense ? Colors.green : Colors.orange, width: 1),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(hasActiveLicense ? Icons.check_circle : Icons.info, color: hasActiveLicense ? Colors.green : Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  Expanded(child: Text(hasActiveLicense ? 'لایسنس فعال' : 'فعال‌سازی لایسنس', style: TextStyle(color: hasActiveLicense ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 16))),
                ]),
                const SizedBox(height: 8),
                if (hasActiveLicense) ...[
                  Text('پلن فعلی: $_currentPlanName', style: const TextStyle(color: AppTheme.textWhite)),
                  Text('روزهای باقی‌مانده: ${toPersianDigits((_currentLicense!['daysRemaining']).toString())}', style: const TextStyle(color: AppTheme.textWhite)),
                ] else
                  const Text('برای استفاده از تمام قابلیت‌های برنامه، کد لایسنس را وارد کنید.', style: TextStyle(color: Colors.orange, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.yellow, width: 1)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('شناسه دستگاه شما:', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                const SizedBox(height: 4),
                SelectableText(_deviceId, style: const TextStyle(color: AppTheme.textYellow, fontSize: 12, fontFamily: 'monospace')),
              ]),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _licenseController,
              style: const TextStyle(color: AppTheme.textWhite, fontFamily: 'monospace', fontSize: 12),
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'کد لایسنس', hintText: 'GLASS-1-365', prefixIcon: Icon(Icons.key, color: AppTheme.yellow), alignLabelWithHint: true),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _activateLicense,
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.check_circle, size: 24),
                label: Text(_isLoading ? 'در حال بررسی...' : 'فعال‌سازی', style: const TextStyle(fontSize: 18)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}