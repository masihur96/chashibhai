class CreateDemandRequestModel {
  final String productName;
  final double quantity;
  final double callingPrice;
  final String deliveryLocation;
  final DateTime expiryTime;
  final String tradeType;
  final String imageUrl;

  const CreateDemandRequestModel({
    required this.productName,
    required this.quantity,
    required this.callingPrice,
    required this.deliveryLocation,
    required this.expiryTime,
    this.tradeType = 'both',
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    final expiryIso = expiryTime.toUtc().toIso8601String();

    return {
      'productName': productName,
      'product_name': productName,
      'quantity': quantity,
      'callingPrice': callingPrice,
      'calling_price': callingPrice,
      'deliveryLocation': deliveryLocation,
      'delivery_location': deliveryLocation,
      'expiryTime': expiryIso,
      'expiry_time': expiryIso,
      'tradeType': tradeType,
      'trade_type': tradeType,
      'imageUrl': imageUrl,
      'image_url': imageUrl,
    };
  }
}
