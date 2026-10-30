import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class LicenseHistoryScreen extends StatefulWidget {
  const LicenseHistoryScreen({super.key});

  @override
  State<LicenseHistoryScreen> createState() => _LicenseHistoryScreenState();
}

class _LicenseHistoryScreenState extends State<LicenseHistoryScreen> {
  List<Map<String, dynamic>> _licenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseHelper.instance.getAllLicenses();
      if (mounted) setState(() { _licenses = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('سوابق لایسنس‌ها'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.yellow), onPressed: _loadLicenses)]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.yellow))
          : _licenses.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('سابقه‌ای ثبت نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))]))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _licenses.length,
                  itemBuilder: (context, index) {
                    final l = _licenses[index];
                    DateTime? expiryDate;
                    try { expiryDate = DateTime.parse(l['expiry_date']); } catch (e) {}
                    final isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Icon(isExpired ? Icons.warning : Icons.check_circle, color: isExpired ? Colors.red : Colors.green, size: 24),
                            const SizedBox(width: 8),
                            Expanded(child: Text(l['plan_name'] ?? 'پلن نامشخص', style: TextStyle(color: isExpired ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 16))),
                          ]),
                          const SizedBox(height: 12),
                          _infoRow('شناسه دستگاه', l['device_id'] ?? '-'),
                          _infoRow('کد لایسنس', l['license_code'] ?? '-', isMono: true),
                          _infoRow('تاریخ صدور', l['issued_at']?.toString().substring(0, 10) ?? '-'),
                          _infoRow('تاریخ انقضا', expiryDate != null ? '${expiryDate.year}/${expiryDate.month.toString().padLeft(2, '0')}/${expiryDate.day.toString().padLeft(2, '0')}' : '-', color: isExpired ? Colors.red : AppTheme.textWhite),
                          if (isExpired) const Padding(padding: EdgeInsets.only(top: 8), child: Text('⚠️ منقضی شده', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _infoRow(String label, String value, {Color color = AppTheme.textWhite, bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
        const SizedBox(height: 2),
        SelectableText(value, style: TextStyle(color: color, fontSize: 13, fontFamily: isMono ? 'monospace' : 'default')),
      ]),
    );
  }
}