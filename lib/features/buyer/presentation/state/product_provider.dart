import 'package:flutter/material.dart';
import '../../../../core/models/mock_data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/upload_service.dart';
import '../../../farmer/data/models/create_product_request_model.dart';
import '../../../farmer/data/repositories/farmer_repository_impl.dart';
import '../../../farmer/domain/repositories/farmer_repository.dart';
import '../../../farmer/domain/usecases/add_product_usecase.dart';
import '../../../farmer/domain/usecases/get_my_products_usecase.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = List<Product>.from(MockData.demoProducts);
  List<Product> _myProducts = [];
  bool _isMyProductsLoading = false;
  String? _myProductsError;

  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String? _errorMessage;

  final AddProductUseCase _addProductUseCase;
  final GetMyProductsUseCase _getMyProductsUseCase;
  final FarmerRepository _farmerRepository;

  ProductProvider({
    AddProductUseCase? addProductUseCase,
    GetMyProductsUseCase? getMyProductsUseCase,
    FarmerRepository? farmerRepository,
  })  : _farmerRepository = farmerRepository ?? FarmerRepositoryImpl(),
        _addProductUseCase = addProductUseCase ?? AddProductUseCase(farmerRepository ?? FarmerRepositoryImpl()),
        _getMyProductsUseCase = getMyProductsUseCase ?? GetMyProductsUseCase(farmerRepository ?? FarmerRepositoryImpl());

  List<Product> get products => _products;
  List<Product> get myProducts => _myProducts;
  bool get isMyProductsLoading => _isMyProductsLoading;
  String? get myProductsError => _myProductsError;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setProducts(List<Product> products) {
    _products = products;
    notifyListeners();
  }

  void setMyProducts(List<Product> products) {
    _myProducts = products;
    notifyListeners();
  }

  void addProduct(Product product) {
    _products.insert(0, product);
    _myProducts.removeWhere((p) => p.id == product.id);
    _myProducts.insert(0, product);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  List<Product> get filteredProducts {
    final query = _searchQuery.toLowerCase();

    return _products.where((product) {
      final matchesSearch = product.productName.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == 'All' || product.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Product> getProductsByCategory(String category) {
    if (category == 'All') return _products;
    return _products.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
  }

  /// Uploads product images using POST /api/v1/upload multipart/form-data
  Future<List<String>> uploadImages({
    required List<UploadFileItem> files,
    String? token,
  }) async {
    return await _farmerRepository.uploadImages(
      files: files,
      token: token,
    );
  }

  /// Fetches the authenticated farmer's own products via GET /api/v1/products/my
  Future<List<Product>> fetchMyProducts({
    int page = 1,
    int limit = 10,
    String? status = 'active',
    String? category,
    String? tradeType,
    double? minPrice,
    double? maxPrice,
    String? search,
    String? token,
  }) async {
    _isMyProductsLoading = true;
    _myProductsError = null;
    notifyListeners();

    try {
      final fetched = await _getMyProductsUseCase(
        page: page,
        limit: limit,
        status: status,
        category: category,
        tradeType: tradeType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        search: search,
        token: token,
      );
      _myProducts = fetched;
      _isMyProductsLoading = false;
      notifyListeners();
      return fetched;
    } catch (e) {
      _isMyProductsLoading = false;
      _myProductsError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return [];
    }
  }

  /// Creates a new product on the backend using the POST /api/v1/products API
  /// and automatically prepends the created product to the local list.
  Future<Product> createProduct({
    required CreateProductRequestModel request,
    String? token,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdProduct = await _addProductUseCase(
        request: request,
        token: token,
      );
      addProduct(createdProduct);
      _isLoading = false;
      notifyListeners();
      return createdProduct;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
