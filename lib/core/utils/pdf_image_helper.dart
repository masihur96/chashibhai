import 'dart:typed_data';
import 'package:flutter/services.dart';

class PdfImageHelper {
  PdfImageHelper._();

  /// Loads an asset image as Uint8List for PDF rendering
  static Future<Uint8List> loadAssetImage(String assetPath) async {
    final ByteData byteData = await rootBundle.load(assetPath);
    return byteData.buffer.asUint8List();
  }
}
