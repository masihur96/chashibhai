import 'package:flutter/material.dart';
import '../../../../core/models/models.dart';
import '../../../../core/models/mock_data.dart';
import '../../../farmer/data/models/create_product_request_model.dart';
import '../../../farmer/domain/usecases/add_product_usecase.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = List<Product>.from(MockData.demoProducts);
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String? _errorMessage;

  final AddProductUseCase _addProductUseCase;

  ProductProvider({AddProductUseCase? addProductUseCase})
      : _addProductUseCase = addProductUseCase ?? AddProductUseCase();

  List<Product> get products => _products;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setProducts(List<Product> products) {
    _products = products;
    notifyListeners();
  }

  void addProduct(Product product) {
    _products.insert(0, product);
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
