import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<List<String>> savePickedImages(List<XFile> picked) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/glass_images');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  List<String> savedPaths = [];
  for (int i = 0; i < picked.length; i++) {
    try {
      final fileName = 'img_${DateTime.now().microsecondsSinceEpoch}_$i.jpg';
      final target = File('${dir.path}/$fileName');
      await File(picked[i].path).copy(target.path);
      savedPaths.add(target.path);
    } catch (e) {
      // اگر کپی موفق نبود، از مسیر اصلی استفاده می‌کنیم
      savedPaths.add(picked[i].path);
    }
  }
  return savedPaths;
}

List<String> parseImagesHelper(dynamic value) {
  if (value == null) return [];
  
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  
  if (value is String) {
    if (value.trim().isEmpty) return [];
    
    // فرمت جدید: جدا شده با |
    if (value.contains('|')) {
      return value.split('|').where((e) => e.trim().isNotEmpty).toList();
    }
    
    // فرمت JSON قدیمی
    if (value.trim().startsWith('[')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    
    // فرمت تک عکس قدیمی
    return [value];
  }
  
  return [];
}