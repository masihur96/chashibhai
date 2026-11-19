import 'package:flutter_test/flutter_test.dart';
import 'package:chashibhai/core/models/models.dart';
import 'package:chashibhai/features/farmer/domain/repositories/farmer_repository.dart';
import 'package:chashibhai/features/farmer/domain/usecases/get_my_products_usecase.dart';
import 'package:chashibhai/features/buyer/presentation/state/product_provider.dart';
import 'package:chashibhai/features/farmer/data/models/create_product_request_model.dart';
import 'package:chashibhai/features/farmer/data/models/update_product_request_model.dart';
import 'package:chashibhai/core/services/upload_service.dart';

class MockFarmerRepository implements FarmerRepository {
  List<Product> mockProducts = [
    Product(
      id: 'p_test_1',
      farmerId: 'farmer_123',
      productName: 'Miniket Rice',
      imageUrl: 'https://cdn.example.com/rice.jpg',
      quantity: 500,
      unit: 'KG',
      minimumPrice: 65,
      tradeType: TradeType.both,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(days: 5)),
      category: 'rice',
      status: 'active',
    ),
  ];

  Map<String, dynamic>? lastQueryParams;

  @override
  Future<Product> addProduct({
    required CreateProductRequestModel request,
    String? token,
  }) async {
    return mockProducts.first;
  }

  @override
  Future<List<String>> uploadImages({
    required List<UploadFileItem> files,
    String? token,
  }) async {
    return ['https://cdn.example.com/rice.jpg'];
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
    lastQueryParams = {
      'page': page,
      'limit': limit,
      'status': status,
      'category': category,
      'tradeType': tradeType,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'search': search,
      'token': token,
    };
    return mockProducts;
  }

  @override
  Future<Product> getProductById({required String id, String? token}) async {
    return mockProducts.firstWhere((p) => p.id == id, orElse: () => mockProducts.first);
  }

  @override
  Future<Product> updateProduct({
    required String id,
    required UpdateProductRequestModel request,
    String? token,
  }) async {
    return mockProducts.first;
  }

  @override
  Future<bool> deleteProduct({required String id, String? token}) async {
    mockProducts.removeWhere((p) => p.id == id);
    return true;
  }
}

void main() {
  group('Farmer Own Products Feature Tests', () {
    late MockFarmerRepository mockRepository;
    late GetMyProductsUseCase getMyProductsUseCase;
    late ProductProvider productProvider;

    setUp(() {
      mockRepository = MockFarmerRepository();
      getMyProductsUseCase = GetMyProductsUseCase(mockRepository);
      productProvider = ProductProvider(
        farmerRepository: mockRepository,
        getMyProductsUseCase: getMyProductsUseCase,
      );
    });

    test('GetMyProductsUseCase calls repository with curl query parameters', () async {
      final products = await getMyProductsUseCase(
        page: 1,
        limit: 10,
        category: 'rice',
        tradeType: 'both',
        minPrice: 30,
        maxPrice: 100,
        search: 'Rice',
        status: 'active',
        token: 'test_token',
      );

      expect(products.length, 1);
      expect(products.first.productName, 'Miniket Rice');
      expect(mockRepository.lastQueryParams?['page'], 1);
      expect(mockRepository.lastQueryParams?['limit'], 10);
      expect(mockRepository.lastQueryParams?['category'], 'rice');
      expect(mockRepository.lastQueryParams?['tradeType'], 'both');
      expect(mockRepository.lastQueryParams?['minPrice'], 30.0);
      expect(mockRepository.lastQueryParams?['maxPrice'], 100.0);
      expect(mockRepository.lastQueryParams?['search'], 'Rice');
      expect(mockRepository.lastQueryParams?['status'], 'active');
      expect(mockRepository.lastQueryParams?['token'], 'test_token');
    });

    test('ProductProvider fetchMyProducts updates state correctly', () async {
      expect(productProvider.myProducts, isEmpty);
      expect(productProvider.isMyProductsLoading, isFalse);

      final future = productProvider.fetchMyProducts(
        category: 'rice',
        tradeType: 'both',
        minPrice: 30,
        maxPrice: 100,
        search: 'Rice',
        status: 'active',
      );

      final results = await future;
      expect(results.length, 1);
      expect(productProvider.myProducts.length, 1);
      expect(productProvider.myProducts.first.productName, 'Miniket Rice');
      expect(productProvider.isMyProductsLoading, isFalse);
      expect(productProvider.myProductsError, isNull);
    });
  });
}
