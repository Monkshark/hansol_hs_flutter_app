import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageUtils {
  static Future<File?> compress(File file, {int minWidth = 1080, int quality = 80}) async {
    final dir = await getTemporaryDirectory();
    final targetPath = p.join(
      dir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}_${p.basenameWithoutExtension(file.path)}.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: minWidth,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );

    return result != null ? File(result.path) : null;
  }

  static Future<List<String>> uploadPostImages(List<File> images, String postId) async {
    final urls = <String>[];
    final storage = FirebaseStorage.instance;

    for (int i = 0; i < images.length; i++) {
      final ref = storage.ref('posts/$postId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
      await ref.putFile(images[i]);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }
}
