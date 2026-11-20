import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chashibhai/core/models/models.dart';
import 'package:chashibhai/core/services/upload_service.dart';
import 'package:chashibhai/features/auth/presentation/state/auth_provider.dart';
import 'package:chashibhai/features/buyer/data/models/create_demand_request_model.dart';
import 'package:chashibhai/features/buyer/data/models/create_bid_request_model.dart';
import 'package:chashibhai/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:chashibhai/features/buyer/domain/usecases/get_my_negotiations_usecase.dart';
import 'package:chashibhai/features/buyer/presentation/state/negotiation_provider.dart';
import 'package:chashibhai/features/buyer/presentation/views/negotiations_list_screen.dart';

class TestNegotiationsMockRepository implements BuyerRepository {
  String? lastToken;

  final List<Negotiation> mockList = [
    Negotiation(
      id: 'neg_test_01',
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
      message: 'Can we settle on ৳72 for 150 KG?',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Negotiation(
      id: 'neg_test_02',
      productId: 'p1',
      productName: 'Organic Potatoes',
      productImageUrl: 'assets/images/potato.png',
      farmerId: 'f1',
      farmerName: 'Farmer Abdul',
      buyerId: '395e2439-099f-41da-a739-019f5a08e504',
      buyerName: 'Masihur Rahman',
      offerPrice: 32.0,
      counterPrice: 32.0,
      status: NegotiationStatus.accepted,
      message: 'Deal confirmed at ৳32/KG.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<Negotiation>> getMyNegotiations({String? token}) async {
    lastToken = token;
    return mockList;
  }

  @override
  Future<List<Bid>> getBidsByProductId({required String productId, String? token}) async => [];

  @override
  Future<List<Bid>> getMyBids({String? token}) async => [];

  @override
  Future<Bid> createBid({required CreateBidRequestModel request, String? token}) async {
    throw UnimplementedError();
  }

  @override
  Future<DemandPost> createDemand({required CreateDemandRequestModel request, String? token}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Product>> getAvailableProducts({int page = 1, int limit = 20, String? category, String? search, String? token}) async => [];

  @override
  Future<List<DemandPost>> getMyDemands({int page = 1, int limit = 10, String? search, String? productName, double? minPrice, double? maxPrice, String? tradeType, String? status, String? token}) async => [];

  @override
  Future<Product?> getProductById({required String id, String? token}) async => null;

  @override
  Future<List<String>> uploadImages({required List<UploadFileItem> files, String? token}) async => [];
}

void main() {
  group('Buyer Negotiations Feature Tests', () {
    late TestNegotiationsMockRepository mockRepository;
    late GetMyNegotiationsUseCase getMyNegotiationsUseCase;
    late NegotiationProvider negotiationProvider;

    setUp(() {
      mockRepository = TestNegotiationsMockRepository();
      getMyNegotiationsUseCase = GetMyNegotiationsUseCase(mockRepository);
      negotiationProvider = NegotiationProvider(
        buyerRepository: mockRepository,
        getMyNegotiationsUseCase: getMyNegotiationsUseCase,
      );
    });

    test('GetMyNegotiationsUseCase calls repository and passes curl token', () async {
      const curlToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzOTVlMjQzOS0wOTlmLTQxZGEtYTczOS0wMTlmNWEwOGU1MDQiLCJwaG9uZSI6Ijg4MDE0MDcwNzAzMTEiLCJlbWFpbCI6IiIsInJvbGUiOiJidXllciIsImlhdCI6MTc5NTE2MDc1NCwiZXhwIjoxNzk1MTYxNjU0fQ.jgyCtzVA9VRSEncgD72S_SCSaeIBQ5LLN_O4oUKOVWA';

      final results = await getMyNegotiationsUseCase(token: curlToken);

      expect(mockRepository.lastToken, curlToken);
      expect(results.length, 2);
      expect(results.first.productName, 'Vine Ripened Tomatoes');
      expect(results.first.offerPrice, 72.0);
      expect(results.first.counterPrice, 75.0);
      expect(results.first.status, NegotiationStatus.countered);
    });

    test('NegotiationProvider fetchMyNegotiations updates list and metrics correctly', () async {
      expect(negotiationProvider.isLoading, isFalse);

      final fetched = await negotiationProvider.fetchMyNegotiations();

      expect(negotiationProvider.isLoading, isFalse);
      expect(negotiationProvider.errorMessage, isNull);
      expect(fetched.length, 2);
      expect(negotiationProvider.counteredCount, 1);
      expect(negotiationProvider.acceptedCount, 1);
      expect(negotiationProvider.pendingCount, 0);

      // Test status filter
      negotiationProvider.setSelectedStatus('Countered');
      expect(negotiationProvider.filteredNegotiations.length, 1);
      expect(negotiationProvider.filteredNegotiations.first.id, 'neg_test_01');

      negotiationProvider.setSelectedStatus('Accepted');
      expect(negotiationProvider.filteredNegotiations.length, 1);
      expect(negotiationProvider.filteredNegotiations.first.id, 'neg_test_02');

      negotiationProvider.setSelectedStatus('All');
      expect(negotiationProvider.filteredNegotiations.length, 2);
    });

    test('NegotiationProvider acceptCounterOffer updates deal to accepted', () async {
      await negotiationProvider.fetchMyNegotiations();

      negotiationProvider.acceptCounterOffer('neg_test_01');

      final updated = negotiationProvider.negotiations.firstWhere((n) => n.id == 'neg_test_01');
      expect(updated.status, NegotiationStatus.accepted);
      expect(updated.offerPrice, 75.0);
      expect(negotiationProvider.acceptedCount, 2);
    });

    testWidgets('NegotiationsListScreen displays curl endpoint pill, summary cards, and negotiation list', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authProvider = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<NegotiationProvider>.value(value: negotiationProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(
            home: NegotiationsListScreen(),
          ),
        ),
      );

      // Settle frame for initial fetch
      await tester.pumpAndSettle();

      // Verify header and endpoint chip
      expect(find.text('My Negotiations'), findsOneWidget);
      expect(find.text('/api/v1/negotiations/my'), findsOneWidget);

      // Verify summary metrics
      expect(find.text('Pending'), findsWidgets);
      expect(find.text('Countered'), findsWidgets);
      expect(find.text('Accepted'), findsWidgets);

      // Verify items from mock repository
      expect(find.text('Vine Ripened Tomatoes'), findsOneWidget);
      expect(find.text('Farmer Abdul'), findsWidgets);
      expect(find.text('Organic Potatoes'), findsOneWidget);
      expect(find.text('Accept Deal'), findsOneWidget);

      // Tap Accept Deal
      await tester.tap(find.text('Accept Deal'));
      await tester.pumpAndSettle();

      expect(negotiationProvider.acceptedCount, 2);
    });
  });
}
