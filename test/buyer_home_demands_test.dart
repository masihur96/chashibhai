import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chashibhai/core/models/models.dart';
import 'package:chashibhai/core/services/upload_service.dart';
import 'package:chashibhai/features/account/presentation/state/app_state_provider.dart';
import 'package:chashibhai/features/auth/presentation/state/auth_provider.dart';
import 'package:chashibhai/features/buyer/data/models/create_demand_request_model.dart';
import 'package:chashibhai/features/buyer/data/models/create_bid_request_model.dart';
import 'package:chashibhai/features/buyer/data/models/create_demand_offer_request_model.dart';
import 'package:chashibhai/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:chashibhai/features/buyer/domain/usecases/get_my_demands_usecase.dart';
import 'package:chashibhai/features/buyer/presentation/state/demand_provider.dart';
import 'package:chashibhai/features/buyer/presentation/state/product_provider.dart';
import 'package:chashibhai/features/buyer/presentation/views/buyer_home.dart';
import 'package:chashibhai/features/group/presentation/state/group_provider.dart';
import 'package:chashibhai/features/wallet/presentation/state/order_provider.dart';

class MockBuyerRepository implements BuyerRepository {
  Map<String, dynamic>? lastGetMyDemandsParams;

  List<DemandPost> mockDemands = [
    DemandPost(
      id: 'd_my_potato_1',
      buyerId: 'buyer_test',
      productName: 'Potato',
      quantity: 1000,
      callingPrice: 28,
      deliveryLocation: 'Karwan Bazar, Dhaka',
      expiryTime: DateTime.parse('2026-11-30T18:00:00Z'),
      status: DemandStatus.active,
      tradeType: TradeType.both,
      imageUrl: 'https://cdn.example.com/demands/potato.jpg',
    ),
  ];

  @override
  Future<List<DemandPost>> getMyDemands({
    int page = 1,
    int limit = 10,
    String? search,
    String? productName,
    double? minPrice,
    double? maxPrice,
    String? tradeType,
    String? status,
    String? token,
  }) async {
    lastGetMyDemandsParams = {
      'page': page,
      'limit': limit,
      'search': search,
      'productName': productName,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'tradeType': tradeType,
      'status': status,
      'token': token,
    };
    return mockDemands;
  }

  @override
  Future<List<DemandPost>> getDemands({
    int page = 1,
    int limit = 10,
    String? tradeType = 'both',
    String? status = 'active',
    String? search,
    String? token,
  }) async {
    return mockDemands;
  }

