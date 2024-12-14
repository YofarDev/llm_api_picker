import 'dart:io';
import 'dart:typed_data';

class Utils {
  static String getMimeType(String path) {
    final String extension = path.split('.').last;
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'jpg':
        return 'image/jpeg';
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  static Future<Uint8List> getBytesFromFile(String filePath) async {
    final File file = File(filePath);
    return file.readAsBytes();
  }
}
