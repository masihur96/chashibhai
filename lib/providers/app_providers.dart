import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
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

final productsByCategoryProvider = Provider.family<List<Product>, String>((ref, category) {
  final products = ref.watch(productsProvider);
  if (category == 'All') return products;
  return products.where((p) => p.category == category).toList();
});

final notificationsProvider = StateProvider<List<AppNotification>>((ref) => MockData.demoNotifications);

final appLocaleProvider = StateProvider<String>((ref) => 'en');

final biometricEnabledProvider = StateProvider<bool>((ref) => false);

final biometricServiceProvider = Provider((ref) => LocalAuthentication());

final biometricAuthenticateProvider = FutureProvider.autoDispose<bool>((ref) async {
  final authDesc = ref.watch(appLocaleProvider) == 'bn' 
    ? 'বায়োমেট্রিক ব্যবহার করে লগইন করুন' 
    : 'Login using biometrics';
    
  try {
    final localAuth = ref.read(biometricServiceProvider);
    final canAuthenticateWithBiometrics = await localAuth.canCheckBiometrics;
    final canAuthenticate = canAuthenticateWithBiometrics || await localAuth.isDeviceSupported();
    
    if (!canAuthenticate) return false;

    return await localAuth.authenticate(
      localizedReason: authDesc,
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: true,
      ),
    );
  } catch (e) {
    return false;
  }
});
