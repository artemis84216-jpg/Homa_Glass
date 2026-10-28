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
    try {
      final data = await DatabaseHelper.instance.getAllSunglasses();
      if (mounted) {
        setState(() { _items = data; _filtered = data; _isLoading = false; });
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
      if (query.isEmpty) { _filtered = _items; } 
      else {
        _filtered = _items.where((i) => (i['name'] ?? '').toLowerCase().contains(query.toLowerCase()) || (i['brand'] ?? '').toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    final file = File(imagePath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فایل عکس یافت نشد'), backgroundColor: Colors.red),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: InteractiveViewer(
            panEnabled: true, boundaryMargin: const EdgeInsets.all(20), minScale: 0.5, maxScale: 4.0,
            child: Image.file(file, fit: BoxFit.contain),
          ),
        ),
      ),
    );
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
    String? imagePathsJson = item?['image_path'];

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) {
            List<String> currentImages = parseImagesHelper(imagePathsJson);
            
            return AlertDialog(
              backgroundColor: AppTheme.cardBlack,
              title: Text(isEdit ? 'ویرایش عینک آفتابی' : 'افزودن عینک آفتابی جدید', style: const TextStyle(color: AppTheme.yellow)),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام عینک *', prefixIcon: Icon(Icons.wb_sunny, color: AppTheme.yellow))),
                  const SizedBox(height: 12),
                  TextField(controller: brandController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'برند