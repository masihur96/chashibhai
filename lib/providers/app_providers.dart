import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models.dart';
import '../core/mock_data.dart';

final userRoleProvider = StateProvider<UserRole>((ref) => UserRole.buyer);

final productsProvider = StateProvider<List<Product>>((ref) => MockData.demoProducts);

final bidsProvider = StateProvider<List<Bid>>((ref) => MockData.demoBids);

final ordersProvider = StateProvider<List<Order>>((ref) => MockData.demoOrders);

final transactionsProvider = StateProvider<List<Transaction>>((ref) => MockData.demoTransactions);

final walletBalanceProvider = StateProvider<double>((ref) => MockData.currentUser.walletBalance);

final demandsProvider = StateProvider<List<DemandPost>>((ref) => MockData.demoDemands);
