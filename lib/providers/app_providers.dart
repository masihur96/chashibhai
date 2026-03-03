import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models.dart';
import '../core/mock_data.dart';

final authStateProvider = StateProvider<AppUser?>((ref) => null); // Initially null (not logged in)

final userRoleProvider = StateProvider<UserRole>((ref) {
  final user = ref.watch(authStateProvider);
  return user?.role ?? UserRole.buyer;
});

final productsProvider = StateProvider<List<Product>>((ref) => MockData.demoProducts);

final bidsProvider = StateProvider<List<Bid>>((ref) => MockData.demoBids);

final ordersProvider = StateProvider<List<Order>>((ref) => MockData.demoOrders);

final transactionsProvider = StateProvider<List<Transaction>>((ref) => MockData.demoTransactions);

final walletBalanceProvider = StateProvider<double>((ref) {
  final user = ref.watch(authStateProvider);
  return user?.walletBalance ?? 0.0;
});

final demandsProvider = StateProvider<List<DemandPost>>((ref) => MockData.demoDemands);

final searchQueryProvider = StateProvider<String>((ref) => '');

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return products.where((product) {
    final matchesSearch = product.productName.toLowerCase().contains(searchQuery);
    final matchesCategory = selectedCategory == 'All' || product.category == selectedCategory;
    return matchesSearch && matchesCategory;
  }).toList();
});
