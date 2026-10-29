import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';
import 'license_manager.dart';
import 'app_utils.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadEmployees(); }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseHelper.instance.getAllEmployees();
      if (mounted) setState(() { _employees = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'optometrist': return 'اپتومتریست';
      case 'seller': return 'فروشنده';
      case 'technician': return 'تکنسین ساخت';
      default: return role;
    }
  }

  Future<void> _showEmployeeDialog({Map<String, dynamic>? emp}) async {
    final isEdit = emp != null;
    
    if (!isEdit) {
      final check = await LicenseManager.canAddEmployee();
      if (!check['allowed']) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: AppTheme.cardBlack,
                title: const Row(children: [Icon(Icons.lock, color: Colors.red, size: 28), SizedBox(width: 8), Text('محدودیت پلن', style: TextStyle(color: Colors.red))]),
                content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(check['message'] ?? 'امکان ثبت کارمند جدید وجود ندارد', style: const TextStyle(color: AppTheme.textWhite)),
                  const SizedBox(height: 12),
                  const Text('برای افزایش سقف کارمندان، پلن خود را ارتقا دهید.', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                ]),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('متوجه شدم', style: TextStyle(color: AppTheme.yellow)))],
              ),
            ),
          );
        }
        return;
      }
    }

    final nameController = TextEditingController(text: emp?['name']?.toString() ?? '');
    final phoneController = TextEditingController(text: emp?['phone']?.toString() ?? '');
    final passwordController = TextEditingController(text: emp?['password']?.toString() ?? '');
    final salaryController = TextEditingController(text: (emp?['base_salary'] ?? 0).toInt().toString());
    final commissionController = TextEditingController(text: (emp?['commission_rate'] ?? 0).toString());
    String role = emp?['role']?.toString() ?? 'seller';
    String status = emp?['status']?.toString() ?? 'active';
    bool obscurePassword = true;

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: Text(isEdit ? 'ویرایش کارمند' : 'افزودن کارمند جدید', style: const TextStyle(color: AppTheme.yellow)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام و نام خانوادگی *', prefixIcon: Icon(Icons.person, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                TextField(controller: phoneController, keyboardType: TextInputType.phone, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'شماره تماس', prefixIcon: Icon(Icons.phone, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: InputDecoration(
                    labelText: 'رمز عبور *',
                    prefixIcon: const Icon(Icons.lock, color: AppTheme.yellow),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.yellow),
                      onPressed: () => setStateDialog(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  dropdownColor: AppTheme.cardBlack,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(labelText: 'نقش', prefixIcon: Icon(Icons.badge, color: AppTheme.yellow)),
                  items: const [
                    DropdownMenuItem(value: 'optometrist', child: Text('اپتومتریست')),
                    DropdownMenuItem(value: 'seller', child: Text('فروشنده')),
                    DropdownMenuItem(value: 'technician', child: Text('تکنسین ساخت')),
                  ],
                  onChanged: (v) => setStateDialog(() => role = v!),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: salaryController, keyboardType: TextInputType.number, inputFormatters: [CommaSeparatorFormatter()], style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'حقوق پایه', prefixIcon: Icon(Icons.attach_money, color: AppTheme.yellow)))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: commissionController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'کمیسیون %', prefixIcon: Icon(Icons.percent, color: AppTheme.yellow)))),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  dropdownColor: AppTheme.cardBlack,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(labelText: 'وضعیت', prefixIcon: Icon(Icons.toggle_on, color: AppTheme.yellow)),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('فعال')),
                    DropdownMenuItem(value: 'inactive', child: Text('غیرفعال')),
                  ],
                  onChanged: (v) => setStateDialog(() => status = v!),
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, foregroundColor: Colors.black),
                onPressed: () async {
                  if (nameController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام و رمز عبور الزامی است'), backgroundColor: Colors.red));
                    return;
                  }
                  try {
                    final data = {
                      'name': nameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'password': passwordController.text.trim(),
                      'role': role,
                      'commission_rate': double.tryParse(commissionController.text) ?? 0,
                      'base_salary': double.tryParse(toEnglishDigits(salaryController.text.replaceAll(',', ''))) ?? 0,
                      'status': status,
                      'created_at': getCurrentJalaliDateTime(),
                    };
                    if (isEdit) {
                      await DatabaseHelper.instance.updateEmployee(emp!['id'], data);
                    } else {
                      await DatabaseHelper.instance.insertEmployee(data);
                    }
                    Navigator.pop(ctx);
                    _loadEmployees();
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

  Future<void> _deleteEmployee(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('تایید حذف', style: TextStyle(color: AppTheme.yellow)), content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))])));
    if (confirm == true) {
      await DatabaseHelper.instance.deleteEmployee(id);
      _loadEmployees();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('کارمندان'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.yellow), onPressed: _loadEmployees)]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.yellow))
          : _employees.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('کارمندی ثبت نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))]))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _employees.length,
                  itemBuilder: (context, index) {
                    final emp = _employees[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: AppTheme.yellow.withOpacity(0.2), child: Icon(Icons.person, color: AppTheme.yellow)),
                        title: Text(emp['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${_getRoleText(emp['role'] ?? '')} | 📞 ${emp['phone'] ?? '-'}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                          Text('حقوق: ${formatPrice(emp['base_salary'])} | کمیسیون: ${emp['commission_rate']}٪', style: const TextStyle(color: AppTheme.textYellow, fontSize: 12)),
                        ]),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit, color: AppTheme.yellow), onPressed: () => _showEmployeeDialog(emp: emp)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteEmployee(emp['id'])),
                        ]),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEmployeeDialog(),
        backgroundColor: AppTheme.yellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('افزودن کارمند'),
      ),
    );
  }
}