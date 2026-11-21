import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:chashibhai/core/models/models.dart';
import 'package:chashibhai/features/account/presentation/state/app_state_provider.dart';
import 'package:chashibhai/features/auth/presentation/state/auth_provider.dart';
import 'package:chashibhai/features/buyer/data/models/create_bid_request_model.dart';
import 'package:chashibhai/features/buyer/data/models/create_demand_offer_request_model.dart';
import 'package:chashibhai/features/buyer/data/models/create_demand_request_model.dart';
import 'package:chashibhai/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:chashibhai/features/buyer/domain/usecases/get_my_demands_usecase.dart';
import 'package:chashibhai/features/buyer/presentation/state/demand_provider.dart';
import 'package:chashibhai/features/buyer/presentation/views/my_demands_screen.dart';

class MockBuyerRepositoryForMyDemands implements BuyerRepository {
  List<DemandPost> testDemands = [];

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
    return testDemands;
  }

  @override
  Future<List<DemandOffer>> getDemandOffers({
    required String demandId,
    String? token,
  }) async {
    if (demandId == 'd1') {
      return [
        DemandOffer(
          id: 'off_1',
          demandId: 'd1',
          farmerId: 'f1',
          offerPrice: 26.5,
          createdAt: DateTime.now(),
        ),
        DemandOffer(
          id: 'off_2',
          demandId: 'd1',
          farmerId: 'f2',
          offerPrice: 27.0,
          createdAt: DateTime.now(),
        ),
      ];
    }
    return [];
  }

  @override
  Future<DemandPost> getDemandById({
    required String demandId,
    String? token,
  }) async {
    return testDemands.firstWhere((d) => d.id == demandId);
  }

  @override
  Future<DemandPost> createDemand({
    required CreateDemandRequestModel request,
    String? token,
  }) async => throw UnimplementedError();

  @override
  Future<Bid> createBid({
    required CreateBidRequestModel request,
    String? token,
  }) async => throw UnimplementedError();

  @override
  Future<List<DemandPost>> getDemands({
    int page = 1,
    int limit = 10,
    String? tradeType = 'both',
    String? status = 'active',
    String? search,
    String? token,
  }) async => [];

  @override
  Future<List<Product>> getAvailableProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String? token,
  }) async => [];

  @override
  Future<Product?> getProductById({required String id, String? token}) async => null;

  @override
  Future<DemandOffer> submitDemandOffer({
    required String demandId,
    required CreateDemandOfferRequestModel request,
    String? token,
  }) async => throw UnimplementedError();

  @override
  Future<AcceptDemandOfferResult> acceptDemandOffer({
    required String demandId,
    required String offerId,
    String? token,
  }) async => throw UnimplementedError();

  @override
  Future<List<Bid>> getBidsByProductId({required String productId, String? token}) async => [];

  @override
  Future<List<Bid>> getMyBids({String? token}) async => [];

  @override
  Future<List<Negotiation>> getMyNegotiations({String? token}) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('MyDemandsScreen Professional UI & Filtering Tests', () {
    late MockBuyerRepositoryForMyDemands mockRepo;
    late DemandProvider demandProvider;
    late AuthProvider authProvider;
    late AppStateProvider appStateProvider;

    final sampleDemands = [
      DemandPost(
        id: 'd1',
        buyerId: 'buyer_1',
        productName: 'Fresh Diamant Potato',
        quantity: 1500,
        callingPrice: 28,
        deliveryLocation: 'Karwan Bazar, Dhaka',
        expiryTime: DateTime.now().add(const Duration(days: 3)),
        status: DemandStatus.active,
        tradeType: TradeType.both,
        imageUrl: '',
        offersCount: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      DemandPost(
        id: 'd2',
        buyerId: 'buyer_1',
        productName: 'Miniket Rice',
        quantity: 2000,
        callingPrice: 65,
        deliveryLocation: 'Santahar, Bogura',
        expiryTime: DateTime.now().subtract(const Duration(days: 1)),
        status: DemandStatus.expired,
        tradeType: TradeType.auction,
        imageUrl: '',
        offersCount: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      DemandPost(
        id: 'd3',
        buyerId: 'buyer_1',
        productName: 'Red Onion',
        quantity: 500,
        callingPrice: 90,
        deliveryLocation: 'Khatunganj, Chattogram',
        expiryTime: DateTime.now().add(const Duration(days: 10)),
        status: DemandStatus.fulfilled,
        tradeType: TradeType.negotiation,
        imageUrl: '',
        offersCount: 4,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    setUp(() {
      mockRepo = MockBuyerRepositoryForMyDemands();
      demandProvider = DemandProvider(
        buyerRepository: mockRepo,
        getMyDemandsUseCase: GetMyDemandsUseCase(mockRepo),
      );
      authProvider = AuthProvider();
      appStateProvider = AppStateProvider();
    });

    testWidgets('Renders pure empty state when user has 0 demands', (WidgetTester tester) async {
      mockRepo.testDemands = [];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DemandProvider>.value(value: demandProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<AppStateProvider>.value(value: appStateProvider),
          ],
          child: const MaterialApp(
            home: MyDemandsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Demands'), findsOneWidget);
      expect(find.text('No Demands Posted Yet'), findsOneWidget);
      expect(find.text('Post Your First Demand'), findsOneWidget);
    });

    testWidgets('Renders KPI statistics bar and demand list cards', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockRepo.testDemands = sampleDemands;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DemandProvider>.value(value: demandProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<AppStateProvider>.value(value: appStateProvider),
          ],
          child: const MaterialApp(
            home: MyDemandsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check App Bar & Subtitle
      expect(find.text('My Demands'), findsOneWidget);
      expect(find.text('Showing 3 of 3 demands'), findsOneWidget);

      // Check KPI Summary Counts
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Offers'), findsOneWidget);
      expect(find.text('6'), findsOneWidget); // Total offers (2 + 0 + 4)
      expect(find.text('Fulfilled'), findsWidgets);
      expect(find.textContaining('days left'), findsWidgets);

      // Check Cards
      expect(find.text('Fresh Diamant Potato'), findsOneWidget);
      expect(find.text('Miniket Rice'), findsOneWidget);
      expect(find.text('Red Onion'), findsOneWidget);

      // Check Calling Prices and Quantities
      expect(find.text('৳28 / KG'), findsOneWidget);
      expect(find.text('1500 KG'), findsOneWidget);
      expect(find.text('Karwan Bazar, Dhaka'), findsOneWidget);
      expect(find.text('2 Offers Received'), findsOneWidget);
    });

    testWidgets('Search query filters demands dynamically in real-time', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockRepo.testDemands = sampleDemands;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DemandProvider>.value(value: demandProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<AppStateProvider>.value(value: appStateProvider),
          ],
          child: const MaterialApp(
            home: MyDemandsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search text "Potato"
      await tester.enterText(find.byType(TextField).first, 'Potato');
      await tester.pumpAndSettle();

      // Only Potato should be visible
      expect(find.text('Fresh Diamant Potato'), findsOneWidget);
      expect(find.text('Miniket Rice'), findsNothing);
      expect(find.text('Red Onion'), findsNothing);
      expect(find.text('Showing 1 of 3 demands'), findsOneWidget);

      // Clear search
      await tester.tap(find.byIcon(Icons.cancel_rounded));
      await tester.pumpAndSettle();

      // All 3 should be back
      expect(find.text('Fresh Diamant Potato'), findsOneWidget);
      expect(find.text('Miniket Rice'), findsOneWidget);
      expect(find.text('Red Onion'), findsOneWidget);
    });

    testWidgets('Quick status chips filter demands', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockRepo.testDemands = sampleDemands;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DemandProvider>.value(value: demandProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<AppStateProvider>.value(value: appStateProvider),
          ],
          child: const MaterialApp(
            home: MyDemandsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Fulfilled" FilterChip
      final fulfilledChip = find.widgetWithText(FilterChip, 'Fulfilled');
      expect(fulfilledChip, findsOneWidget);
      await tester.tap(fulfilledChip);
      await tester.pumpAndSettle();

      // Only Red Onion (fulfilled) should be shown
      expect(find.text('Red Onion'), findsOneWidget);
      expect(find.text('Fresh Diamant Potato'), findsNothing);
      expect(find.text('Miniket Rice'), findsNothing);

      // Tap "With Offers" FilterChip
      final withOffersChip = find.widgetWithText(FilterChip, 'With Offers');
      expect(withOffersChip, findsOneWidget);
      await tester.tap(withOffersChip);
      await tester.pumpAndSettle();

      expect(find.text('Red Onion'), findsOneWidget);
    });

    testWidgets('Shows filtered empty state with reset button when no results match', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      mockRepo.testDemands = sampleDemands;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DemandProvider>.value(value: demandProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<AppStateProvider>.value(value: appStateProvider),
          ],
          child: const MaterialApp(
            home: MyDemandsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search text that matches nothing
      await tester.enterText(find.byType(TextField).first, 'Watermelon NonExistent');
      await tester.pumpAndSettle();

      expect(find.text('No Demands Match Your Filters'), findsOneWidget);
      expect(find.text('Reset All Filters'), findsOneWidget);

      // Tap "Reset All Filters"
      await tester.tap(find.text('Reset All Filters'));
      await tester.pumpAndSettle();

      // Results should be restored
      expect(find.text('Fresh Diamant Potato'), findsOneWidget);
      expect(find.text('Miniket Rice'), findsOneWidget);
      expect(find.text('Red Onion'), findsOneWidget);
    });
  });
}
