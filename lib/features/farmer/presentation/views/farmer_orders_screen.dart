import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/custom_search_bar.dart';
import '../../../../core/presentation/widgets/filter_chips_list.dart';
import '../../../../core/presentation/widgets/order_card.dart';
import '../../../../core/presentation/widgets/empty_state_widget.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../wallet/presentation/state/order_provider.dart';
import '../../../buyer/presentation/state/product_provider.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../../../../features/order/presentation/views/order_details_screen.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'Pending';

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppStateProvider>().appLocale;
    final currentUser = context.watch<AuthProvider>().currentUser;
    final allOrders = context.watch<OrderProvider>().orders;
    final products = context.watch<ProductProvider>().products;

    // Filter orders for current farmer
    final myOrders = allOrders.where((o) => o.farmerId == currentUser?.id).toList();

    // Apply status filter
    final filteredOrders = myOrders.where((order) {
      bool matchesStatus = false;
      if (_selectedStatus == 'Pending') {
        matchesStatus = order.status == OrderStatus.pending;
      } else if (_selectedStatus == 'Dispatched') {
        matchesStatus = order.status == OrderStatus.dispatched;
      } else if (_selectedStatus == 'Delivered') {
        matchesStatus = order.status == OrderStatus.delivered;
      } else if (_selectedStatus == 'Cancelled') {
        matchesStatus = order.status == OrderStatus.cancelled;
      }

      return matchesStatus;
    }).toList();

    // Search is applied by checking the matched product name
    final searchFilteredOrders = filteredOrders.where((order) {
      if (_searchQuery.isEmpty) return true;
      final product = products.firstWhere(
        (p) => p.id == order.supplyId,
        orElse: () => Product(
          id: '', farmerId: '', productName: 'Unknown Product',
          imageUrl: '', quantity: 0, minimumPrice: 0,
          tradeType: TradeType.negotiation, startTime: DateTime.now(),
          endTime: DateTime.now(), category: '',
        ),
      );
      return product.productName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: CustomSearchBar(
              hintText: 'Search orders...',
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilterChipsList(
              categories: const ['Pending', 'Dispatched', 'Delivered', 'Cancelled'],
              selectedCategory: _selectedStatus,
              onSelected: (category) => setState(() => _selectedStatus = category),
              languageCode: languageCode,
            ),
          ),
          Expanded(
            child: searchFilteredOrders.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.local_shipping_outlined,
                    title: 'No orders found',
                    subtitle: 'You do not have any orders in this status right now.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: searchFilteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = searchFilteredOrders[index];
                      // Find product name or mock it
                      final product = products.firstWhere(
                        (p) => p.id == order.supplyId,
                        orElse: () => Product(
                          id: '', farmerId: '', productName: 'Unknown Product',
                          imageUrl: '', quantity: 0, minimumPrice: 0,
                          tradeType: TradeType.negotiation, startTime: DateTime.now(),
                          endTime: DateTime.now(), category: '',
                        ),
                      );
                      
                      // Mocking createdAt since it's not in Order model
                      final createdAt = DateTime.now().subtract(Duration(days: index + 1));

                      return OrderCard(
                        order: order,
                        productName: product.productName,
                        createdAt: createdAt,
                        currencyFormat: currencyFormat,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsScreen(order: order),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
