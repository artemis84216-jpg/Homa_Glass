import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'database_helper.dart';
import 'app_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (_currentPassController.text.isEmpty || _newPassController.text.isEmpty || _confirmPassController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً تمام فیلدها را پر کنید'), backgroundColor: Colors.red));
      return;
    }
    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز جدید و تکرار آن مطابقت ندارند'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPassword = prefs.getString('glass_password') ?? '1234';
      
      if (_currentPassController.text != savedPassword) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز فعلی اشتباه است'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
        return;
      }

      await prefs.setString('glass_password', _newPassController.text);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ رمز عبور با موفقیت تغییر کرد'), backgroundColor: Colors.green));
      _currentPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _backupDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final sourcePath = '$dbPath/homa_glass.db';
      final tempDir = await getTemporaryDirectory();
      final backupPath = '${tempDir.path}/homa_glass_backup_${DateTime.now().millisecondsSinceEpoch}.db';
      
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فایل دیتابیس یافت نشد'), backgroundColor: Colors.red));
        return;
      }
      
      await sourceFile.copy(backupPath);
      await Share.shareXFiles([XFile(backupPath)], text: 'پشتیبان Homa_Glass - ${getCurrentJalaliDateTime()}');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ فایل پشتیبان آماده اشتراک‌گذاری شد'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در پشتیبان‌گیری: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _resetDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('⚠️ هشدار جدی', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: const Text('این عمل تمام اطلاعات را برای همیشه پاک می‌کند. آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('بله، پاک کن', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.resetDatabase();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ دیتابیس پاک شد'), backgroundColor: Colors.green));
    }
  }

  // متد جدید برای بازنشانی کامل دیتابیس
  Future<void> _resetDatabaseCompletely() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('⚠️ بازنشانی کامل دیتابیس', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          content: const Text(
            'این عمل فایل دیتابیس را کاملاً حذف می‌کند و برنامه از صفر شروع می‌شود. تمام اطلاعات پاک خواهند شد.\n\nاگر با خطای دیتابیس مواجه هستید، این گزینه را بزنید.\n\nآیا مطمئن هستید؟',
            style: TextStyle(color: AppTheme.textWhite),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('بله، بازنشانی کن', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      try {
        await DatabaseHelper.instance.resetDatabaseCompletely();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ دیتابیس بازنشانی شد. برنامه را ببندید و دوباره باز کنید.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بازنشانی: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('خروج از برنامه', style: TextStyle(color: AppTheme.yellow)),
          content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              },
              child: const Text('بله', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('تنظیمات'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // کارت تغییر رمز
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.lock, color: AppTheme.yellow), SizedBox(width: 8), Text('تغییر رمز عبور', style: TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 16),
                      TextField(controller: _currentPassController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'رمز فعلی', prefixIcon: Icon(Icons.lock_outline, color: AppTheme.yellow))),
                      const SizedBox(height: 12),
                      TextField(controller: _newPassController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'رمز جدید', prefixIcon: Icon(Icons.key, color: AppTheme.yellow))),
                      const SizedBox(height: 12),
                      TextField(controller: _confirmPassController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'تکرار رمز جدید', prefixIcon: Icon(Icons.key, color: AppTheme.yellow))),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, foregroundColor: Colors.black),
                          onPressed: _isLoading ? null : _changePassword,
                          icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.save),
                          label: const Text('ذخیره رمز جدید', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // کارت پشتیبان‌گیری
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.cloud_upload, color: AppTheme.yellow), SizedBox(width: 8), Text('پشتیبان‌گیری', style: TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 12),
                      const Text('از تمام اطلاعات خود نسخه پشتیبان تهیه کنید.', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, foregroundColor: Colors.black),
                          onPressed: _backupDatabase,
                          icon: const Icon(Icons.download),
                          label: const Text('دریافت فایل پشتیبان', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // کارت بازنشانی کامل دیتابیس (جدید)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.refresh, color: Colors.orange), SizedBox(width: 8), Text('بازنشانی کامل دیتابیس', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 12),
                      const Text('اگر با خطای دیتابیس مواجه هستید، این گزینه را بزنید. فایل دیتابیس حذف و از صفر ساخته می‌شود.', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                          onPressed: _resetDatabaseCompletely,
                          icon: const Icon(Icons.refresh),
                          label: const Text('بازنشانی دیتابیس', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // کارت پاک کردن لایسنس قبلی
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.key_off, color: Colors.purple), SizedBox(width: 8), Text('پاک کردن لایسنس قبلی', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 12),
                      const Text('اگر لایسنس قدیمی ذخیره شده و نمی‌خواهید آن را استفاده کنید، این دکمه را بزنید.', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => Directionality(
                                textDirection: TextDirection.rtl,
                                child: AlertDialog(
                                  backgroundColor: AppTheme.cardBlack,
                                  title: const Text('تایید پاک کردن لایسنس', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                                  content: const Text('آیا مطمئن هستید که می‌خواهید لایسنس فعلی را پاک کنید؟', style: TextStyle(color: AppTheme.textWhite)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('بله، پاک کن', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              ),
                            );
                            if (confirm == true) {
                              await LicenseHelper.clearLicense();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ لایسنس پاک شد. برنامه را ببندید و دوباره باز کنید.'), backgroundColor: Colors.green, duration: Duration(seconds: 3)));
                            }
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('پاک کردن لایسنس', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // کارت حذف کامل اطلاعات
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.delete_forever, color: Colors.red), SizedBox(width: 8), Text('حذف کامل اطلاعات', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 12),
                      const Text('این عمل تمام اطلاعات را برای همیشه پاک می‌کند.', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: _resetDatabase,
                          icon: const Icon(Icons.delete),
                          label: const Text('حذف همه اطلاعات', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // کارت خروج
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 8), Text('خروج از حساب', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: _logout,
                          icon: const Icon(Icons.exit_to_app),
                          label: const Text('خروج', style: TextStyle(fontWeight: FontWeight.bold)),
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