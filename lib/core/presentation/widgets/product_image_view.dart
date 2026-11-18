import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProductImageView extends StatelessWidget {
  final String imageUrl;
  final Uint8List? imageBytes;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImageView({
    super.key,
    required this.imageUrl,
    this.imageBytes,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackWidget = Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          Icons.shopping_basket_outlined,
          color: Colors.grey.shade400,
          size: (height != null && height! < 50) ? 20 : 36,
        ),
      ),
    );

    Widget imageWidget;

    // 1. Direct memory bytes
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      imageWidget = Image.memory(
        imageBytes!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallbackWidget,
      );
    }
    // 2. Base64 data URI or raw base64 string
    else if (imageUrl.startsWith('data:image')) {
      try {
        final commaIndex = imageUrl.indexOf(',');
        final base64Str = commaIndex != -1 ? imageUrl.substring(commaIndex + 1) : imageUrl;
        final decodedBytes = base64Decode(base64Str.trim());
        imageWidget = Image.memory(
          decodedBytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => fallbackWidget,
        );
      } catch (_) {
        imageWidget = fallbackWidget;
      }
    }
    // 3. Network URL (http/https)
    else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      imageWidget = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallbackWidget,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade100,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }
    // 4. Local File path on device
    else if (!kIsWeb &&
        (imageUrl.startsWith('/') ||
            imageUrl.startsWith('file://') ||
            imageUrl.contains(Platform.pathSeparator))) {
      final cleanPath = imageUrl.replaceFirst('file://', '');
      final file = File(cleanPath);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => fallbackWidget,
        );
      } else {
        imageWidget = fallbackWidget;
      }
    }
    // 5. Local Asset bundled in app
    else if (imageUrl.isNotEmpty) {
      imageWidget = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallbackWidget,
      );
    } else {
      imageWidget = fallbackWidget;
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }
    return imageWidget;
  }
}
