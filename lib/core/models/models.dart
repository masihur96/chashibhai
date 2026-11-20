enum UserRole { farmer, buyer, admin }

enum TradeType { auction, negotiation, both }

enum NegotiationStatus { pending, accepted, rejected, countered }

enum DemandStatus { active, expired, fulfilled }

enum OrderStatus { pending, dispatched, delivered, cancelled }

enum TransactionType { deposit, escrow, release, withdrawal }

class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String phone;
  final double rating;
  final double walletBalance;
  final bool isVerified;
  final String? email;
  final String? avatarUrl;
  final String? district;

  AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    this.rating = 0.0,
    this.walletBalance = 0.0,
    this.isVerified = false,
    this.email,
    this.avatarUrl,
    this.district,
  });

  AppUser copyWith({
    String? id,
    String? name,
    UserRole? role,
    String? phone,
    double? rating,
    double? walletBalance,
    bool? isVerified,
    String? email,
    String? avatarUrl,
    String? district,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      rating: rating ?? this.rating,
      walletBalance: walletBalance ?? this.walletBalance,
      isVerified: isVerified ?? this.isVerified,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      district: district ?? this.district,
    );
  }
}

class Product {
  final String id;
  final String farmerId;
  final String productName;
  final String imageUrl;
  final List<String> imageUrls;
  final double quantity; // In KG or Tons
  final String unit;
  final double minimumPrice;
  final TradeType tradeType;
  final DateTime startTime;
  final DateTime endTime;
  final String category;
  final String status;

  Product({
    required this.id,
    required this.farmerId,
    required this.productName,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.quantity,
    this.unit = 'KG',
    required this.minimumPrice,
    required this.tradeType,
    required this.startTime,
    required this.endTime,
    required this.category,
    this.status = 'active',
  });

  Product copyWith({
    String? id,
    String? farmerId,
    String? productName,
    String? imageUrl,
    List<String>? imageUrls,
    double? quantity,
    String? unit,
    double? minimumPrice,
    TradeType? tradeType,
    DateTime? startTime,
    DateTime? endTime,
    String? category,
    String? status,
  }) {
    return Product(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      minimumPrice: minimumPrice ?? this.minimumPrice,
      tradeType: tradeType ?? this.tradeType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      status: status ?? this.status,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    TradeType parseTradeType(dynamic val) {
      final str = val?.toString().toLowerCase();
      if (str == 'auction') return TradeType.auction;
      if (str == 'negotiation') return TradeType.negotiation;
      return TradeType.both;
    }

    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val == null) return fallback;
      return DateTime.tryParse(val.toString()) ?? fallback;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    List<String> parseUrls(dynamic val) {
      if (val is List) {
        return val
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty && s != 'string')
            .toList();
      }
      return [];
    }

    final parsedUrls = parseUrls(json['imageUrls'] ?? json['image_urls'] ?? json['images']);
    final primaryImg = (json['imageUrl'] ??
            json['image_url'] ??
            (json['image'] != null && json['image'] != 'string' ? json['image'] : null) ??
            (json['file'] != null && json['file'] != 'string' ? json['file'] : null) ??
            (parsedUrls.isNotEmpty ? parsedUrls.first : ''))
        .toString();

