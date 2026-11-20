import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chashibhai/core/models/models.dart';
import 'package:chashibhai/core/services/upload_service.dart';
import 'package:chashibhai/features/auth/presentation/state/auth_provider.dart';
import 'package:chashibhai/features/group/presentation/state/group_provider.dart';
import 'package:chashibhai/features/buyer/data/models/create_demand_request_model.dart';
import 'package:chashibhai/features/buyer/data/models/create_bid_request_model.dart';
import 'package:chashibhai/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:chashibhai/features/buyer/domain/usecases/create_demand_usecase.dart';
import 'package:chashibhai/features/buyer/presentation/state/demand_provider.dart';
import 'package:chashibhai/features/buyer/presentation/views/post_demand_screen.dart';

// Valid 1x1 transparent PNG bytes for Flutter test image codec
final Uint8List samplePngBytes = Uint8List.fromList([
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1,
  0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 11, 73, 68, 65, 84,
  120, 156, 99, 96, 0, 0, 0, 2, 0, 1, 244, 113, 100, 166, 0, 0, 0, 0, 73, 69,
  78, 68, 174, 66, 96, 130
]);

class MockBuyerRepository implements BuyerRepository {
  CreateDemandRequestModel? lastRequest;
  String? lastToken;
  List<UploadFileItem>? lastUploadedFiles;
  List<String> mockUploadUrls = [
    'https://nimydnehbwyorkpefbgr.supabase.co/storage/v1/object/public/product-images/demands/test_potato.jpg'
  ];

  @override
  Future<List<String>> uploadImages({
    required List<UploadFileItem> files,
    String? token,
  }) async {
    lastUploadedFiles = List.from(files);
    lastToken = token;
    return mockUploadUrls;
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

  @override
  Future<Bid> createBid({
    required CreateBidRequestModel request,
    String? token,
  }) async {
    return Bid(
      id: 'b_mock_create',
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
    return [];
  }

  @override
  Future<Product?> getProductById({
    required String id,
    String? token,
  }) async {
    return null;
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

    test('DemandProvider.uploadImages forwards files to repository', () async {
      final testFiles = [
        UploadFileItem.fromBytes(
          bytes: samplePngBytes,
          name: '913242608_test.jpg',
          mimeType: 'image/jpeg',
        ),
      ];

      final urls = await demandProvider.uploadImages(
        files: testFiles,
        token: 'bearer_token_abc',
      );

      expect(urls.length, 1);
      expect(urls.first, contains('test_potato.jpg'));
      expect(mockRepository.lastUploadedFiles?.first.name, '913242608_test.jpg');
      expect(mockRepository.lastToken, 'bearer_token_abc');
    });

    testWidgets('PostDemandScreen renders curl defaults and publishes demand', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
      expect(find.text('Product Image'), findsOneWidget);
      expect(find.text('Pick Image'), findsOneWidget);

      // Scroll into view and tap Publish Demand button
      final publishBtn = find.widgetWithText(ElevatedButton, 'Publish Demand');
      expect(publishBtn, findsOneWidget);
      await tester.ensureVisible(publishBtn);
      await tester.tap(publishBtn);
      await tester.pumpAndSettle();

      // Verify mock repository received the request with curl default imageUrl
      expect(mockRepository.lastRequest?.productName, 'Potatoes (Diamant)');
      expect(mockRepository.lastRequest?.quantity, 1000);
      expect(mockRepository.lastRequest?.callingPrice, 28);
      expect(mockRepository.lastRequest?.deliveryLocation, 'Karwan Bazar, Dhaka');
      expect(mockRepository.lastRequest?.tradeType, 'both');
      expect(mockRepository.lastRequest?.imageUrl, 'https://cdn.example.com/demands/potato.jpg');
    });

    testWidgets('PostDemandScreen uploads picked local image and sets imageUrl on demand publish', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      // Simulate picked image
      final state = tester.state(find.byType(PostDemandScreen)) as dynamic;
      state.setSelectedImagesForTesting([
        UploadFileItem.fromBytes(
          bytes: samplePngBytes,
          name: 'picked_potato.jpg',
          mimeType: 'image/jpeg',
        ),
      ]);
      await tester.pumpAndSettle();

      // Verify UI shows picked image information
      expect(find.text('picked_potato.jpg'), findsOneWidget);
      expect(find.text('1 image(s) picked'), findsOneWidget);
      expect(find.text('Upload Now'), findsOneWidget);

      // Tap Publish Demand
      final publishBtn = find.widgetWithText(ElevatedButton, 'Publish Demand');
      await tester.ensureVisible(publishBtn);
      await tester.tap(publishBtn);
      await tester.pumpAndSettle();

      // Verify upload was triggered with the picked image
      expect(mockRepository.lastUploadedFiles, isNotNull);
      expect(mockRepository.lastUploadedFiles!.first.name, 'picked_potato.jpg');

      // Verify demand request imageUrl was set to the uploaded URL
      expect(
        mockRepository.lastRequest?.imageUrl,
        'https://nimydnehbwyorkpefbgr.supabase.co/storage/v1/object/public/product-images/demands/test_potato.jpg',
      );
    });

    testWidgets('PostDemandScreen Upload Now button uploads picked image immediately and updates imageUrl', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      // Simulate picked image
      final state = tester.state(find.byType(PostDemandScreen)) as dynamic;
      state.setSelectedImagesForTesting([
        UploadFileItem.fromBytes(
          bytes: samplePngBytes,
          name: 'immediate_upload.jpg',
          mimeType: 'image/jpeg',
        ),
      ]);
      await tester.pumpAndSettle();

      // Tap "Upload Now" button
      final uploadNowFinder = find.text('Upload Now');
      expect(uploadNowFinder, findsOneWidget);
      await tester.ensureVisible(uploadNowFinder);
      await tester.tap(uploadNowFinder);
      await tester.pumpAndSettle();

      // Verify repository uploadImages was called
      expect(mockRepository.lastUploadedFiles?.first.name, 'immediate_upload.jpg');

      // Verify UI state changed to "Uploaded" and displays the uploaded URL
      expect(find.text('Uploaded'), findsOneWidget);
      expect(
        find.text(
          'https://nimydnehbwyorkpefbgr.supabase.co/storage/v1/object/public/product-images/demands/test_potato.jpg',
        ),
        findsOneWidget,
      );
    });
  });
}
