import 'dart:io';
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
      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final target = File('${dir.path}/$fileName');
      await File(picked[i].path).copy(target.path);
      savedPaths.add(target.path);
    } catch (e) {
      // اگر کپی نشد، همان مسیر موقت را نگه دار (حداقل در همان جلسه کار می‌کند)
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