    return Product(
      id: (json['id'] ?? json['_id'] ?? 'p_${DateTime.now().millisecondsSinceEpoch}').toString(),
      farmerId: (json['farmerId'] ?? json['farmer_id'] ?? json['userId'] ?? json['user_id'] ?? '').toString(),
      productName: (json['productName'] ?? json['product_name'] ?? json['name'] ?? '').toString(),
      imageUrl: primaryImg,
      imageUrls: parsedUrls.isNotEmpty ? parsedUrls : (primaryImg.isNotEmpty ? [primaryImg] : const []),
      quantity: parseDouble(json['quantity']),
      unit: (json['unit'] ?? 'KG').toString(),
      minimumPrice: parseDouble(json['minimumPrice'] ?? json['minimum_price']),
      tradeType: parseTradeType(json['tradeType'] ?? json['trade_type']),
      startTime: parseDate(json['startTime'] ?? json['start_time'], DateTime.now()),
      endTime: parseDate(json['endTime'] ?? json['end_time'], DateTime.now().add(const Duration(days: 7))),
      category: (json['category'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    String tradeTypeString;
    switch (tradeType) {
      case TradeType.auction:
        tradeTypeString = 'auction';
        break;
      case TradeType.negotiation:
        tradeTypeString = 'negotiation';
        break;
      case TradeType.both:
        tradeTypeString = 'both';
        break;
    }

    final effectiveUrls = imageUrls.isNotEmpty ? imageUrls : (imageUrl.isNotEmpty ? [imageUrl] : <String>[]);

    return {
      'id': id,
      'farmerId': farmerId,
      'farmer_id': farmerId,
      'productName': productName,
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
      'minimumPrice': minimumPrice,
      'minimum_price': minimumPrice,
      'tradeType': tradeTypeString,
      'trade_type': tradeTypeString,
      'category': category,
      'startTime': startTime.toUtc().toIso8601String(),
      'start_time': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'imageUrl': imageUrl,
      'image_url': imageUrl,
      'imageUrls': effectiveUrls,
      'image_urls': effectiveUrls,
      'images': effectiveUrls,
      'status': status,
    };
  }
}

class Bid {
  final String id;
  final String productId;
  final String buyerId;
  final double amount;
  final DateTime createdAt;
  final String? bidderName;
  final String? status;
  final String? productName;
  final String? productImageUrl;
  final String? productUnit;
  final double? productMinimumPrice;
  final DateTime? productEndTime;
  final double? currentHighestBid;
  final bool? isWinning;

  Bid({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.amount,
    required this.createdAt,
    this.bidderName,
    this.status = 'active',
    this.productName,
    this.productImageUrl,
    this.productUnit,
    this.productMinimumPrice,
    this.productEndTime,
    this.currentHighestBid,
    this.isWinning,
  });

  Bid copyWith({
    String? id,
    String? productId,
    String? buyerId,
    double? amount,
    DateTime? createdAt,
    String? bidderName,
    String? status,
    String? productName,
    String? productImageUrl,
    String? productUnit,
    double? productMinimumPrice,
    DateTime? productEndTime,
    double? currentHighestBid,
    bool? isWinning,
  }) {
    return Bid(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      buyerId: buyerId ?? this.buyerId,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      bidderName: bidderName ?? this.bidderName,
      status: status ?? this.status,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      productUnit: productUnit ?? this.productUnit,
      productMinimumPrice: productMinimumPrice ?? this.productMinimumPrice,
      productEndTime: productEndTime ?? this.productEndTime,
      currentHighestBid: currentHighestBid ?? this.currentHighestBid,
      isWinning: isWinning ?? this.isWinning,
    );
  }

  factory Bid.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    String? bidderName = json['bidderName']?.toString() ??
        json['bidder_name']?.toString() ??
        json['userName']?.toString() ??
        json['name']?.toString();
    if (bidderName == null) {
      final bidderMap = json['bidder'] ?? json['user'] ?? json['buyer'];
      if (bidderMap is Map<String, dynamic>) {
        bidderName = bidderMap['name']?.toString() ??
            bidderMap['fullName']?.toString() ??
            bidderMap['phone']?.toString();
      }
    }

    // Extract nested product details if present
    String? productName;
    String? productImageUrl;
    String? productUnit;
    double? productMinimumPrice;
    DateTime? productEndTime;

    final productMap = json['product'];
    if (productMap is Map<String, dynamic>) {
      productName = productMap['productName']?.toString() ??
          productMap['product_name']?.toString() ??
          productMap['name']?.toString();
      productImageUrl = productMap['imageUrl']?.toString() ??
          productMap['image_url']?.toString() ??
          productMap['image']?.toString();
      productUnit = productMap['unit']?.toString();
      if (productMap['minimumPrice'] != null || productMap['minimum_price'] != null) {
        productMinimumPrice = parseDouble(productMap['minimumPrice'] ?? productMap['minimum_price']);
      }
      if (productMap['endTime'] != null || productMap['end_time'] != null) {
        productEndTime = DateTime.tryParse((productMap['endTime'] ?? productMap['end_time']).toString());
      }
    }
    productName ??= json['productName']?.toString() ?? json['product_name']?.toString();
    productImageUrl ??= json['productImageUrl']?.toString() ?? json['product_image_url']?.toString();
    productUnit ??= json['unit']?.toString();
    if (productMinimumPrice == null && (json['minimumPrice'] != null || json['minimum_price'] != null)) {
      productMinimumPrice = parseDouble(json['minimumPrice'] ?? json['minimum_price']);
    }
    if (productEndTime == null && (json['endTime'] != null || json['end_time'] != null)) {
      productEndTime = DateTime.tryParse((json['endTime'] ?? json['end_time']).toString());
    }

    double? currentHighestBid;
    if (json['currentHighestBid'] != null || json['highestBid'] != null || json['current_highest_bid'] != null) {
      currentHighestBid = parseDouble(json['currentHighestBid'] ?? json['highestBid'] ?? json['current_highest_bid']);
    }

    bool? isWinning;
    if (json['isWinning'] != null || json['is_winning'] != null) {
      isWinning = json['isWinning'] == true || json['is_winning'] == true;
    }

    return Bid(
      id: (json['id'] ?? json['_id'] ?? 'b_${DateTime.now().millisecondsSinceEpoch}').toString(),
      productId: (json['productId'] ?? json['product_id'] ?? (productMap is Map ? productMap['id'] : '') ?? '').toString(),
      buyerId: (json['buyerId'] ?? json['buyer_id'] ?? json['userId'] ?? json['user_id'] ?? '').toString(),
      amount: parseDouble(json['amount'] ?? json['price'] ?? json['bidAmount'] ?? json['bid_amount']),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      bidderName: bidderName,
      status: (json['status'] ?? 'active').toString(),
      productName: productName,
      productImageUrl: productImageUrl,
      productUnit: productUnit,
      productMinimumPrice: productMinimumPrice,
      productEndTime: productEndTime,
      currentHighestBid: currentHighestBid,
      isWinning: isWinning,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'product_id': productId,
      'buyerId': buyerId,
      'buyer_id': buyerId,
      'amount': amount,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      if (bidderName != null) 'bidderName': bidderName,
      if (status != null) 'status': status,
      if (productName != null) 'productName': productName,
      if (productImageUrl != null) 'productImageUrl': productImageUrl,
      if (productUnit != null) 'productUnit': productUnit,
      if (productMinimumPrice != null) 'productMinimumPrice': productMinimumPrice,
      if (productEndTime != null) 'productEndTime': productEndTime!.toUtc().toIso8601String(),
      if (currentHighestBid != null) 'currentHighestBid': currentHighestBid,
      if (isWinning != null) 'isWinning': isWinning,
    };
  }
}

class Negotiation {
  final String id;
  final String productId;
  final String buyerId;
  final String farmerId;
  final NegotiationStatus status;
  final double? offerPrice;
  final double? counterPrice;
  final String? productName;
  final String? productImageUrl;
  final String? farmerName;
  final String? buyerName;
  final String? message;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Negotiation({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.farmerId,
    required this.status,
    this.offerPrice,
    this.counterPrice,
    this.productName,
    this.productImageUrl,
    this.farmerName,
    this.buyerName,
    this.message,
    this.createdAt,
    this.updatedAt,
  });

