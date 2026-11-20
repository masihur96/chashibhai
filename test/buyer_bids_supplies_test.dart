import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chashibhai/core/models/models.dart';
import 'package:chashibhai/core/services/upload_service.dart';
import 'package:chashibhai/features/account/presentation/state/app_state_provider.dart';
import 'package:chashibhai/features/auth/presentation/state/auth_provider.dart';
import 'package:chashibhai/features/buyer/data/models/create_demand_request_model.dart';
import 'package:chashibhai/features/buyer/data/models/create_bid_request_model.dart';
import 'package:chashibhai/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:chashibhai/features/account/presentation/state/review_provider.dart';
import 'package:chashibhai/features/buyer/domain/usecases/create_bid_usecase.dart';
import 'package:chashibhai/features/buyer/domain/usecases/get_product_bids_usecase.dart';
import 'package:chashibhai/features/buyer/presentation/state/demand_provider.dart';
import 'package:chashibhai/features/buyer/presentation/state/product_provider.dart';
import 'package:chashibhai/features/buyer/presentation/views/buyer_home.dart';
import 'package:chashibhai/features/buyer/presentation/views/product_details.dart';
import 'package:chashibhai/features/group/presentation/state/group_provider.dart';
import 'package:chashibhai/features/wallet/presentation/state/order_provider.dart';

class TestMockBuyerRepository implements BuyerRepository {
  CreateBidRequestModel? lastBidRequest;
  String? lastBidToken;

  final Product testTargetProduct = Product(
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
  );

  @override
  Future<Bid> createBid({
    required CreateBidRequestModel request,
    String? token,
  }) async {
    lastBidRequest = request;
    lastBidToken = token;
    return Bid(
      id: 'b_test_created_1',
      productId: request.productId,
      buyerId: '395e2439-099f-41da-a739-019f5a08e504',
      amount: request.amount,
      createdAt: DateTime.now(),
      status: 'active',
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
    return [testTargetProduct];
  }

  @override
  Future<Product?> getProductById({
    required String id,
    String? token,
  }) async {
    if (id == testTargetProduct.id) return testTargetProduct;
    return null;
  }

  @override
  Future<DemandPost> createDemand({
    required CreateDemandRequestModel request,
    String? token,
  }) async {
    throw UnimplementedError();
  }

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
    return [];
  }

  @override
  Future<List<String>> uploadImages({
    required List<UploadFileItem> files,
    String? token,
  }) async {
    return [];
  }

  String? lastGetBidsProductId;
  String? lastGetBidsToken;

  @override
  Future<List<Bid>> getBidsByProductId({
    required String productId,
    String? token,
  }) async {
    lastGetBidsProductId = productId;
    lastGetBidsToken = token;
    return [
      Bid(
        id: 'b_fetched_1',
        productId: productId,
        buyerId: '395e2439-099f-41da-a739-019f5a08e504',
        amount: 65.0,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        bidderName: 'Masihur Rahman',
      ),
      Bid(
        id: 'b_fetched_2',
        productId: productId,
        buyerId: 'b_competitor',
        amount: 60.0,
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        bidderName: 'Karim Trader',
      ),
    ];
  }

