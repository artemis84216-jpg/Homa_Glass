import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_dashboard.dart';
import 'app_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _savedPassword = '1234';

  @override
  void initState() {
    super.initState();
    _loadPassword();
  }

  Future<void> _loadPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('glass_password');
    if (saved != null && saved.isNotEmpty) {
      setState(() => _savedPassword = saved);
    }
  }

  void _login() async {
    final pass = _passwordController.text.trim();
    if (pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز عبور را وارد کنید'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    if (pass == _savedPassword) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز عبور اشتباه است'), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBlack,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.yellow, width: 2),
                    ),
                    child: const Icon(Icons.visibility, size: 50, color: AppTheme.yellow),
                  ),
                  const SizedBox(height: 16),
                  const Text('Homa_Glass', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.yellow, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  const Text('سیستم مدیریت عینک و معاینه چشم', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(labelText: 'رمز عبور', prefixIcon: Icon(Icons.lock, color: AppTheme.yellow)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, foregroundColor: Colors.black),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text('ورود', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('رمز پیش‌فرض: 1234', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}