  @override
  Future<DemandOffer> submitDemandOffer({
    required String demandId,
    required CreateDemandOfferRequestModel request,
    String? token,
  }) async {
    return DemandOffer(
      id: 'mock_offer_home',
      demandId: demandId,
      farmerId: 'farmer_1',
      offerPrice: request.offerPrice,
      note: request.note,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<DemandOffer>> getDemandOffers({
    required String demandId,
    String? token,
  }) async {
    return [];
  }

  @override
  Future<DemandPost> getDemandById({
    required String demandId,
    String? token,
  }) async {
    return mockDemands.firstWhere(
      (d) => d.id == demandId,
      orElse: () => mockDemands.first,
    );
  }

  @override
  Future<AcceptDemandOfferResult> acceptDemandOffer({
    required String demandId,
    required String offerId,
    String? token,
  }) async {
    return AcceptDemandOfferResult(
      success: true,
      message: 'Offer accepted successfully',
      demandId: demandId,
      offerId: offerId,
      status: 'fulfilled',
    );
  }

  @override
  Future<DemandPost> createDemand({
    required CreateDemandRequestModel request,
    String? token,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> uploadImages({
    required List<UploadFileItem> files,
    String? token,
  }) async {
    return [];
  }

  @override
  Future<Bid> createBid({
    required CreateBidRequestModel request,
    String? token,
  }) async {
    return Bid(
      id: 'b_mock_1',
      productId: request.productId,
      buyerId: 'buyer_test',
      amount: request.amount,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<Product>> getAvailableProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String? token,
  }) async {
    return [
      Product(
        id: 'ee9ac1a6-bb66-45d0-a6de-8e390702be0e',
        farmerId: 'f1',
        productName: 'Fresh Diamond Potatoes',
        imageUrl: 'assets/images/potato.png',
        quantity: 500,
        unit: 'KG',
        minimumPrice: 55.0,
        tradeType: TradeType.auction,
        startTime: DateTime.now().subtract(const Duration(hours: 4)),
        endTime: DateTime.now().add(const Duration(days: 2)),
        category: 'Vegetables',
      ),
    ];
  }

  @override
  Future<Product?> getProductById({
    required String id,
    String? token,
  }) async {
    return Product(
      id: id,
      farmerId: 'f1',
      productName: 'Fresh Diamond Potatoes',
      imageUrl: 'assets/images/potato.png',
      quantity: 500,
      unit: 'KG',
      minimumPrice: 55.0,
      tradeType: TradeType.auction,
      startTime: DateTime.now().subtract(const Duration(hours: 4)),
      endTime: DateTime.now().add(const Duration(days: 2)),
      category: 'Vegetables',
    );
  }

  @override
  Future<List<Bid>> getBidsByProductId({
    required String productId,
    String? token,
  }) async {
    return [];
  }

  @override
  Future<List<Bid>> getMyBids({
    String? token,
  }) async {
    return [];
  }

  @override
  Future<List<Negotiation>> getMyNegotiations({
    String? token,
  }) async {
    return [];
  }
}

void main() {
  group('Buyer Home - Get My Demands Feature Tests', () {
    late MockBuyerRepository mockRepository;
    late GetMyDemandsUseCase getMyDemandsUseCase;
    late DemandProvider demandProvider;

    setUp(() {
      mockRepository = MockBuyerRepository();
      getMyDemandsUseCase = GetMyDemandsUseCase(mockRepository);
      demandProvider = DemandProvider(
        buyerRepository: mockRepository,
        getMyDemandsUseCase: getMyDemandsUseCase,
      );
    });

    test('GetMyDemandsUseCase calls repository with curl query parameters', () async {
      final demands = await getMyDemandsUseCase(
        page: 1,
        limit: 10,
        search: 'Potato',
        productName: 'Potato',
        minPrice: 20,
        maxPrice: 50,
        tradeType: 'both',
        status: 'active',
        token: 'curl_bearer_token',
      );

      expect(demands.length, 1);
      expect(demands.first.productName, 'Potato');
      expect(demands.first.callingPrice, 28);
      expect(demands.first.quantity, 1000);

      expect(mockRepository.lastGetMyDemandsParams?['page'], 1);
      expect(mockRepository.lastGetMyDemandsParams?['limit'], 10);
      expect(mockRepository.lastGetMyDemandsParams?['search'], 'Potato');
      expect(mockRepository.lastGetMyDemandsParams?['productName'], 'Potato');
      expect(mockRepository.lastGetMyDemandsParams?['minPrice'], 20);
      expect(mockRepository.lastGetMyDemandsParams?['maxPrice'], 50);
      expect(mockRepository.lastGetMyDemandsParams?['tradeType'], 'both');
      expect(mockRepository.lastGetMyDemandsParams?['status'], 'active');
      expect(mockRepository.lastGetMyDemandsParams?['token'], 'curl_bearer_token');
    });

    test('DemandProvider fetchMyDemands updates state correctly', () async {
      expect(demandProvider.myDemands, isEmpty);
      expect(demandProvider.isMyDemandsLoading, isFalse);

      final future = demandProvider.fetchMyDemands(
        page: 1,
        limit: 10,
        search: 'Potato',
        productName: 'Potato',
        minPrice: 20,
        maxPrice: 50,
        tradeType: 'both',
        status: 'active',
      );

      await future;

      expect(demandProvider.isMyDemandsLoading, isFalse);
      expect(demandProvider.myDemandsError, isNull);
      expect(demandProvider.myDemands.length, 1);
      expect(demandProvider.myDemands.first.productName, 'Potato');
      expect(demandProvider.myDemands.first.callingPrice, 28);
    });

    testWidgets('BuyerHomeScreen displays My Demands section and renders fetched demand', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authProvider = AuthProvider();
      final productProvider = ProductProvider();
      final groupProvider = GroupProvider();
      final orderProvider = OrderProvider();
      final appStateProvider = AppStateProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DemandProvider>.value(value: demandProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
            ChangeNotifierProvider<GroupProvider>.value(value: groupProvider),
            ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
            ChangeNotifierProvider<AppStateProvider>.value(value: appStateProvider),
          ],
          child: const MaterialApp(
            home: BuyerHomeScreen(),
          ),
        ),
      );

      // Trigger post frame callback for fetchMyDemands
      await tester.pumpAndSettle();

      // Verify My Demands header and filter pills are rendered
      expect(find.text('My Demands'), findsOneWidget);
      expect(find.text('Potato'), findsWidgets);
      expect(find.text('৳20 - ৳50'), findsOneWidget);
      expect(find.text('Trade: Both'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);

      // Verify the fetched demand is displayed
      expect(find.text('Karwan Bazar, Dhaka'), findsWidgets);
      expect(find.text('1000.0 KG'), findsWidgets);

      // Verify repository was called with curl defaults
      expect(mockRepository.lastGetMyDemandsParams?['search'], 'Potato');
      expect(mockRepository.lastGetMyDemandsParams?['productName'], 'Potato');
      expect(mockRepository.lastGetMyDemandsParams?['minPrice'], 20);
      expect(mockRepository.lastGetMyDemandsParams?['maxPrice'], 50);
      expect(mockRepository.lastGetMyDemandsParams?['tradeType'], 'both');
      expect(mockRepository.lastGetMyDemandsParams?['status'], 'active');
    });
  });
}