  @override
  Future<List<Negotiation>> getMyNegotiations({
    String? token,
  }) async {
    return [
      Negotiation(
        id: 'neg_test_1',
        productId: 'p3',
        productName: 'Vine Ripened Tomatoes',
        productImageUrl: 'assets/images/tomato.png',
        farmerId: 'f1',
        farmerName: 'Farmer Abdul',
        buyerId: '395e2439-099f-41da-a739-019f5a08e504',
        buyerName: 'Masihur Rahman',
        offerPrice: 72.0,
        counterPrice: 75.0,
        status: NegotiationStatus.countered,
        message: 'Can we settle on ৳72?',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }
}

void main() {
  group('Buyer Available Supplies & Bids Feature Tests', () {
    late TestMockBuyerRepository mockRepository;
    late CreateBidUseCase createBidUseCase;
    late DemandProvider demandProvider;
    late ProductProvider productProvider;

    setUp(() {
      mockRepository = TestMockBuyerRepository();
      createBidUseCase = CreateBidUseCase(mockRepository);
      final getProductBidsUseCase = GetProductBidsUseCase(mockRepository);
      demandProvider = DemandProvider(
        buyerRepository: mockRepository,
        createBidUseCase: createBidUseCase,
        getProductBidsUseCase: getProductBidsUseCase,
      );
      productProvider = ProductProvider(
        buyerRepository: mockRepository,
      );
    });

    test('CreateBidRequestModel serializes with both productId and product_id for curl specs', () {
      const model = CreateBidRequestModel(
        productId: 'ee9ac1a6-bb66-45d0-a6de-8e390702be0e',
        amount: 55,
      );
      final json = model.toJson();

      expect(json['productId'], 'ee9ac1a6-bb66-45d0-a6de-8e390702be0e');
      expect(json['product_id'], 'ee9ac1a6-bb66-45d0-a6de-8e390702be0e');
      expect(json['amount'], 55);
    });

    test('DemandProvider placeBid calls repository and prepends bid to list', () async {
      const curlToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTE1MDM5OCwiZXhwIjoxNzk1MTUxMjk4fQ.7JodOSM6L_8q748GQJ1MUVqtfSEl8_xeDSiJKjiHcFA';

      final newBid = await demandProvider.placeBid(
        productId: 'ee9ac1a6-bb66-45d0-a6de-8e390702be0e',
        amount: 55,
        token: curlToken,
      );

      expect(mockRepository.lastBidRequest?.productId, 'ee9ac1a6-bb66-45d0-a6de-8e390702be0e');
      expect(mockRepository.lastBidRequest?.amount, 55);
      expect(mockRepository.lastBidToken, curlToken);

      expect(demandProvider.bids.first.id, newBid.id);
      expect(demandProvider.bids.first.amount, 55);
    });

    test('ProductProvider fetchAvailableProducts populates products with target product', () async {
      expect(productProvider.isAvailableProductsLoading, isFalse);

      final products = await productProvider.fetchAvailableProducts();

      expect(productProvider.isAvailableProductsLoading, isFalse);
      expect(productProvider.availableProductsError, isNull);
      expect(products.any((p) => p.id == 'ee9ac1a6-bb66-45d0-a6de-8e390702be0e'), isTrue);
    });

    testWidgets('BuyerHomeScreen renders Available Supplies with curl chips and target item', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authProvider = AuthProvider();
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

      await tester.pumpAndSettle();

      // Verify curl indicator badges for available supplies
      expect(find.text('POST /api/v1/bids'), findsOneWidget);
      expect(find.text('Target: ee9ac1a6...'), findsOneWidget);
      expect(find.text('Bid: ৳55'), findsOneWidget);
      expect(find.text('Role: Buyer'), findsOneWidget);

      // Verify Featured Supply Card components
      expect(find.text('LIVE AUCTION SUPPLY'), findsOneWidget);
      expect(find.text('Target Item'), findsOneWidget);
      expect(find.text('Fresh Diamond Potatoes'), findsWidgets);
      expect(find.text('Quick Bid ৳55'), findsOneWidget);
      expect(find.text('Place Bid'), findsWidgets);

      // Trigger Quick Bid ৳55
      await tester.tap(find.text('Quick Bid ৳55'));
      await tester.pumpAndSettle();

      expect(mockRepository.lastBidRequest?.productId, 'ee9ac1a6-bb66-45d0-a6de-8e390702be0e');
      expect(mockRepository.lastBidRequest?.amount, 55.0);
    });

    test('GetProductBidsUseCase calls repository with curl productId and token', () async {
      final getProductBidsUseCase = GetProductBidsUseCase(mockRepository);
      const testProductId = 'ea374c5d-7edf-49b4-af27-a8ebce966ed3';
      const testToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTE1ODI5NSwiZXhwIjoxNzk1MTU5MTk1fQ.xJWsu_m_q470KTzWo_CajAUzig4lRpTw4sbhbF6gOMc';

      final bids = await getProductBidsUseCase(
        productId: testProductId,
        token: testToken,
      );

      expect(mockRepository.lastGetBidsProductId, testProductId);
      expect(mockRepository.lastGetBidsToken, testToken);
      expect(bids.length, 2);
      expect(bids.first.amount, 65.0);
      expect(bids.first.bidderName, 'Masihur Rahman');
    });

    test('DemandProvider fetchProductBids loads bids, sorts descending, and updates state', () async {
      const testProductId = 'ea374c5d-7edf-49b4-af27-a8ebce966ed3';
      expect(demandProvider.isProductBidsLoading, isFalse);

      final fetched = await demandProvider.fetchProductBids(productId: testProductId);

      expect(demandProvider.isProductBidsLoading, isFalse);
      expect(demandProvider.productBidsError, isNull);
      expect(fetched.length, 2);
      expect(fetched.first.amount, 65.0);
      expect(fetched[1].amount, 60.0);

      final productBids = demandProvider.getProductBids(testProductId);
      expect(productBids.length, 2);
      expect(productBids.first.amount, 65.0);
    });

    testWidgets('ProductDetailsScreen displays Live Auction section with curl endpoint and leaderboard', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testProduct = Product(
        id: 'ea374c5d-7edf-49b4-af27-a8ebce966ed3',
        farmerId: 'f1',
        productName: 'Premium Fresh Potatoes',
        imageUrl: 'assets/images/potato.png',
        quantity: 800,
        unit: 'KG',
        minimumPrice: 50.0,
        tradeType: TradeType.auction,
        startTime: DateTime.now().subtract(const Duration(hours: 4)),
        endTime: DateTime.now().add(const Duration(days: 2)),
        category: 'Vegetables',
      );

      final authProvider = AuthProvider();
      final reviewProvider = ReviewProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DemandProvider>.value(value: demandProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
            ChangeNotifierProvider<ReviewProvider>.value(value: reviewProvider),
          ],
          child: MaterialApp(
            home: ProductDetailsScreen(product: testProduct),
          ),
        ),
      );

      // Settle frame for initial bid fetch
      await tester.pumpAndSettle();

      // Verify curl endpoint chip
      expect(find.text('GET /api/v1/bids/product/ea374c5d-7edf-49b4-af27-a8ebce966ed3'), findsOneWidget);

      // Verify Live Auction UI components
      expect(find.text('Live Auction'), findsOneWidget);
      expect(find.text('Ends in 12h 30m'), findsOneWidget);
      expect(find.text('HIGHEST BID'), findsOneWidget);
      expect(find.text('STARTING PRICE'), findsOneWidget);
      expect(find.text('TOTAL BIDS'), findsOneWidget);

      // Verify Leaderboard items
      expect(find.text('Auction Leaderboard'), findsOneWidget);
      expect(find.text('Masihur Rahman'), findsOneWidget);
      expect(find.text('HIGHEST'), findsOneWidget);
      expect(find.text('Karim Trader'), findsOneWidget);
      expect(find.text('৳65'), findsWidgets);
      expect(find.text('৳60'), findsOneWidget);

      // Verify bottom action button
      expect(find.text('Place Bid'), findsOneWidget);
    });
  });
}
