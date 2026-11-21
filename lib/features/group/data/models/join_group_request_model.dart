class JoinGroupRequestModel {
  final double quantity;

  const JoinGroupRequestModel({
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    final qtyNum = quantity == quantity.roundToDouble()
        ? quantity.toInt()
        : quantity;

    return {
      'quantity': qtyNum,
      'contributionQuantity': qtyNum,
      'contribution_quantity': qtyNum,
    };
  }
}
