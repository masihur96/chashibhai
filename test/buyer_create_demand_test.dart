import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chashibhai/core/models/models.dart';
import 'package:chashibhai/features/auth/presentation/state/auth_provider.dart';
import 'package:chashibhai/features/group/presentation/state/group_provider.dart';
import 'package:chashibhai/features/buyer/data/models/create_demand_request_model.dart';
import 'package:chashibhai/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:chashibhai/features/buyer/domain/usecases/create_demand_usecase.dart';
import 'package:chashibhai/features/buyer/presentation/state/demand_provider.dart';
import 'package:chashibhai/features/buyer/presentation/views/post_demand_screen.dart';

class MockBuyerRepository implements BuyerRepository {
  CreateDemandRequestModel? lastRequest;
  String? lastToken;

  @override
  Future<DemandPost> createDemand({
    required CreateDemandRequestModel request,
    String? token,
  }) async {
    lastRequest = request;
    lastToken = token;

    return DemandPost(
      id: 'd_test_123',
      buyerId: 'buyer_test',
      productName: request.productName,
      quantity: request.quantity,
      callingPrice: request.callingPrice,
      deliveryLocation: request.deliveryLocation,
      expiryTime: request.expiryTime,
      status: DemandStatus.active,
      tradeType: request.tradeType == 'both'
          ? TradeType.both
          : (request.tradeType == 'auction'
              ? TradeType.auction
              : TradeType.negotiation),
      imageUrl: request.imageUrl,
    );
  }
}

void main() {
  group('Create Demand Feature Tests', () {
    late MockBuyerRepository mockRepository;
    late CreateDemandUseCase createDemandUseCase;
    late DemandProvider demandProvider;

    setUp(() {
      mockRepository = MockBuyerRepository();
      createDemandUseCase = CreateDemandUseCase(mockRepository);
      demandProvider = DemandProvider(
        buyerRepository: mockRepository,
        createDemandUseCase: createDemandUseCase,
      );
    });

    test('CreateDemandRequestModel produces correct json matching curl', () {
      final expiry = DateTime.parse('2026-11-30T18:00:00Z');
      final request = CreateDemandRequestModel(
        productName: 'Potatoes (Diamant)',
        quantity: 1000,
        callingPrice: 28,
        deliveryLocation: 'Karwan Bazar, Dhaka',
        expiryTime: expiry,
        tradeType: 'both',
        imageUrl: 'https://cdn.example.com/demands/potato.jpg',
      );

      final json = request.toJson();

      expect(json['productName'], 'Potatoes (Diamant)');
      expect(json['product_name'], 'Potatoes (Diamant)');
      expect(json['quantity'], 1000);
      expect(json['callingPrice'], 28);
      expect(json['calling_price'], 28);
      expect(json['deliveryLocation'], 'Karwan Bazar, Dhaka');
      expect(json['delivery_location'], 'Karwan Bazar, Dhaka');
      expect(json['expiryTime'], '2026-11-30T18:00:00.000Z');
      expect(json['expiry_time'], '2026-11-30T18:00:00.000Z');
      expect(json['tradeType'], 'both');
      expect(json['trade_type'], 'both');
      expect(json['imageUrl'], 'https://cdn.example.com/demands/potato.jpg');
      expect(json['image_url'], 'https://cdn.example.com/demands/potato.jpg');
    });

    test('CreateDemandUseCase calls repository and adds to DemandProvider', () async {
      final expiry = DateTime.parse('2026-11-30T18:00:00Z');
      final request = CreateDemandRequestModel(
        productName: 'Potatoes (Diamant)',
        quantity: 1000,
        callingPrice: 28,
        deliveryLocation: 'Karwan Bazar, Dhaka',
        expiryTime: expiry,
        tradeType: 'both',
        imageUrl: 'https://cdn.example.com/demands/potato.jpg',
      );

      final demand = await demandProvider.createDemand(
        request: request,
        token: 'test_token',
      );

      expect(demand.id, 'd_test_123');
      expect(demand.productName, 'Potatoes (Diamant)');
      expect(demand.quantity, 1000);
      expect(demand.callingPrice, 28);
      expect(demand.deliveryLocation, 'Karwan Bazar, Dhaka');
      expect(demand.tradeType, TradeType.both);
      expect(demand.imageUrl, 'https://cdn.example.com/demands/potato.jpg');

      expect(demandProvider.demands.first.id, 'd_test_123');
      expect(mockRepository.lastRequest?.productName, 'Potatoes (Diamant)');
      expect(mockRepository.lastToken, 'test_token');
    });

    testWidgets('PostDemandScreen renders curl defaults and publishes demand', (WidgetTester tester) async {
      final authProvider = AuthProvider();
      final groupProvider = GroupProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DemandProvider>.value(value: demandProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<GroupProvider>.value(value: groupProvider),
          ],
          child: const MaterialApp(
            home: PostDemandScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify curl defaults are pre-populated
      expect(find.text('Post Buying Demand'), findsOneWidget);
      expect(find.text('Potatoes (Diamant)'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.text('Karwan Bazar, Dhaka'), findsOneWidget);
      expect(find.text('BOTH'), findsOneWidget);

      // Scroll into view and tap Publish Demand button
      final publishBtn = find.widgetWithText(ElevatedButton, 'Publish Demand');
      expect(publishBtn, findsOneWidget);
      await tester.ensureVisible(publishBtn);
      await tester.tap(publishBtn);
      await tester.pumpAndSettle();

      // Verify mock repository received the request
      expect(mockRepository.lastRequest?.productName, 'Potatoes (Diamant)');
      expect(mockRepository.lastRequest?.quantity, 1000);
      expect(mockRepository.lastRequest?.callingPrice, 28);
      expect(mockRepository.lastRequest?.deliveryLocation, 'Karwan Bazar, Dhaka');
      expect(mockRepository.lastRequest?.tradeType, 'both');
      expect(mockRepository.lastRequest?.imageUrl, 'https://cdn.example.com/demands/potato.jpg');
    });
  });
}
