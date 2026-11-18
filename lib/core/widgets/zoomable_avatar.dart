import 'package:flutter/material.dart';

class ZoomableAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String fallbackText;

  const ZoomableAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24.0,
    this.fallbackText = 'U',
  });

  void _showZoomedImage(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.8,
          maxScale: 4.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _fallbackWidget(size: 150),
                  )
                : _fallbackWidget(size: 150),
          ),
        ),
      ),
    );
  }

  Widget _fallbackWidget({double size = 48}) {
    return Container(
      width: size,
      height: size,
      color: Colors.green.shade100,
      alignment: Alignment.center,
      child: Text(
        fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : 'U',
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showZoomedImage(context),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.green.shade100,
        backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty) ? NetworkImage(imageUrl!) : null,
        child: (imageUrl == null || imageUrl!.isEmpty) ? _fallbackWidget(size: radius * 2) : null,
      ),
    );
  }
}
