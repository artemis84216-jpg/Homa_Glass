import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'database_helper.dart';
import 'app_utils.dart';
import 'image_helper.dart';

class GeneralInfoDevScreen extends StatefulWidget {
  const GeneralInfoDevScreen({super.key});
  @override
  State<GeneralInfoDevScreen> createState() => _GeneralInfoDevScreenState();
}

class _GeneralInfoDevScreenState extends State<GeneralInfoDevScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() { super.initState(); _loadItems(); }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseHelper.instance.getAllGeneralInfo();
      if (mounted) setState(() { _items = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    final file = File(imagePath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فایل عکس یافت نشد'), backgroundColor: Colors.red));
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
    final titleController = TextEditingController(text: item?['title']?.toString() ?? '');
    final contentController = TextEditingController(text: item?['content']?.toString() ?? '');
    String? imagePathsJson = item?['image_paths'];

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) {
            List<String> currentImages = parseImagesHelper(imagePathsJson);
            
            return AlertDialog(
              backgroundColor: AppTheme.cardBlack,
              title: Text(isEdit ? 'ویرایش مقاله' : 'افزودن مقاله جدید', style: const TextStyle(color: AppTheme.yellow)),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: titleController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'عنوان مقاله *', prefixIcon: Icon(Icons.title, color: AppTheme.yellow))),
                  const SizedBox(height: 12),
                  TextField(controller: contentController, maxLines: 6, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'متن کامل مقاله *', prefixIcon: Icon(Icons.description, color: AppTheme.yellow))),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final List<XFile>? images = await _picker.pickMultiImage();
                      if (images != null && images.isNotEmpty) {
                        final saved = await savePickedImages(images);
                        setStateDialog(() => currentImages = saved);
                      }
                    },
                    icon: const Icon(Icons.image, color: AppTheme.yellow),
                    label: const Text('انتخاب عکس (چندتایی)', style: TextStyle(color: AppTheme.textWhite)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardBlack, side: const BorderSide(color: AppTheme.yellow)),
                  ),
                  if (currentImages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: currentImages.map((path) => GestureDetector(
                        onTap: () => _showFullScreenImage(ctx, path),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 80, height: 80,
                            child: Image.file(File(path), fit: BoxFit.cover),
                          ),
                        ),
                      )).toList(),
                    ),
                  ]
                ]),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.yellow, foregroundColor: Colors.black),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عنوان و متن الزامی است'), backgroundColor: Colors.red));
                      return;
                    }
                    try {
                      final data = {
                        'title': titleController.text.trim(),
                        'content': contentController.text.trim(),
                        'image_paths': currentImages.isNotEmpty ? currentImages.join('|') : null,
                        'created_at': getCurrentJalaliDateTime(),
                      };
                      if (isEdit) { 
                        await DatabaseHelper.instance.updateGeneralInfo(item!['id'], data); 
                      } else { 
                        await DatabaseHelper.instance.insertGeneralInfo(data); 
                      }
                      Navigator.pop(ctx);
                      _loadItems();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
                    }
                  },
                  child: Text(isEdit ? 'ذخیره' : 'افزودن', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteItem(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('تایید حذف', style: TextStyle(color: AppTheme.yellow)), content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))])));
    if (confirm == true) { 
      await DatabaseHelper.instance.deleteGeneralInfo(id); 
      _loadItems(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('مدیریت اطلاعات عمومی'), centerTitle: true),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.yellow)) 
        : _items.isEmpty 
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.library_books, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('مقاله‌ای ثبت نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) 
          : ListView.builder(
              padding: const EdgeInsets.all(12), itemCount: _items.length,
              itemBuilder: (context, index) {
                final i = _items[index];
                final List<String> images = parseImagesHelper(i['image_paths']);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: images.isNotEmpty 
                        ? GestureDetector(
                            onTap: () => _showFullScreenImage(context, images.first),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 50, height: 50,
                                child: Image.file(File(images.first), fit: BoxFit.cover),
                              ),
                            ),
                          ) 
                        : CircleAvatar(backgroundColor: AppTheme.yellow.withOpacity(0.2), child: const Icon(Icons.library_books, color: AppTheme.yellow)),
                    title: Text(i['title'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${toPersianDigits(images.length.toString())} عکس | ${i['created_at'] ?? ''}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                      if (images.length > 1) Text('و ${toPersianDigits((images.length - 1).toString())} عکس دیگر', style: const TextStyle(color: AppTheme.textGrey, fontSize: 11, fontStyle: FontStyle.italic)),
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
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showDialog(), backgroundColor: AppTheme.yellow, foregroundColor: Colors.black, icon: const Icon(Icons.add), label: const Text('افزودن مقاله')),
    );
  }
}