  Negotiation copyWith({
    String? id,
    String? productId,
    String? buyerId,
    String? farmerId,
    NegotiationStatus? status,
    double? offerPrice,
    double? counterPrice,
    String? productName,
    String? productImageUrl,
    String? farmerName,
    String? buyerName,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Negotiation(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      buyerId: buyerId ?? this.buyerId,
      farmerId: farmerId ?? this.farmerId,
      status: status ?? this.status,
      offerPrice: offerPrice ?? this.offerPrice,
      counterPrice: counterPrice ?? this.counterPrice,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      farmerName: farmerName ?? this.farmerName,
      buyerName: buyerName ?? this.buyerName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Negotiation.fromJson(Map<String, dynamic> json) {
    NegotiationStatus parseStatus(dynamic val) {
      switch (val?.toString().toLowerCase()) {
        case 'accepted': return NegotiationStatus.accepted;
        case 'rejected': return NegotiationStatus.rejected;
        case 'countered': return NegotiationStatus.countered;
        default: return NegotiationStatus.pending;
      }
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    // Extract nested product info
    String? productName;
    String? productImageUrl;
    final productMap = json['product'];
    if (productMap is Map<String, dynamic>) {
      productName = productMap['productName']?.toString() ??
          productMap['product_name']?.toString() ??
          productMap['name']?.toString();
      productImageUrl = productMap['imageUrl']?.toString() ??
          productMap['image_url']?.toString() ??
          productMap['image']?.toString();
    }
    productName ??= json['productName']?.toString() ?? json['product_name']?.toString();
    productImageUrl ??= json['productImageUrl']?.toString() ?? json['product_image_url']?.toString();

    // Extract nested farmer info
    String? farmerName;
    final farmerMap = json['farmer'] ?? json['seller'];
    if (farmerMap is Map<String, dynamic>) {
      farmerName = farmerMap['name']?.toString() ??
          farmerMap['fullName']?.toString() ??
          farmerMap['phone']?.toString();
    }
    farmerName ??= json['farmerName']?.toString() ?? json['farmer_name']?.toString();

    // Extract nested buyer info
    String? buyerName;
    final buyerMap = json['buyer'];
    if (buyerMap is Map<String, dynamic>) {
      buyerName = buyerMap['name']?.toString() ??
          buyerMap['fullName']?.toString() ??
          buyerMap['phone']?.toString();
    }
    buyerName ??= json['buyerName']?.toString() ?? json['buyer_name']?.toString();

    return Negotiation(
      id: (json['id'] ?? json['_id'] ?? 'n_${DateTime.now().millisecondsSinceEpoch}').toString(),
      productId: (json['productId'] ?? json['product_id'] ??
          (productMap is Map ? productMap['id'] : '') ?? '').toString(),
      buyerId: (json['buyerId'] ?? json['buyer_id'] ?? json['userId'] ?? '').toString(),
      farmerId: (json['farmerId'] ?? json['farmer_id'] ?? '').toString(),
      status: parseStatus(json['status']),
      offerPrice: parseDouble(json['offerPrice'] ?? json['offer_price'] ?? json['price'] ?? json['amount']),
      counterPrice: parseDouble(json['counterPrice'] ?? json['counter_price'] ?? json['counterOffer']),
      productName: productName,
      productImageUrl: productImageUrl,
      farmerName: farmerName,
      buyerName: buyerName,
      message: json['message']?.toString() ?? json['note']?.toString(),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'product_id': productId,
    'buyerId': buyerId,
    'buyer_id': buyerId,
    'farmerId': farmerId,
    'farmer_id': farmerId,
    'status': status.name,
    if (offerPrice != null) 'offerPrice': offerPrice,
    if (counterPrice != null) 'counterPrice': counterPrice,
    if (message != null) 'message': message,
    if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
  };
}

class NegotiationOffer {
  final String id;
  final String negotiationId;
  final String senderId;
  final double amount;
  final DateTime createdAt;

  NegotiationOffer({
    required this.id,
    required this.negotiationId,
    required this.senderId,
    required this.amount,
    required this.createdAt,
  });
}

class DemandPost {
  final String id;
  final String buyerId;
  final String productName;
  final double quantity;
  final double callingPrice;
  final String deliveryLocation;
  final DateTime expiryTime;
  final DemandStatus status;
  final TradeType tradeType;
  final String imageUrl;
  final String? buyerName;
  final String? buyerPhone;

  DemandPost({
    required this.id,
    required this.buyerId,
    required this.productName,
    required this.quantity,
    required this.callingPrice,
    required this.deliveryLocation,
    required this.expiryTime,
    required this.status,
    required this.tradeType,
    required this.imageUrl,
    this.buyerName,
    this.buyerPhone,
  });

  DemandPost copyWith({
    String? id,
    String? buyerId,
    String? productName,
    double? quantity,
    double? callingPrice,
    String? deliveryLocation,
    DateTime? expiryTime,
    DemandStatus? status,
    TradeType? tradeType,
    String? imageUrl,
    String? buyerName,
    String? buyerPhone,
  }) {
    return DemandPost(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      callingPrice: callingPrice ?? this.callingPrice,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      expiryTime: expiryTime ?? this.expiryTime,
      status: status ?? this.status,
      tradeType: tradeType ?? this.tradeType,
      imageUrl: imageUrl ?? this.imageUrl,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
    );
  }

  factory DemandPost.fromJson(Map<String, dynamic> json) {
    TradeType parseTradeType(dynamic val) {
      final str = val?.toString().toLowerCase();
      if (str == 'auction') return TradeType.auction;
      if (str == 'both') return TradeType.both;
      return TradeType.negotiation;
    }

    DemandStatus parseDemandStatus(dynamic val) {
      final str = val?.toString().toLowerCase();
      if (str == 'expired') return DemandStatus.expired;
      if (str == 'fulfilled') return DemandStatus.fulfilled;
      return DemandStatus.active;
    }

    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val == null) return fallback;
      return DateTime.tryParse(val.toString()) ?? fallback;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final buyerObj = json['buyer'] is Map<String, dynamic> ? json['buyer'] as Map<String, dynamic> : null;

    return DemandPost(
      id: (json['id'] ?? json['_id'] ?? 'd_${DateTime.now().millisecondsSinceEpoch}').toString(),
      buyerId: (json['buyerId'] ?? json['buyer_id'] ?? json['userId'] ?? json['user_id'] ?? '').toString(),
      productName: (json['productName'] ?? json['product_name'] ?? '').toString(),
      quantity: parseDouble(json['quantity']),
      callingPrice: parseDouble(json['callingPrice'] ?? json['calling_price']),
      deliveryLocation: (json['deliveryLocation'] ?? json['delivery_location'] ?? '').toString(),
      expiryTime: parseDate(json['expiryTime'] ?? json['expiry_time'], DateTime.now().add(const Duration(days: 3))),
      status: parseDemandStatus(json['status']),
      tradeType: parseTradeType(json['tradeType'] ?? json['trade_type']),
      imageUrl: (json['imageUrl'] ?? json['image_url'] ?? '').toString(),
      buyerName: buyerObj?['name']?.toString() ?? json['buyerName']?.toString() ?? json['buyer_name']?.toString(),
      buyerPhone: buyerObj?['phone']?.toString() ?? json['buyerPhone']?.toString() ?? json['buyer_phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyerId': buyerId,
      'buyer_id': buyerId,
      'productName': productName,
      'product_name': productName,
      'quantity': quantity,
      'callingPrice': callingPrice,
      'calling_price': callingPrice,
      'deliveryLocation': deliveryLocation,
      'delivery_location': deliveryLocation,
      'expiryTime': expiryTime.toUtc().toIso8601String(),
      'expiry_time': expiryTime.toUtc().toIso8601String(),
      'status': status.name,
      'tradeType': tradeType.name,
      'trade_type': tradeType.name,
      'imageUrl': imageUrl,
      'image_url': imageUrl,
    };
  }
}

class DemandOffer {
  final String id;
  final String demandId;
  final String farmerId;
  final double offerPrice;
  final String? note;
  final DateTime createdAt;

  DemandOffer({
    required this.id,
    required this.demandId,
    required this.farmerId,
    required this.offerPrice,
    this.note,
    required this.createdAt,
  });

  factory DemandOffer.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return DemandOffer(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      demandId: (json['demandId'] ?? json['demand_id'] ?? '').toString(),
      farmerId: (json['farmerId'] ?? json['farmer_id'] ?? '').toString(),
      offerPrice: parseDouble(json['offerPrice'] ?? json['offer_price']),
      note: json['note']?.toString(),
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ??
                json['created_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'demandId': demandId,
      'demand_id': demandId,
      'farmerId': farmerId,
      'farmer_id': farmerId,
      'offerPrice': offerPrice,
      'offer_price': offerPrice,
      if (note != null) 'note': note,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }
}

class Order {
  final String id;
  final String? supplyId;
  final String? demandId;
  final String buyerId;
  final String farmerId;
  final double finalPrice;
  final double quantity;
  final double commission;
  final OrderStatus status;

  Order({
    required this.id,
    this.supplyId,
    this.demandId,
    required this.buyerId,
    required this.farmerId,
    required this.finalPrice,
    required this.quantity,
    required this.commission,
    required this.status,
  });
}

class Transaction {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.createdAt,
  });
}

enum GroupBuyStatus { open, active, fulfilled, cancelled }

enum NotificationType { order, payment, alert, promo }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final NotificationType type;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.isRead = false,
  });
}

class GroupMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime createdAt;

  GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
  });
}

class GroupMember {
  final String userId;
  final String name;
  final double contributionQuantity;
  final bool isPaid;
  final String phone;

  GroupMember({
    required this.userId,
    required this.name,
    required this.contributionQuantity,
    this.isPaid = false,
    this.phone = '',
  });
}

class BuyingGroup {
  final String id;
  final String name;
  final String productName;
  final String category;
  final double targetQuantity;
  final double filledQuantity;
  final double pricePerKg;
  final String deliveryLocation;
  final String createdBy;
  final List<GroupMember> members;
  final List<GroupMessage> messages;
  final DateTime expiryDate;
  final GroupBuyStatus status;
  final String? linkedDemandId;

  BuyingGroup({
    required this.id,
    required this.name,
    required this.productName,
    required this.category,
    required this.targetQuantity,
    required this.filledQuantity,
    required this.pricePerKg,
    required this.deliveryLocation,
    required this.createdBy,
    required this.members,
    required this.messages,
    required this.expiryDate,
    this.status = GroupBuyStatus.open,
    this.linkedDemandId,
  });

  BuyingGroup copyWith({
    List<GroupMember>? members,
    List<GroupMessage>? messages,
    double? filledQuantity,
    GroupBuyStatus? status,
    String? linkedDemandId,
  }) {
    return BuyingGroup(
      id: id,
      name: name,
      productName: productName,
      category: category,
      targetQuantity: targetQuantity,
      filledQuantity: filledQuantity ?? this.filledQuantity,
      pricePerKg: pricePerKg,
      deliveryLocation: deliveryLocation,
      createdBy: createdBy,
      members: members ?? this.members,
      messages: messages ?? this.messages,
      expiryDate: expiryDate,
      status: status ?? this.status,
      linkedDemandId: linkedDemandId ?? this.linkedDemandId,
    );
  }
}

class Review {
  final String id;
  final String reviewerId;
  final String revieweeId;
  final String? orderId;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.reviewerId,
    required this.revieweeId,
    this.orderId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          json['reviewId']?.toString() ??
          'rev_${DateTime.now().millisecondsSinceEpoch}',
      reviewerId: json['reviewerId']?.toString() ??
          json['reviewer_id']?.toString() ??
          json['userId']?.toString() ??
          '',
      revieweeId: json['revieweeId']?.toString() ??
          json['reviewee_id']?.toString() ??
          json['targetUserId']?.toString() ??
          '',
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString(),
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : (double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0),
      comment: json['comment']?.toString() ?? json['review']?.toString(),
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ??
                json['created_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      if (orderId != null) 'orderId': orderId,
      'rating': rating,
      if (comment != null) 'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Review copyWith({
    String? id,
    String? reviewerId,
    String? revieweeId,
    String? orderId,
    double? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      reviewerId: reviewerId ?? this.reviewerId,
      revieweeId: revieweeId ?? this.revieweeId,
      orderId: orderId ?? this.orderId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
