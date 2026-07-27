import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../state/product_provider.dart';
import '../../../group/presentation/state/group_provider.dart';
import '../state/demand_provider.dart';
import '../../../wallet/presentation/state/order_provider.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../../../../core/presentation/widgets/product_card.dart';
import './product_details.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CategoryProductsScreen extends StatelessWidget {
  final String category;

  const CategoryProductsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().getProductsByCategory(category);
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          category == 'All' ? 'All Products' : '$category Supplies',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No products available in this category',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: products[index],
                  currencyFormat: currencyFormat,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsScreen(product: products[index]),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
