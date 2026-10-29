import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  Jalali? _startDate;
  Jalali? _endDate;
  String _reportType = 'all';

  double _totalSales = 0;
  double _totalExpenses = 0;
  double _totalSalaries = 0;
  int _ordersCount = 0;
  int _customersCount = 0;
  int _examsCount = 0;
  Map<String, double> _topFrames = {};
  Map<String, double> _topLenses = {};

  @override
  void initState() { super.initState(); _loadReports(); }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final startStr = _startDate != null ? '${_startDate!.year}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.day.toString().padLeft(2, '0')}' : null;
      final endStr = _endDate != null ? '${_endDate!.year}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.day.toString().padLeft(2, '0')}' : null;

      final orders = await DatabaseHelper.instance.getAllOrders();
      final filteredOrders = orders.where((o) {
        if (startStr == null || endStr == null) return true;
        final orderDate = o['order_date']?.toString() ?? '';
        return orderDate.compareTo(startStr) >= 0 && orderDate.compareTo(endStr) <= 0;
      }).toList();

      _ordersCount = filteredOrders.length;
      _totalSales = filteredOrders.fold(0.0, (sum, o) => sum + ((o['total'] ?? 0) as num).toDouble());
      _topFrames = {};
      _topLenses = {};

      for (var order in filteredOrders) {
        final frameName = order['frame_name']?.toString();
        final lensName = order['lens_name']?.toString();
        final total = (order['total'] ?? 0) as num;
        if (frameName != null && frameName.isNotEmpty) {
          _topFrames[frameName] = (_topFrames[frameName] ?? 0) + total.toDouble();
        }
        if (lensName != null && lensName.isNotEmpty) {
          _topLenses[lensName] = (_topLenses[lensName] ?? 0) + total.toDouble();
        }
      }

      final customers = await DatabaseHelper.instance.getAllCustomers();
      _customersCount = customers.length;

      final exams = await DatabaseHelper.instance.getAllEyeExams();
      _examsCount = exams.where((e) {
        if (startStr == null || endStr == null) return true;
        final examDate = e['exam_date']?.toString() ?? '';
        return examDate.compareTo(startStr) >= 0 && examDate.compareTo(endStr) <= 0;
      }).length;

      final employees = await DatabaseHelper.instance.getAllEmployees();
      _totalSalaries = employees.where((e) => e['status'] == 'active').fold(0.0, (sum, e) => sum + ((e['base_salary'] ?? 0) as num).toDouble());

      final expenses = await DatabaseHelper.instance.getExpenses(startDate: startStr, endDate: endStr);
      _totalExpenses = expenses.fold(0.0, (sum, e) => sum + ((e['amount'] ?? 0) as num).toDouble());

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ گزارشات بروزرسانی شد'), backgroundColor: AppTheme.yellow));
      }
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
      appBar: AppBar(title: const Text('گزارشات'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.yellow), onPressed: _loadReports)]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.yellow))
          : Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // فیلتر تاریخ
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        const Row(children: [Icon(Icons.filter_alt, color: AppTheme.yellow), SizedBox(width: 8), Text('فیلتر بازه زمانی', style: TextStyle(color: AppTheme.yellow, fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: OutlinedButton.icon(onPressed: () async { final p = await showPersianDatePicker(context: context, initialDate: _startDate ?? Jalali.now(), firstDate: Jalali(1400), lastDate: Jalali(1450)); if (p != null) { setState(() => _startDate = p); _loadReports(); } }, icon: const Icon(Icons.calendar_today, color: AppTheme.yellow), label: Text(_startDate != null ? '${_startDate!.year}/${_startDate!.month}/${_startDate!.day}' : 'از تاریخ', style: const TextStyle(color: AppTheme.textWhite)), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.yellow)))),
                          const SizedBox(width: 12),
                          Expanded(child: OutlinedButton.icon(onPressed: () async { final p = await showPersianDatePicker(context: context, initialDate: _endDate ?? Jalali.now(), firstDate: Jalali(1400), lastDate: Jalali(1450)); if (p != null) { setState(() => _endDate = p); _loadReports(); } }, icon: const Icon(Icons.calendar_today, color: AppTheme.yellow), label: Text(_endDate != null ? '${_endDate!.year}/${_endDate!.month}/${_endDate!.day}' : 'تا تاریخ', style: const TextStyle(color: AppTheme.textWhite)), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.yellow)))),
                        ]),
                        if (_startDate != null || _endDate != null) ...[
                          const SizedBox(height: 8),
                          TextButton(onPressed: () { setState(() { _startDate = null; _endDate = null; }); _loadReports(); }, child: const Text('حذف فیلتر', style: TextStyle(color: Colors.red))),
                        ]
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // آمار کلی
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Row(children: [Icon(Icons.bar_chart, color: AppTheme.yellow, size: 28), SizedBox(width: 8), Text('آمار کلی', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.yellow))]),
                        const Divider(height: 24),
                        _statRow('تعداد سفارشات', '${toPersianDigits(_ordersCount.toString())} سفارش', AppTheme.textWhite),
                        _statRow('تعداد معاینات', '${toPersianDigits(_examsCount.toString())} معاینه', AppTheme.textWhite),
                        _statRow('تعداد مشتریان', '${toPersianDigits(_customersCount.toString())} مشتری', AppTheme.textWhite),
                        const Divider(height: 16),
                        _statRow('کل فروش', '${formatPrice(_totalSales.toInt())} تومان', Colors.green, isLarge: true),
                        _statRow('کل هزینه‌ها', '${formatPrice(_totalExpenses.toInt())} تومان', Colors.red),
                        _statRow('کل حقوق', '${formatPrice(_totalSalaries.toInt())} تومان', Colors.orange),
                        const Divider(height: 16),
                        _statRow('سود خالص', '${formatPrice((_totalSales - _totalExpenses - _totalSalaries).toInt())} تومان', _totalSales - _totalExpenses - _totalSalaries >= 0 ? Colors.green : Colors.red, isLarge: true),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // پرفروش‌ترین فریم‌ها
                  if (_topFrames.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Row(children: [Icon(Icons.style, color: AppTheme.yellow, size: 28), SizedBox(width: 8), Text('پرفروش‌ترین فریم‌ها', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.yellow))]),
                          const SizedBox(height: 12),
                          ...(_topFrames.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5).map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: [Expanded(child: Text(e.key, style: const TextStyle(color: AppTheme.textWhite))), Text('${formatPrice(e.value.toInt())} تومان', style: const TextStyle(color: AppTheme.textYellow, fontWeight: FontWeight.bold))]),
                          )),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // پرفروش‌ترین عدسی‌ها
                  if (_topLenses.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Row(children: [Icon(Icons.lens_blur, color: AppTheme.yellow, size: 28), SizedBox(width: 8), Text('پرفروش‌ترین عدسی‌ها', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.yellow))]),
                          const SizedBox(height: 12),
                          ...(_topLenses.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5).map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: [Expanded(child: Text(e.key, style: const TextStyle(color: AppTheme.textWhite))), Text('${formatPrice(e.value.toInt())} تومان', style: const TextStyle(color: AppTheme.textYellow, fontWeight: FontWeight.bold))]),
                          )),
                        ]),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
    );
  }

  Widget _statRow(String label, String value, Color color, {bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isLarge ? 18 : 16, color: AppTheme.textGrey)),
          Text(value, style: TextStyle(fontSize: isLarge ? 20 : 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}