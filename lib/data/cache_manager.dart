import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CacheManager {
  Future<double> getCurrentCacheSize() async {
    final cacheDir = await getTemporaryDirectory();
    return _getDirSize(cacheDir);
  }

  Future<double> _getDirSize(Directory dir) async {
    double size = 0;
    try {
      if (dir.existsSync()) {
        final files = dir.listSync(recursive: true, followLinks: false);
        for (var file in files) {
          if (file is File) {
            size += await file.length();
          }
        }
      }
    } catch (e) {
      print("Error calculating cache size: $e");
    }
    return size / (1024 * 1024);
  }
}
