import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class LensesScreen extends StatefulWidget {
  const LensesScreen({super.key});
  @override
  State<LensesScreen> createState() => _LensesScreenState();
}

class _LensesScreenState extends State<LensesScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() { super.initState(); _loadItems(); }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllLenses();
    setState(() { _items = data; _filtered = data; _isLoading = false; });
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) { _filtered = _items; } 
      else {
        _filtered = _items.where((i) => (i['name'] ?? '').toLowerCase().contains(query.toLowerCase()) || (i['brand'] ?? '').toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  Future<void> _showDialog({Map<String, dynamic>? item}) async {
    final isEdit = item != null;
    final nameController = TextEditingController(text: item?['name']?.toString() ?? '');
    final brandController = TextEditingController(text: item?['brand']?.toString() ?? '');
    final costController = TextEditingController(text: (item?['cost_price'] ?? 0).toInt().toString());
    final sellController = TextEditingController(text: (item?['sell_price'] ?? 0).toInt().toString());
    final stockController = TextEditingController(text: (item?['stock_quantity'] ?? 0).toString());
    String type = item?['type']?.toString() ?? lensTypes.first;
    String index = item?['lens_index']?.toString() ?? lensIndexes.first;
    String features = item?['features']?.toString() ?? '';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: Text(isEdit ? 'ویرایش عدسی' : 'افزودن عدسی جدید', style: const TextStyle(color: AppTheme.yellow)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام عدسی *', prefixIcon: Icon(Icons.lens_blur, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                TextField(controller: brandController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'برند', prefixIcon: Icon(Icons.business, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<String>(value: type, dropdownColor: AppTheme.cardBlack, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نوع', prefixIcon: Icon(Icons.category, color: AppTheme.yellow)), items: lensTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setStateDialog(() => type = v!))),
                  const SizedBox(width: 8),
                  Expanded(child: DropdownButtonFormField<String>(value: index, dropdownColor: AppTheme.cardBlack, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'ایندکس', prefixIcon: Icon(Icons.straighten, color: AppTheme.yellow)), items: lensIndexes.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(), onChanged: (v) => setStateDialog(() => index = v!))),
                ]),
                const SizedBox(height: 12),
                TextField(controller: TextEditingController(text: features), onChanged: (v) => features = v, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'ویژگی‌ها (مثال: بلوکات، آنتی‌رفلکس)', prefixIcon: Icon(Icons.star, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: costController, keyboardType: TextInputType.number, inputFormatters: [CommaSeparatorFormatter()], style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'قیمت خرید', prefixIcon: Icon(Icons.attach_money, color: AppTheme.yellow)))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: sellController, keyboardType: TextInputType.number, inputFormatters: [CommaSeparatorFormatter()], style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'قیمت فروش', prefixIcon: Icon(Icons.attach_money, color: AppTheme.yellow)))),
                ]),
                const SizedBox(height: 12),
                TextField(controller: stockController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'موجودی انبار', prefixIcon: Icon(Icons.inventory, color: AppTheme.yellow))),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, foregroundColor: Colors.black),
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام عدسی الزامی است'), backgroundColor: Colors.red));
                    return;
                  }
                  final data = {
                    'name': nameController.text.trim(), 'brand': brandController.text.trim(), 'type': type,
                    'lens_index': index, 'features': features,
                    'cost_price': double.tryParse(toEnglishDigits(costController.text.replaceAll(',', ''))) ?? 0,
                    'sell_price': double.tryParse(toEnglishDigits(sellController.text.replaceAll(',', ''))) ?? 0,
                    'stock_quantity': int.tryParse(toEnglishDigits(stockController.text)) ?? 0,
                    'created_at': getCurrentJalaliDateTime(),
                  };
                  if (isEdit) { await DatabaseHelper.instance.updateLens(item!['id'], data); } 
                  else { await DatabaseHelper.instance.insertLens(data); }
                  Navigator.pop(ctx);
                  _loadItems();
                },
                child: Text(isEdit ? 'ذخیره' : 'افزودن', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItem(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('تایید حذف', style: TextStyle(color: AppTheme.yellow)), content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))])));
    if (confirm == true) { await DatabaseHelper.instance.deleteLens(id); _loadItems(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('مدیریت عدسی‌ها'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.yellow), onPressed: _loadItems)]),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _searchController, style: const TextStyle(color: AppTheme.textWhite), decoration: InputDecoration(hintText: 'جستجو در نام یا برند...', prefixIcon: const Icon(Icons.search, color: AppTheme.yellow), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.yellow), onPressed: () { _searchController.clear(); _filter(''); }) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: _filter)),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.yellow)) : _filtered.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lens_blur, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('عدسی‌ای یافت نشد', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) : ListView.builder(
              padding: const EdgeInsets.all(12), itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final i = _filtered[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: AppTheme.yellow.withOpacity(0.2), child: const Icon(Icons.lens_blur, color: AppTheme.yellow)),
                    title: Text(i['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${i['brand'] ?? ''} | ایندکس: ${i['lens_index'] ?? '-'} | ${i['type'] ?? ''}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                      Text('موجودی: ${formatNumber(i['stock_quantity'] ?? 0)} | فروش: ${formatPrice(i['sell_price'])} تومان', style: const TextStyle(color: AppTheme.textYellow, fontSize: 12)),
                    ]),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit, color: AppTheme.yellow), onPressed: () => _showDialog(item: i)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteItem(i['id'])),
                    ]),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showDialog(), backgroundColor: AppTheme.yellow, foregroundColor: Colors.black, icon: const Icon(Icons.add), label: const Text('افزودن عدسی')),
    );
  }
}