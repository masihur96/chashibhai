import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chashibhai/core/models/models.dart';
import 'package:chashibhai/features/account/presentation/state/app_state_provider.dart';
import 'package:chashibhai/features/auth/presentation/state/auth_provider.dart';
import 'package:chashibhai/features/buyer/data/models/create_bid_request_model.dart';
import 'package:chashibhai/features/buyer/data/models/create_demand_request_model.dart';
import 'package:chashibhai/features/buyer/data/models/create_demand_offer_request_model.dart';
import 'package:chashibhai/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:chashibhai/features/buyer/domain/usecases/get_demands_usecase.dart';
import 'package:chashibhai/features/buyer/presentation/state/product_provider.dart';
import 'package:chashibhai/features/buyer/presentation/state/demand_provider.dart';
import 'package:chashibhai/features/farmer/domain/repositories/farmer_repository.dart';
import 'package:chashibhai/features/farmer/domain/usecases/get_my_products_usecase.dart';
import 'package:chashibhai/features/farmer/presentation/views/farmer_dashboard.dart';
import 'package:chashibhai/features/farmer/data/models/create_product_request_model.dart';
import 'package:chashibhai/features/farmer/data/models/update_product_request_model.dart';
import 'package:chashibhai/core/services/upload_service.dart';

class FakeBuyerRepository implements BuyerRepository {
  Map<String, dynamic>? lastGetDemandsParams;

  @override
  Future<List<DemandPost>> getDemands({
    int page = 1,
    int limit = 10,
    String? tradeType = 'both',
    String? status = 'active',
    String? search,
    String? token,
  }) async {
    lastGetDemandsParams = {
      'page': page,
      'limit': limit,
      'tradeType': tradeType,
      'status': status,
      'search': search,
      'token': token,
    };
    return [
      DemandPost(
        id: 'dem_potato_api_1',
        buyerId: 'd51a5dec-5c96-4dcd-8f1a-01461ae605e9',
        buyerName: 'Karwan Bazar Wholesaler',
        productName: 'Potato Diamant',
        quantity: 1000,
        callingPrice: 28,
        deliveryLocation: 'Karwan Bazar, Dhaka',
        expiryTime: DateTime.now().add(const Duration(days: 4)),
        status: DemandStatus.active,
        tradeType: TradeType.both,
        imageUrl: '',
      ),
    ];
  }

  @override
  Future<DemandPost> createDemand({
    required CreateDemandRequestModel request,
    String? token,
  }) async => throw UnimplementedError();

  @override
  Future<List<String>> uploadImages({
    required List<UploadFileItem> files,
    String? token,
  }) async => [];

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
  }) async => [];

  @override
  Future<Bid> createBid({
    required CreateBidRequestModel request,
    String? token,
  }) async => throw UnimplementedError();

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
  Future<List<Bid>> getBidsByProductId({required String productId, String? token}) async => [];

  @override
  Future<List<Bid>> getMyBids({String? token}) async => [];

  @override
  Future<List<Negotiation>> getMyNegotiations({String? token}) async => [];

  @override
  Future<DemandOffer> submitDemandOffer({
    required String demandId,
    required CreateDemandOfferRequestModel request,
    String? token,
  }) async {
    return DemandOffer(
      id: 'mock_demand_offer_id',
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
  }) async => [];

  @override
  Future<DemandPost> getDemandById({
    required String demandId,
    String? token,
  }) async => throw UnimplementedError();
}

class FakeFarmerRepository implements FarmerRepository {
  @override
  Future<Product> addProduct({
    required CreateProductRequestModel request,
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
  Future<List<Product>> getMyProducts({
    int page = 1,
    int limit = 10,
    String? status,
    String? category,
    String? tradeType,
    double? minPrice,
    double? maxPrice,
    String? search,
    String? token,
  }) async {
    return [
      Product(
        id: 'p_boro_rice',
        farmerId: 'farmer_1',
        productName: 'Boro Rice',
        imageUrl: '',
        quantity: 500,
        unit: 'KG',
        minimumPrice: 45,
        tradeType: TradeType.both,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(days: 5)),
        category: 'rice',
        status: 'active',
      ),
    ];
  }

  @override
  Future<Product> getProductById({required String id, String? token}) async {
    throw UnimplementedError();
  }

  @override
  Future<Product> updateProduct({
    required String id,
    required UpdateProductRequestModel request,
    String? token,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteProduct({required String id, String? token}) async {
    return true;
  }
}

void main() {
  testWidgets('FarmerDashboard displays active listings section and products', (WidgetTester tester) async {
    final fakeRepo = FakeFarmerRepository();
    final productProvider = ProductProvider(
      farmerRepository: fakeRepo,
      getMyProductsUseCase: GetMyProductsUseCase(fakeRepo),
    );
    final authProvider = AuthProvider();
    final demandProvider = DemandProvider();
    final appStateProvider = AppStateProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<DemandProvider>.value(value: demandProvider),
          ChangeNotifierProvider<AppStateProvider>.value(value: appStateProvider),
        ],
        child: const MaterialApp(
          home: FarmerDashboard(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Your Active Listings'), findsOneWidget);
    expect(find.text('Boro Rice'), findsOneWidget);
    expect(find.text('500.0 KG listed'), findsOneWidget);
    expect(find.text('Rice (Curl Filter)'), findsOneWidget);
  });

  testWidgets('FarmerDashboard fetches and displays Buyer Demands using cURL params', (WidgetTester tester) async {
    final fakeRepo = FakeFarmerRepository();
    final fakeBuyerRepo = FakeBuyerRepository();
    final productProvider = ProductProvider(
      farmerRepository: fakeRepo,
      getMyProductsUseCase: GetMyProductsUseCase(fakeRepo),
    );
    final authProvider = AuthProvider();
    final demandProvider = DemandProvider(
      buyerRepository: fakeBuyerRepo,
      getDemandsUseCase: GetDemandsUseCase(fakeBuyerRepo),
    );
    final appStateProvider = AppStateProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<DemandProvider>.value(value: demandProvider),
          ChangeNotifierProvider<AppStateProvider>.value(value: appStateProvider),
        ],
        child: const MaterialApp(
          home: FarmerDashboard(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Buyer Demands section and cURL parameters
    expect(fakeBuyerRepo.lastGetDemandsParams, isNotNull);
    expect(fakeBuyerRepo.lastGetDemandsParams!['page'], equals(1));
    expect(fakeBuyerRepo.lastGetDemandsParams!['limit'], equals(10));
    expect(fakeBuyerRepo.lastGetDemandsParams!['tradeType'], equals('both'));
    expect(fakeBuyerRepo.lastGetDemandsParams!['status'], equals('active'));

    // Verify UI components rendered
    expect(find.text('Buyer Demands'), findsOneWidget);
    expect(find.text('Potato Diamant'), findsOneWidget);
    expect(find.text('Karwan Bazar Wholesaler'), findsOneWidget);
    expect(find.text('Karwan Bazar, Dhaka'), findsOneWidget);
    expect(find.text('1000 KG'), findsOneWidget);
    expect(find.text('৳28'), findsOneWidget);
    expect(find.text('/api/v1/demands?tradeType=both&status=active'), findsOneWidget);
  });
}
