class UpdateProductRequestModel {
  final String productName;
  final double quantity;
  final String unit;
  final double minimumPrice;
  final String tradeType;
  final String category;
  final String status;
  final DateTime startTime;
  final DateTime endTime;
  final String imageUrl;
  final List<String>? imageUrls;

  const UpdateProductRequestModel({
    required this.productName,
    required this.quantity,
    this.unit = 'KG',
    required this.minimumPrice,
    this.tradeType = 'both',
    required this.category,
    this.status = 'active',
    required this.startTime,
    required this.endTime,
    required this.imageUrl,
    this.imageUrls,
  });

  Map<String, dynamic> toJson() {
    final startTimeIso = startTime.toUtc().toIso8601String();
    final endTimeIso = endTime.toUtc().toIso8601String();

    final urls = (imageUrls != null && imageUrls!.isNotEmpty)
        ? imageUrls!
        : (imageUrl.isNotEmpty && imageUrl != 'string'
            ? [imageUrl]
            : <String>[]);

    final primaryUrl = imageUrl.isNotEmpty
        ? imageUrl
        : (urls.isNotEmpty ? urls.first : '');

    return {
      'productName': productName,
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
      'minimumPrice': minimumPrice,
      'minimum_price': minimumPrice,
      'tradeType': tradeType,
      'trade_type': tradeType,
      'category': category,
      'status': status,
      'startTime': startTimeIso,
      'start_time': startTimeIso,
      'endTime': endTimeIso,
      'end_time': endTimeIso,
      'imageUrl': primaryUrl,
      'image_url': primaryUrl,
      'imageUrls': urls,
      'image_urls': urls,
    };
  }

  factory UpdateProductRequestModel.fromJson(Map<String, dynamic> json) {
    List<String>? parsedUrls;
    if (json['imageUrls'] is List) {
      parsedUrls = (json['imageUrls'] as List).map((e) => e.toString()).toList();
    } else if (json['image_urls'] is List) {
      parsedUrls = (json['image_urls'] as List).map((e) => e.toString()).toList();
    }

    final primaryUrl = (json['imageUrl'] ??
            json['image_url'] ??
            (parsedUrls != null && parsedUrls.isNotEmpty ? parsedUrls.first : ''))
        .toString();

    return UpdateProductRequestModel(
      productName: (json['productName'] ?? json['product_name'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: (json['unit'] ?? 'KG').toString(),
      minimumPrice: ((json['minimumPrice'] ?? json['minimum_price']) as num?)?.toDouble() ?? 0.0,
      tradeType: (json['tradeType'] ?? json['trade_type'] ?? 'both').toString(),
      category: (json['category'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      startTime: DateTime.tryParse(
            (json['startTime'] ?? json['start_time'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      endTime: DateTime.tryParse(
            (json['endTime'] ?? json['end_time'])?.toString() ?? '',
          ) ??
          DateTime.now().add(const Duration(days: 7)),
      imageUrl: primaryUrl,
      imageUrls: parsedUrls,
    );
  }
}
