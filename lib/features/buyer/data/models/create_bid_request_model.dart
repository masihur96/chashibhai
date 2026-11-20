class CreateBidRequestModel {
  final String productId;
  final double amount;

  const CreateBidRequestModel({
    required this.productId,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'product_id': productId,
      'amount': amount,
    };
  }

  factory CreateBidRequestModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return CreateBidRequestModel(
      productId: (json['productId'] ?? json['product_id'] ?? '').toString(),
      amount: parseDouble(json['amount']),
    );
  }
}
