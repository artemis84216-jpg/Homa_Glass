import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});
  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<Map<String, dynamic>> _suppliers = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadSuppliers(); }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllSuppliers();
    setState(() { _suppliers = data; _isLoading = false; });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ لیست بروزرسانی شد'), backgroundColor: AppTheme.yellow));
  }

  Future<void> _showSupplierDialog({Map<String, dynamic>? supplier}) async {
    final isEdit = supplier != null;
    final nameController = TextEditingController(text: supplier?['name']?.toString() ?? '');
    final phoneController = TextEditingController(text: supplier?['phone']?.toString() ?? '');
    final addressController = TextEditingController(text: supplier?['address']?.toString() ?? '');
    final notesController = TextEditingController(text: supplier?['notes']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: Text(isEdit ? 'ویرایش تامین‌کننده' : 'افزودن تامین‌کننده جدید', style: const TextStyle(color: AppTheme.yellow)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام شرکت / شخص *', prefixIcon: Icon(Icons.business, color: AppTheme.yellow))),
              const SizedBox(height: 12),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'شماره تماس', prefixIcon: Icon(Icons.phone, color: AppTheme.yellow))),
              const SizedBox(height: 12),
              TextField(controller: addressController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'آدرس', prefixIcon: Icon(Icons.location_on, color: AppTheme.yellow))),
              const SizedBox(height: 12),
              TextField(controller: notesController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'توضیحات', prefixIcon: Icon(Icons.notes, color: AppTheme.yellow))),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, foregroundColor: Colors.black),
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام الزامی است'), backgroundColor: Colors.red));
                  return;
                }
                final data = {'name': nameController.text.trim(), 'phone': phoneController.text.trim(), 'address': addressController.text.trim(), 'notes': notesController.text.trim(), 'created_at': getCurrentJalaliDateTime()};
                if (isEdit) { await DatabaseHelper.instance.updateSupplier(supplier!['id'], data); } 
                else { await DatabaseHelper.instance.insertSupplier(data); }
                Navigator.pop(ctx);
                _loadSuppliers();
              },
              child: Text(isEdit ? 'ذخیره' : 'افزودن', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDebtDialog(Map<String, dynamic> supplier) async {
    final currentDebt = (supplier['total_debt'] ?? 0).toDouble();
    final amountController = TextEditingController();
    final descController = TextEditingController(text: 'پرداخت بدهی');
    Jalali payDate = Jalali.now();

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: Text('پرداخت به: ${supplier['name']}', style: const TextStyle(color: AppTheme.yellow)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('بدهی فعلی به این تامین‌کننده: ${formatPrice(currentDebt.toInt())} تومان', style: const TextStyle(color: AppTheme.textWhite, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(controller: amountController, keyboardType: TextInputType.number, inputFormatters: [CommaSeparatorFormatter()], style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'مبلغ پرداختی (تومان)', prefixIcon: Icon(Icons.payments, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showPersianDatePicker(context: ctx, initialDate: payDate, firstDate: Jalali(1400), lastDate: Jalali(1450));
                    if (picked != null) setStateDialog(() => payDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today, color: AppTheme.yellow),
                  label: Text('تاریخ: ${payDate.year}/${payDate.month.toString().padLeft(2, '0')}/${payDate.day.toString().padLeft(2, '0')}', style: const TextStyle(color: AppTheme.textWhite)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.yellow)),
                ),
                const SizedBox(height: 12),
                TextField(controller: descController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'توضیحات', prefixIcon: Icon(Icons.notes, color: AppTheme.yellow))),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, foregroundColor: Colors.black),
                onPressed: () async {
                  final amount = double.tryParse(toEnglishDigits(amountController.text.replaceAll(',', ''))) ?? 0;
                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مبلغ نامعتبر است'), backgroundColor: Colors.red));
                    return;
                  }
                  final newDebt = currentDebt - amount;
                  await DatabaseHelper.instance.updateSupplier(supplier['id'], {'total_debt': newDebt});
                  await DatabaseHelper.instance.insertInstallment({
                    'type': 'supplier', 'reference_id': supplier['id'], 'amount': amount,
                    'date': '${payDate.year}/${payDate.month.toString().padLeft(2, '0')}/${payDate.day.toString().padLeft(2, '0')}',
                    'description': descController.text.trim(), 'is_paid': 1, 'created_at': getCurrentJalaliDateTime(),
                  });
                  Navigator.pop(ctx);
                  _loadSuppliers();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ پرداخت با موفقیت ثبت شد'), backgroundColor: Colors.green));
                },
                child: const Text('ثبت پرداخت', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSupplier(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('تایید حذف', style: TextStyle(color: AppTheme.yellow)), content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))])));
    if (confirm == true) { await DatabaseHelper.instance.deleteSupplier(id); _loadSuppliers(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('تامین‌کنندگان و بدهی‌ها'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.yellow), onPressed: _loadSuppliers)]),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.yellow)) : _suppliers.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.business, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('تامین‌کننده‌ای ثبت نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) : ListView.builder(
        padding: const EdgeInsets.all(12), itemCount: _suppliers.length,
        itemBuilder: (context, index) {
          final s = _suppliers[index];
          final debt = (s['total_debt'] ?? 0).toDouble();
          final hasDebt = debt > 0;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: hasDebt ? Colors.red.withOpacity(0.2) : AppTheme.yellow.withOpacity(0.2), child: Icon(hasDebt ? Icons.warning : Icons.business, color: hasDebt ? Colors.red : AppTheme.yellow)),
              title: Text(s['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('📞 ${s['phone'] ?? '-'}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                if (hasDebt) Text('⚠️ بدهی مرکز: ${formatPrice(debt.toInt())} تومان', style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
              ]),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (hasDebt) IconButton(icon: const Icon(Icons.payments, color: AppTheme.yellow), tooltip: 'ثبت پرداخت', onPressed: () => _showDebtDialog(s)),
                IconButton(icon: const Icon(Icons.edit, color: AppTheme.yellow), onPressed: () => _showSupplierDialog(supplier: s)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSupplier(s['id'])),
              ]),
              isThreeLine: true,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showSupplierDialog(), backgroundColor: AppTheme.yellow, foregroundColor: Colors.black, icon: const Icon(Icons.add), label: const Text('افزودن تامین‌کننده')),
    );
  }
}