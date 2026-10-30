import 'dart:io';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<List<String>> savePickedImages(List<XFile> picked) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/glass_images');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  List<String> savedPaths = [];
  final random = Random();
  
  for (int i = 0; i < picked.length; i++) {
    try {
      // استفاده از microseconds + random برای اطمینان از یکتا بودن نام فایل
      final uniqueId = '${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(99999)}_$i';
      final fileName = 'img_$uniqueId.jpg';
      final target = File('${dir.path}/$fileName');
      await File(picked[i].path).copy(target.path);
      savedPaths.add(target.path);
    } catch (e) {
      // اگر کپی نشد، همان مسیر موقت را نگه دار
      savedPaths.add(picked[i].path);
    }
  }
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