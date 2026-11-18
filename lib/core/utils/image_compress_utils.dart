import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class ImageCompressUtils {
  ImageCompressUtils._();

  /// Calculates target size maintaining aspect ratio
  static ({double width, double height}) calculateTargetSize(
    int originalWidth,
    int originalHeight, {
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) {
    double ratio = originalWidth / originalHeight;
    int targetWidth = originalWidth;
    int targetHeight = originalHeight;

    if (targetWidth > maxWidth) {
      targetWidth = maxWidth;
      targetHeight = (targetWidth / ratio).round();
    }
    if (targetHeight > maxHeight) {
      targetHeight = maxHeight;
      targetWidth = (targetHeight * ratio).round();
    }

    return (width: targetWidth.toDouble(), height: targetHeight.toDouble());
  }

  /// Compress image bytes (placeholder/stub)
  static Future<Uint8List?> compressBytes(Uint8List list, {int quality = 80}) async {
    debugPrint('Compressing ${list.lengthInBytes} bytes with quality $quality');
    return list;
  }
}
