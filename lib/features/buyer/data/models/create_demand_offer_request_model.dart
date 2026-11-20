class CreateDemandOfferRequestModel {
  final double offerPrice;
  final String? note;

  CreateDemandOfferRequestModel({
    required this.offerPrice,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'offerPrice': offerPrice,
      'offer_price': offerPrice,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }

  factory CreateDemandOfferRequestModel.fromJson(Map<String, dynamic> json) {
    return CreateDemandOfferRequestModel(
      offerPrice: (json['offerPrice'] ?? json['offer_price'] is num)
          ? (json['offerPrice'] ?? json['offer_price']).toDouble()
          : (double.tryParse((json['offerPrice'] ?? json['offer_price'])?.toString() ?? '0') ?? 0.0),
      note: json['note']?.toString(),
    );
  }
}
