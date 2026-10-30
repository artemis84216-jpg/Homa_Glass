import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final code = _licenseController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کد لایسنس را وارد کنید'), backgroundColor: Colors.red));
      return;
    }
    
    setState(() => _isLoading = true);
    
    final result = await LicenseHelper.validateAndSaveLicense(code, _deviceId);
    
    setState(() => _isLoading = false);
    
    if (result['success'] == true) {
      final plans = await DatabaseHelper.instance.getAllPlans();
      final plan = plans.firstWhere((p) => p['id'] == result['planId'], orElse: () => {'name': 'پلن $result[planId]'});
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ لایسنس فعال شد - ${plan['name']} - ${toPersianDigits(result['days'].toString())} روز'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ));
      Navigator.pop(context, true);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: const Row(children: [Icon(Icons.error, color: Colors.red, size: 28), SizedBox(width: 8), Text('خطا', style: TextStyle(color: Colors.red))]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result['message'] ?? 'خطای نامشخص', style: const TextStyle(color: AppTheme.textWhite)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('شناسه دستگاه شما:', style: TextStyle(color: AppTheme.textGrey, fontSize: 11)),
                      const SizedBox(height: 4),
                      SelectableText(_deviceId, style: const TextStyle(color: AppTheme.textYellow, fontSize: 11, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('متوجه شدم', style: TextStyle(color: AppTheme.yellow)),
              ),
            ],
          ),
        ),
      );
    }
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
                  const Text('برای استفاده از تمام قابلیت‌های برنامه، کد لایسنس را از توسعه‌دهنده دریافت و در اینجا وارد کنید.', style: TextStyle(color: Colors.orange, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.cardBlack, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.yellow, width: 1)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('شناسه دستگاه شما:', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: SelectableText(_deviceId, style: const TextStyle(color: AppTheme.textYellow, fontSize: 12, fontFamily: 'monospace'))),
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppTheme.yellow, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _deviceId));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شناسه کپی شد'), backgroundColor: Colors.green));
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _licenseController,
              style: const TextStyle(color: AppTheme.textWhite, fontFamily: 'monospace', fontSize: 12),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'کد لایسنس',
                hintText: 'HOMA-...',
                prefixIcon: Icon(Icons.key, color: AppTheme.yellow),
                alignLabelWithHint: true,
              ),
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