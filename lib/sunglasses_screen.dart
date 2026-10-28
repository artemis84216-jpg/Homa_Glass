import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'database_helper.dart';
import 'app_utils.dart';
import 'image_helper.dart';

class SunglassesScreen extends StatefulWidget {
  const SunglassesScreen({super.key});
  @override
  State<SunglassesScreen> createState() => _SunglassesScreenState();
}

class _SunglassesScreenState extends State<SunglassesScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() { super.initState(); _loadItems(); }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllSunglasses();
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
    final modelController = TextEditingController(text: item?['model']?.toString() ?? '');
    final colorController = TextEditingController(text: item?['color']?.toString() ?? '');
    final uvController = TextEditingController(text: item?['uv_protection']?.toString() ?? 'UV400');
    final costController = TextEditingController(text: (item?['cost_price'] ?? 0).toInt().toString());
    final sellController = TextEditingController(text: (item?['sell_price'] ?? 0).toInt().toString());
    final stockController = TextEditingController(text: (item?['stock_quantity'] ?? 0).toString());
    String? imagePath = item?['image_path'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: Text(isEdit ? 'ویرایش عینک آفتابی' : 'افزودن عینک آفتابی جدید', style: const TextStyle(color: AppTheme.yellow)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام عینک *', prefixIcon: Icon(Icons.wb_sunny, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                TextField(controller: brandController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'برند', prefixIcon: Icon(Icons.business, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: modelController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'مدل', prefixIcon: Icon(Icons.category, color: AppTheme.yellow)))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: colorController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'رنگ', prefixIcon: Icon(Icons.color_lens, color: AppTheme.yellow)))),
                ]),
                const SizedBox(height: 12),
                TextField(controller: uvController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'محافظت UV', prefixIcon: Icon(Icons.shield, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: costController, keyboardType: TextInputType.number, inputFormatters: [CommaSeparatorFormatter()], style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'قیمت خرید', prefixIcon: Icon(Icons.attach_money, color: AppTheme.yellow)))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: sellController, keyboardType: TextInputType.number, inputFormatters: [CommaSeparatorFormatter()], style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'قیمت فروش', prefixIcon: Icon(Icons.attach_money, color: AppTheme.yellow)))),
                ]),
                const SizedBox(height: 12),
                TextField(controller: stockController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'موجودی انبار', prefixIcon: Icon(Icons.inventory, color: AppTheme.yellow))),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final images = await _picker.pickMultiImage();
                    if (images != null && images.isNotEmpty) {
                      final saved = await savePickedImages(images);
                      setStateDialog(() => imagePath = saved.join('|'));
                    }
                  },
                  icon: const Icon(Icons.image, color: AppTheme.yellow),
                  label: const Text('انتخاب عکس', style: TextStyle(color: AppTheme.textWhite)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardBlack, side: const BorderSide(color: AppTheme.yellow)),
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, foregroundColor: Colors.black),
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام عینک الزامی است'), backgroundColor: Colors.red));
                    return;
                  }
                  final data = {
                    'name': nameController.text.trim(), 'brand': brandController.text.trim(), 'model': modelController.text.trim(),
                    'color': colorController.text.trim(), 'uv_protection': uvController.text.trim(),
                    'cost_price': double.tryParse(toEnglishDigits(costController.text.replaceAll(',', ''))) ?? 0,
                    'sell_price': double.tryParse(toEnglishDigits(sellController.text.replaceAll(',', ''))) ?? 0,
                    'stock_quantity': int.tryParse(toEnglishDigits(stockController.text)) ?? 0,
                    'image_path': imagePath, 'created_at': getCurrentJalaliDateTime(),
                  };
                  if (isEdit) { await DatabaseHelper.instance.updateSunglass(item!['id'], data); } 
                  else { await DatabaseHelper.instance.insertSunglass(data); }
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
    if (confirm == true) { await DatabaseHelper.instance.deleteSunglass(id); _loadItems(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('عینک‌های آفتابی'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.yellow), onPressed: _loadItems)]),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _searchController, style: const TextStyle(color: AppTheme.textWhite), decoration: InputDecoration(hintText: 'جستجو در نام یا برند...', prefixIcon: const Icon(Icons.search, color: AppTheme.yellow), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.yellow), onPressed: () { _searchController.clear(); _filter(''); }) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: _filter)),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.yellow)) : _filtered.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.wb_sunny, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('عینکی یافت نشد', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) : ListView.builder(
              padding: const EdgeInsets.all(12), itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final i = _filtered[index];
                final images = parseImagesHelper(i['image_path']);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: images.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 50, height: 50, child: Image.file(File(images.first), fit: BoxFit.cover))) : CircleAvatar(backgroundColor: AppTheme.yellow.withOpacity(0.2), child: const Icon(Icons.wb_sunny, color: AppTheme.yellow)),
                    title: Text(i['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${i['brand'] ?? ''} | ${i['model'] ?? ''} | ${i['color'] ?? ''}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
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
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showDialog(), backgroundColor: AppTheme.yellow, foregroundColor: Colors.black, icon: const Icon(Icons.add), label: const Text('افزودن عینک')),
    );
  }
}