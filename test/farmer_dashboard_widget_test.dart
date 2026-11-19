import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chashibhai/core/models/models.dart';
import 'package:chashibhai/features/account/presentation/state/app_state_provider.dart';
import 'package:chashibhai/features/auth/presentation/state/auth_provider.dart';
import 'package:chashibhai/features/buyer/presentation/state/product_provider.dart';
import 'package:chashibhai/features/buyer/presentation/state/demand_provider.dart';
import 'package:chashibhai/features/farmer/domain/repositories/farmer_repository.dart';
import 'package:chashibhai/features/farmer/domain/usecases/get_my_products_usecase.dart';
import 'package:chashibhai/features/farmer/presentation/views/farmer_dashboard.dart';
import 'package:chashibhai/features/farmer/data/models/create_product_request_model.dart';
import 'package:chashibhai/features/farmer/data/models/update_product_request_model.dart';
import 'package:chashibhai/core/services/upload_service.dart';

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
}
