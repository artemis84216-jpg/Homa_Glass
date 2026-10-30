import 'dart:io';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<List<String>> savePickedImages(List<XFile> picked) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/glass_images');
  
  // دیباگ: نمایش مسیر پوشه
  print('📁 مسیر ذخیره عکس: ${dir.path}');
  
  if (!await dir.exists()) {
    await dir.create(recursive: true);
    print('✓ پوشه ایجاد شد');
  }

  List<String> savedPaths = [];
  final random = Random();
  
  for (int i = 0; i < picked.length; i++) {
    try {
      final uniqueId = '${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(99999)}_$i';
      final fileName = 'img_$uniqueId.jpg';
      final target = File('${dir.path}/$fileName');
      
      print('📸 در حال ذخیره عکس $i: ${picked[i].path} → ${target.path}');
      
      await File(picked[i].path).copy(target.path);
      
      if (await target.exists()) {
        savedPaths.add(target.path);
        print('✓ عکس $i با موفقیت ذخیره شد');
      } else {
        print('❌ عکس $i ذخیره نشد!');
        savedPaths.add(picked[i].path);
      }
    } catch (e) {
      print('❌ خطا در ذخیره عکس $i: $e');
      savedPaths.add(picked[i].path);
    }
  }
  
  print('🎯 تعداد عکس‌های ذخیره شده: ${savedPaths.length}');
  return savedPaths;
}

List<String> parseImagesHelper(dynamic value) {
  if (value == null) return [];
  if (value is String && value.trim().isNotEmpty) {
    return value.split('|').where((e) => e.trim().isNotEmpty).toList();
  }
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return [];
}