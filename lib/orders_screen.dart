import 'package:flutter/material.dart';
import 'app_utils.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('سفارشات'), centerTitle: true),
      body: const Center(child: Text('در فاز ۴ تکمیل می‌شود', style: TextStyle(color: AppTheme.textGrey))),
    );
  }
}