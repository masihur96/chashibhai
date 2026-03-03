import 'models.dart';

class MockData {
  static final currentUser = AppUser(
    id: 'u1',
    name: 'Masihur Rahman',
    role: UserRole.buyer,
    phone: '01700000000',
    rating: 4.8,
    walletBalance: 25000.0,
    isVerified: true,
  );

  static final farmerUser = AppUser(
    id: 'f1',
    name: 'Farmer Abdul',
    role: UserRole.farmer,
    phone: '01800000000',
    rating: 4.5,
    walletBalance: 12000.0,
    isVerified: true,
  );

  static final demoProducts = [
    Product(
      id: 'p1',
      farmerId: 'f1',
      productName: 'Organic Potatoes',
      imageUrl: 'assets/images/potato.png',
      quantity: 500,
      unit: 'KG',
      minimumPrice: 35.0,
      tradeType: TradeType.both,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(days: 2)),
      category: 'Vegetables',
    ),
    Product(
      id: 'p2',
      farmerId: 'f1',
      productName: 'Red Onions',
      imageUrl: 'assets/images/onion.png',
      quantity: 300,
      unit: 'KG',
      minimumPrice: 65.0,
      tradeType: TradeType.auction,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 12)),
      category: 'Vegetables',
    ),
    Product(
      id: 'p3',
      farmerId: 'f1',
      productName: 'Vine Ripened Tomatoes',
      imageUrl: 'assets/images/tomato.png',
      quantity: 150,
      unit: 'KG',
      minimumPrice: 80.0,
      tradeType: TradeType.negotiation,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(days: 1)),
      category: 'Vegetables',
    ),
    Product(
      id: 'p4',
      farmerId: 'f1',
      productName: 'Fresh Basmati Rice',
      imageUrl: 'assets/images/rice.png',
      quantity: 1000,
      unit: 'KG',
      minimumPrice: 120.0,
      tradeType: TradeType.negotiation,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(days: 10)),
      category: 'Grains',
    ),
  ];

  static final demoBids = [
    Bid(
      id: 'b1',
      productId: 'p2',
      buyerId: 'u2',
      amount: 68.0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    Bid(
      id: 'b2',
      productId: 'p2',
      buyerId: 'u3',
      amount: 70.0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];

  static final demoDemands = [
    DemandPost(
      id: 'd1',
      buyerId: 'u1',
      productName: 'Green Chillies',
      quantity: 50,
      callingPrice: 120.0,
      deliveryLocation: 'Dhaka, Bangladesh',
      expiryTime: DateTime.now().add(const Duration(days: 3)),
      status: DemandStatus.active,
    ),
  ];

  static final demoOrders = [
    Order(
      id: 'o1',
      supplyId: 'p1',
      buyerId: 'u1',
      farmerId: 'f1',
      finalPrice: 35.0,
      quantity: 100,
      commission: 350.0,
      status: OrderStatus.delivered,
    ),
  ];

  static final demoTransactions = [
    Transaction(
      id: 't1',
      userId: 'u1',
      type: TransactionType.deposit,
      amount: 30000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Transaction(
      id: 't2',
      userId: 'u1',
      type: TransactionType.escrow,
      amount: 3500.0,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}
