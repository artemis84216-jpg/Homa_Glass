import 'package:flutter/material.dart';
import 'app_utils.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('گزارشات'), centerTitle: true),
      body: const Center(child: Text('در فاز ۵ تکمیل می‌شود', style: TextStyle(color: AppTheme.textGrey))),
    );
  }
}