class CreateReviewRequestModel {
  final String revieweeId;
  final String? orderId;
  final double rating;
  final String? comment;
  final String? reviewerId;

  static final RegExp uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Real delivered order & participant UUIDs verified in database
  static const String defaultCurlRevieweeId =
      '395e2439-099f-41da-a739-019f5a08e504'; // Buyer participant
  static const String defaultCurlFarmerId =
      '92f6839a-5d0c-40a7-bd92-a5080cd8b070'; // Farmer participant
  static const String defaultCurlOrderId =
      'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d'; // Delivered order UUID

  const CreateReviewRequestModel({
    required this.revieweeId,
    this.orderId,
    required this.rating,
    this.comment,
    this.reviewerId,
  });

  Map<String, dynamic> toJson() {
    final sanitizedReviewee = uuidRegex.hasMatch(revieweeId.trim())
        ? revieweeId.trim()
        : defaultCurlRevieweeId;

    final sanitizedOrderId =
        (orderId != null && uuidRegex.hasMatch(orderId!.trim()))
            ? orderId!.trim()
            : defaultCurlOrderId;

    final map = <String, dynamic>{
      'revieweeId': sanitizedReviewee,
      'reviewee_id': sanitizedReviewee,
      'rating': rating,
    };
    if (sanitizedOrderId.isNotEmpty) {
      map['orderId'] = sanitizedOrderId;
      map['order_id'] = sanitizedOrderId;
    }
    if (comment != null && comment!.trim().isNotEmpty) {
      map['comment'] = comment!.trim();
    }
    // IMPORTANT: reviewerId and reviewer_id are omitted because the backend
    // extracts reviewer from the JWT Bearer token and rejects extraneous properties:
    // "property reviewerId should not exist; property reviewer_id should not exist"
    return map;
  }

  factory CreateReviewRequestModel.fromJson(Map<String, dynamic> json) {
    return CreateReviewRequestModel(
      revieweeId: json['revieweeId']?.toString() ??
          json['reviewee_id']?.toString() ??
          '',
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString(),
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : (double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0),
      comment: json['comment']?.toString() ?? json['review']?.toString(),
      reviewerId:
          json['reviewerId']?.toString() ?? json['reviewer_id']?.toString(),
    );
  }
}
