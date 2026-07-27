import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/status_badge.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final List<Order> _mockOrders = [
    Order(id: 'ORD1001', supplyId: 'PRD101', buyerId: 'U1002', farmerId: 'U1001', finalPrice: 45000, quantity: 1000, commission: 450, status: OrderStatus.pending),
    Order(id: 'ORD1002', supplyId: 'PRD102', buyerId: 'U1004', farmerId: 'U1005', finalPrice: 120000, quantity: 5000, commission: 1200, status: OrderStatus.dispatched),
    Order(id: 'ORD1003', supplyId: 'PRD103', buyerId: 'U1002', farmerId: 'U1001', finalPrice: 8500, quantity: 200, commission: 85, status: OrderStatus.delivered),
    Order(id: 'ORD1004', supplyId: 'PRD104', buyerId: 'U1004', farmerId: 'U1003', finalPrice: 65000, quantity: 1500, commission: 650, status: OrderStatus.cancelled),
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
              Text('Global Orders', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Order ID...',
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
                DataColumn(label: Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Buyer ID', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Farmer ID', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Commission', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _mockOrders.map((order) {
                BadgeVariant variant;
                switch (order.status) {
                  case OrderStatus.pending:
                  case OrderStatus.dispatched:
                    variant = BadgeVariant.info;
                    break;
                  case OrderStatus.delivered:
                    variant = BadgeVariant.success;
                    break;
                  case OrderStatus.cancelled:
                    variant = BadgeVariant.error;
                    break;
                }

                return DataRow(
                  cells: [
                    DataCell(Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(order.buyerId)),
                    DataCell(Text(order.farmerId)),
                    DataCell(Text('৳ ${order.finalPrice}')),
                    DataCell(Text('৳ ${order.commission}', style: const TextStyle(color: Colors.green))),
                    DataCell(StatusBadge(label: order.status.toString().split('.').last.toUpperCase(), variant: variant)),
                    DataCell(
                      TextButton(
                        onPressed: () {
                          // View details
                        },
                        child: const Text('View Details'),
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
