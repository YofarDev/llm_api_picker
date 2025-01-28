import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';

class Utils {
  static String getMimeType(String path) {
    return lookupMimeType(path) ?? 'image/jpeg';
  }

  static Future<Uint8List> getBytesFromFile(String filePath) async {
    final File file = File(filePath);
    return file.readAsBytes();
  }
}
