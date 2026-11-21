class CreateGroupRequestModel {
  final String name;
  final String productName;
  final String category;
  final double targetQuantity;
  final double pricePerKg;
  final String deliveryLocation;
  final DateTime expiryDate;
  final double initialContribution;

  const CreateGroupRequestModel({
    required this.name,
    required this.productName,
    required this.category,
    required this.targetQuantity,
    required this.pricePerKg,
    required this.deliveryLocation,
    required this.expiryDate,
    required this.initialContribution,
  });

  Map<String, dynamic> toJson() {
    final cat = category.toLowerCase().trim();
    final expiryUtc = expiryDate.toUtc().toIso8601String();
    final targetNum = targetQuantity == targetQuantity.roundToDouble()
        ? targetQuantity.toInt()
        : targetQuantity;
    final priceNum = pricePerKg == pricePerKg.roundToDouble()
        ? pricePerKg.toInt()
        : pricePerKg;
    final initContribNum = initialContribution == initialContribution.roundToDouble()
        ? initialContribution.toInt()
        : initialContribution;

    return {
      'name': name.trim(),
      'productName': productName.trim(),
      'product_name': productName.trim(),
      'category': cat,
      'targetQuantity': targetNum,
      'target_quantity': targetNum,
      'pricePerKg': priceNum,
      'price_per_kg': priceNum,
      'deliveryLocation': deliveryLocation.trim(),
      'delivery_location': deliveryLocation.trim(),
      'expiryDate': expiryUtc,
      'expiry_date': expiryUtc,
      'initialContribution': initContribNum,
      'initial_contribution': initContribNum,
    };
  }
}
