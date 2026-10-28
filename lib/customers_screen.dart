import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() { super.initState(); _loadCustomers(); }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseHelper.instance.getAllCustomers();
      if (mounted) {
        setState(() { 
          _customers = data; 
          _filtered = data; 
          _isLoading = false; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) { _filtered = _customers; } 
      else {
        _filtered = _customers.where((c) => 
          (c['name'] ?? '').toLowerCase().contains(query.toLowerCase()) || 
          (c['phone'] ?? '').contains(query) || 
          (c['national_id'] ?? '').contains(query)
        ).toList();
      }
    });
  }

  Future<void> _showCustomerDialog({Map<String, dynamic>? customer}) async {
    final isEdit = customer != null;
    final nameController = TextEditingController(text: customer?['name']?.toString() ?? '');
    final phoneController = TextEditingController(text: customer?['phone']?.toString() ?? '');
    final nationalIdController = TextEditingController(text: customer?['national_id']?.toString() ?? '');
    final addressController = TextEditingController(text: customer?['address']?.toString() ?? '');
    final jobController = TextEditingController(text: customer?['job']?.toString() ?? '');
    final medicalController = TextEditingController(text: customer?['medical_history']?.toString() ?? '');
    String gender = customer?['gender']?.toString() ?? 'male';

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: Text(isEdit ? 'ویرایش مشتری' : 'افزودن مشتری جدید', style: const TextStyle(color: AppTheme.yellow)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام و نام خانوادگی *', prefixIcon: Icon(Icons.person, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                TextField(controller: phoneController, keyboardType: TextInputType.phone, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'شماره تماس *', prefixIcon: Icon(Icons.phone, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                TextField(controller: nationalIdController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'کد ملی', prefixIcon: Icon(Icons.badge, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: RadioListTile<String>(title: const Text('آقا', style: TextStyle(color: AppTheme.textWhite, fontSize: 12)), value: 'male', groupValue: gender, onChanged: (v) => setStateDialog(() => gender = v!))),
                  Expanded(child: RadioListTile<String>(title: const Text('خانم', style: TextStyle(color: AppTheme.textWhite, fontSize: 12)), value: 'female', groupValue: gender, onChanged: (v) => setStateDialog(() => gender = v!))),
                ]),
                const SizedBox(height: 12),
                TextField(controller: addressController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'آدرس', prefixIcon: Icon(Icons.location_on, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                TextField(controller: jobController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'شغل', prefixIcon: Icon(Icons.work, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                TextField(controller: medicalController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'سوابق پزشکی', prefixIcon: Icon(Icons.medical_services, color: AppTheme.yellow))),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, foregroundColor: Colors.black),
                onPressed: () async {
                  if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام و شماره تماس الزامی است'), backgroundColor: Colors.red));
                    return;
                  }
                  try {
                    final data = {
                      'name': nameController.text.trim(), 'phone': phoneController.text.trim(), 
                      'national_id': nationalIdController.text.trim(), 'address': addressController.text.trim(), 
                      'gender': gender, 'job': jobController.text.trim(), 'medical_history': medicalController.text.trim(), 
                      'created_at': getCurrentJalaliDateTime(),
                    };
                    if (isEdit) { await DatabaseHelper.instance.updateCustomer(customer!['id'], data); } 
                    else { await DatabaseHelper.instance.insertCustomer(data); }
                    Navigator.pop(ctx);
                    _loadCustomers();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
                  }
                },
                child: Text(isEdit ? 'ذخیره' : 'افزودن', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCustomer(int id) async {
    final confirm = await showDialog<bool>(
      context: context, 
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl, 
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack, 
          title: const Text('تایید حذف', style: TextStyle(color: AppTheme.yellow)), 
          content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), 
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), 
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))
          ]
        )
      )
    );
    if (confirm == true) { 
      await DatabaseHelper.instance.deleteCustomer(id); 
      _loadCustomers(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('مشتریان'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.yellow), onPressed: _loadCustomers)]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController, style: const TextStyle(color: AppTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'جستجو بر اساس نام، شماره یا کد ملی...', 
                prefixIcon: const Icon(Icons.search, color: AppTheme.yellow), 
                suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.yellow), onPressed: () { _searchController.clear(); _filter(''); }) : null, 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
              ),
              onChanged: _filter,
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.yellow)) 
              : _filtered.isEmpty 
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('مشتری‌ای یافت نشد', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) 
                : ListView.builder(
                    padding: const EdgeInsets.all(12), itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final c = _filtered[index];
                      final debt = ((c['total_debt'] ?? 0) as num).toDouble();
                      final hasDebt = debt > 0;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: hasDebt ? Colors.red.withOpacity(0.2) : AppTheme.yellow.withOpacity(0.2), child: Icon(hasDebt ? Icons.warning : Icons.person, color: hasDebt ? Colors.red : AppTheme.yellow)),
                          title: Text(c['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('📞 ${c['phone'] ?? '-'} | 🆔 ${c['national_id'] ?? '-'}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                            if (hasDebt) Text('⚠️ بدهی: ${formatPrice(debt.toInt())} تومان', style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                          ]),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.edit, color: AppTheme.yellow), onPressed: () => _showCustomerDialog(customer: c)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCustomer(c['id'])),
                          ]),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerDialog(), 
        backgroundColor: AppTheme.yellow, 
        foregroundColor: Colors.black, 
        icon: const Icon(Icons.add), 
        label: const Text('افزودن مشتری')
      ),
    );
  }
}