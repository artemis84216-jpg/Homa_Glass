import 'package:flutter/material.dart';
import 'dart:io';
import 'database_helper.dart';
import 'app_utils.dart';
import 'image_helper.dart';

class GeneralInfoScreen extends StatefulWidget {
  const GeneralInfoScreen({super.key});
  @override
  State<GeneralInfoScreen> createState() => _GeneralInfoScreenState();
}

class _GeneralInfoScreenState extends State<GeneralInfoScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadItems(); }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllGeneralInfo();
    setState(() { _items = data; _isLoading = false; });
  }

  void _showDetail(Map<String, dynamic> item) {
    final List<String> images = parseImagesHelper(item['image_paths']);
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: AppTheme.cardBlack,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item['title'] ?? '', style: const TextStyle(color: AppTheme.yellow, fontSize: 18, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.close, color: AppTheme.textGrey), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(color: AppTheme.yellow),
                if (images.isNotEmpty) ...[
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(images[index]), width: 300, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(item['content'] ?? '', style: const TextStyle(color: AppTheme.textWhite, height: 1.8, fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('اطلاعات عمومی و سلامت چشم'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.yellow), onPressed: _loadItems)]),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.yellow)) : _items.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.library_books, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('مقاله‌ای یافت نشد', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) : ListView.builder(
        padding: const EdgeInsets.all(12), itemCount: _items.length,
        itemBuilder: (context, index) {
          final i = _items[index];
          final List<String> images = parseImagesHelper(i['image_paths']);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _showDetail(i),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.library_books, color: AppTheme.yellow, size: 24),
                    const SizedBox(width: 8),
                    Expanded(child: Text(i['title'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold))),
                  ]),
                  if (images.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(height: 150, width: double.infinity, child: Image.file(File(images.first), fit: BoxFit.cover)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(i['content'] ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textGrey, height: 1.6)),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}