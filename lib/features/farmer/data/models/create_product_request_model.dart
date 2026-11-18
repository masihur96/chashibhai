class CreateProductRequestModel {
  final String productName;
  final double quantity;
  final String unit;
  final double minimumPrice;
  final String tradeType;
  final String category;
  final DateTime startTime;
  final DateTime endTime;
  final String imageUrl;

  const CreateProductRequestModel({
    required this.productName,
    required this.quantity,
    this.unit = 'KG',
    required this.minimumPrice,
    this.tradeType = 'both',
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    final startTimeIso = startTime.toUtc().toIso8601String();
    final endTimeIso = endTime.toUtc().toIso8601String();

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
      'startTime': startTimeIso,
      'start_time': startTimeIso,
      'endTime': endTimeIso,
      'end_time': endTimeIso,
      'imageUrl': imageUrl,
      'image_url': imageUrl,
    };
  }

  factory CreateProductRequestModel.fromJson(Map<String, dynamic> json) {
    return CreateProductRequestModel(
      productName: (json['productName'] ?? json['product_name'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: (json['unit'] ?? 'KG').toString(),
      minimumPrice: ((json['minimumPrice'] ?? json['minimum_price']) as num?)?.toDouble() ?? 0.0,
      tradeType: (json['tradeType'] ?? json['trade_type'] ?? 'both').toString(),
      category: (json['category'] ?? '').toString(),
      startTime: DateTime.tryParse((json['startTime'] ?? json['start_time'])?.toString() ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse((json['endTime'] ?? json['end_time'])?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 7)),
      imageUrl: (json['imageUrl'] ?? json['image_url'] ?? '').toString(),
    );
  }
}
