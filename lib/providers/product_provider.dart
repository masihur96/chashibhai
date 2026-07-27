import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/mock_data.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = MockData.demoProducts;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<Product> get products => _products;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  void setProducts(List<Product> products) {
    _products = products;
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
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Product> getProductsByCategory(String category) {
    if (category == 'All') return _products;
    return _products.where((p) => p.category == category).toList();
  }
}
