import './models.dart';

class MockData {
  static final demoGroups = [
    BuyingGroup(
      id: 'g1',
      name: 'Dhaka Potato Buyers',
      productName: 'Organic Potatoes',
      category: 'Vegetables',
      targetQuantity: 500,
      filledQuantity: 320,
      pricePerKg: 35.0,
      deliveryLocation: 'Kawran Bazar, Dhaka',
      createdBy: 'u1',
      expiryDate: DateTime.now().add(const Duration(days: 4)),
      status: GroupBuyStatus.open,
      members: [
        GroupMember(userId: 'u1', name: 'Masihur Rahman', contributionQuantity: 150, isPaid: true, phone: '01700000000'),
        GroupMember(userId: 'u2', name: 'Karim (Wholesaler)', contributionQuantity: 100, isPaid: false, phone: '01711111111'),
        GroupMember(userId: 'u3', name: 'Rahim (Retailer)', contributionQuantity: 70, isPaid: true, phone: '01722222222'),
      ],
      messages: [
        GroupMessage(id: 'm1', groupId: 'g1', senderId: 'u1', senderName: 'Masihur Rahman', message: 'আমি এই গ্রুপ তৈরি করেছি। আসুন একসাথে আলু কিনি! 🥔', createdAt: DateTime.now().subtract(const Duration(hours: 5))),
        GroupMessage(id: 'm2', groupId: 'g1', senderId: 'u2', senderName: 'Karim', message: 'দারুণ আইডিয়া ভাই! আমি ১০০ কেজি নেব।', createdAt: DateTime.now().subtract(const Duration(hours: 4))),
        GroupMessage(id: 'm3', groupId: 'g1', senderId: 'u3', senderName: 'Rahim', message: 'আমিও আছি। ৭০ কেজি কনফার্ম করলাম।', createdAt: DateTime.now().subtract(const Duration(hours: 3))),
        GroupMessage(id: 'm4', groupId: 'g1', senderId: 'u1', senderName: 'Masihur Rahman', message: 'কৃষক আব্দুল সাহেবের সাথে কথা হয়েছে। দাম ৩৫ টাকা/কেজি পাওয়া যাবে।', createdAt: DateTime.now().subtract(const Duration(hours: 1))),
      ],
    ),
    BuyingGroup(
      id: 'g2',
      name: 'BD Rice Collective',
      productName: 'Fresh Basmati Rice',
      category: 'Grains',
      targetQuantity: 1000,
      filledQuantity: 450,
      pricePerKg: 118.0,
      deliveryLocation: 'Sadarghat, Dhaka',
      createdBy: 'u2',
      expiryDate: DateTime.now().add(const Duration(days: 7)),
      status: GroupBuyStatus.open,
      members: [
        GroupMember(userId: 'u2', name: 'Karim (Wholesaler)', contributionQuantity: 300, isPaid: true, phone: '01711111111'),
        GroupMember(userId: 'u3', name: 'Rahim (Retailer)', contributionQuantity: 150, isPaid: false, phone: '01722222222'),
      ],
      messages: [
        GroupMessage(id: 'm5', groupId: 'g2', senderId: 'u2', senderName: 'Karim', message: 'Basmati rice group started! We need 1000 KG for bulk discount.', createdAt: DateTime.now().subtract(const Duration(days: 1))),
        GroupMessage(id: 'm6', groupId: 'g2', senderId: 'u3', senderName: 'Rahim', message: 'Joined! I can take 150 KG.', createdAt: DateTime.now().subtract(const Duration(hours: 10))),
      ],
    ),
    BuyingGroup(
      id: 'g3',
      name: 'Chittagong Onion Group',
      productName: 'Red Onions',
      category: 'Vegetables',
      targetQuantity: 300,
      filledQuantity: 300,
      pricePerKg: 62.0,
      deliveryLocation: 'Reazuddin Bazar, Chittagong',
      createdBy: 'u3',
      expiryDate: DateTime.now().add(const Duration(days: 1)),
      status: GroupBuyStatus.active,
      members: [
        GroupMember(userId: 'u3', name: 'Rahim (Retailer)', contributionQuantity: 180, isPaid: true, phone: '01722222222'),
        GroupMember(userId: 'u2', name: 'Karim (Wholesaler)', contributionQuantity: 120, isPaid: true, phone: '01711111111'),
      ],
      messages: [
        GroupMessage(id: 'm7', groupId: 'g3', senderId: 'u3', senderName: 'Rahim', message: 'Group is FULL! 🎉 All 300 KG committed. Waiting for farmer confirmation.', createdAt: DateTime.now().subtract(const Duration(hours: 2))),
        GroupMessage(id: 'm8', groupId: 'g3', senderId: 'u2', senderName: 'Karim', message: 'Payment করে দিলাম। দ্রুত ডেলিভারি পাবো আশা করি।', createdAt: DateTime.now().subtract(const Duration(hours: 1))),
      ],
    ),
  ];


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
      tradeType: TradeType.negotiation,
      imageUrl: 'assets/images/potato.png',
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

  static final demoNotifications = [
    AppNotification(
      id: 'n1',
      title: 'Order Delivered',
      message: 'Your order for 100KG Organic Potatoes has been delivered successfully.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.order,
    ),
    AppNotification(
      id: 'n2',
      title: 'Payment Received',
      message: 'You have received ৳3,500.00 in your wallet from Farmer Abdul.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.payment,
    ),
    AppNotification(
      id: 'n3',
      title: 'Price Alert',
      message: 'The price of Red Onions has dropped by 10% in your area.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.alert,
      isRead: true,
    ),
    AppNotification(
      id: 'n4',
      title: 'Welcome to ChashiBhai!',
      message: 'Start exploring the best agri-deals in Bangladesh today.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      type: NotificationType.promo,
      isRead: true,
    ),
  ];

  static final demoReviews = [
    Review(
      id: 'r1',
      reviewerId: 'u1',
      revieweeId: 'f1',
      orderId: 'o1',
      rating: 5.0,
      comment: 'Excellent quality and timely delivery. The farmer was very communicative.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Review(
      id: 'r2',
      reviewerId: 'f1',
      revieweeId: 'u1',
      orderId: 'o1',
      rating: 4.5,
      comment: 'Prompt payment and smooth transaction. Great buyer!',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];
}
