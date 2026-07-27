import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/status_badge.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final List<Product> _mockProducts = [
    Product(id: 'PRD101', farmerId: 'U1001', productName: 'Premium Rice', imageUrl: '', quantity: 5000, minimumPrice: 45, tradeType: TradeType.both, startTime: DateTime.now(), endTime: DateTime.now().add(const Duration(days: 10)), category: 'Grains', status: 'active'),
    Product(id: 'PRD102', farmerId: 'U1003', productName: 'Fresh Potatoes', imageUrl: '', quantity: 2000, minimumPrice: 20, tradeType: TradeType.negotiation, startTime: DateTime.now(), endTime: DateTime.now().add(const Duration(days: 5)), category: 'Vegetables', status: 'active'),
    Product(id: 'PRD103', farmerId: 'U1005', productName: 'Green Apples', imageUrl: '', quantity: 500, minimumPrice: 120, tradeType: TradeType.auction, startTime: DateTime.now(), endTime: DateTime.now().add(const Duration(days: 2)), category: 'Fruits', status: 'suspended'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Marketplace Products', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              columns: const [
                DataColumn(label: Text('Product ID', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Farmer ID', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _mockProducts.map((product) {
                return DataRow(
                  cells: [
                    DataCell(Text(product.id, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(product.productName)),
                    DataCell(Text(product.category)),
                    DataCell(Text(product.farmerId)),
                    DataCell(Text('${product.quantity} KG')),
                    DataCell(
                      StatusBadge(
                        label: product.status.toUpperCase(),
                        variant: product.status == 'active' ? BadgeVariant.success : BadgeVariant.error,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (product.status == 'active')
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.gavel, size: 16, color: Colors.red),
                              label: const Text('Unpublish', style: TextStyle(color: Colors.red)),
                            )
                          else
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.restore, size: 16, color: Colors.green),
                              label: const Text('Restore', style: TextStyle(color: Colors.green)),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
