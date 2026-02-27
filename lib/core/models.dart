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

  AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    this.rating = 0.0,
    this.walletBalance = 0.0,
    this.isVerified = false,
  });
}

class Product {
  final String id;
  final String farmerId;
  final String productName;
  final String imageUrl;
  final double quantity; // In KG or Tons
  final String unit;
  final double minimumPrice;
  final TradeType tradeType;
  final DateTime startTime;
  final DateTime endTime;
  final String status;

  Product({
    required this.id,
    required this.farmerId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    this.unit = 'KG',
    required this.minimumPrice,
    required this.tradeType,
    required this.startTime,
    required this.endTime,
    this.status = 'active',
  });
}

class Bid {
  final String id;
  final String productId;
  final String buyerId;
  final double amount;
  final DateTime createdAt;

  Bid({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.amount,
    required this.createdAt,
  });
}

class Negotiation {
  final String id;
  final String productId;
  final String buyerId;
  final String farmerId;
  final NegotiationStatus status;

  Negotiation({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.farmerId,
    required this.status,
  });
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

  DemandPost({
    required this.id,
    required this.buyerId,
    required this.productName,
    required this.quantity,
    required this.callingPrice,
    required this.deliveryLocation,
    required this.expiryTime,
    required this.status,
  });
}

class DemandOffer {
  final String id;
  final String demandId;
  final String farmerId;
  final double offerPrice;
  final DateTime createdAt;

  DemandOffer({
    required this.id,
    required this.demandId,
    required this.farmerId,
    required this.offerPrice,
    required this.createdAt,
  });
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
