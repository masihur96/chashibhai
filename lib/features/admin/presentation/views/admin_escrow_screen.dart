import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/status_badge.dart';
import 'package:intl/intl.dart';

class AdminEscrowScreen extends StatefulWidget {
  const AdminEscrowScreen({super.key});

  @override
  State<AdminEscrowScreen> createState() => _AdminEscrowScreenState();
}

class _AdminEscrowScreenState extends State<AdminEscrowScreen> {
  final List<Order> _mockEscrowOrders = [
    Order(id: 'ORD1001', supplyId: 'PRD101', buyerId: 'U1002', farmerId: 'U1001', finalPrice: 45000, quantity: 1000, commission: 450, status: OrderStatus.pending),
    Order(id: 'ORD1002', supplyId: 'PRD102', buyerId: 'U1004', farmerId: 'U1005', finalPrice: 120000, quantity: 5000, commission: 1200, status: OrderStatus.dispatched),
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
              Text('Escrow Management', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search Escrow ID / Order ID...',
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.shield, color: Colors.orange.shade700, size: 48),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Funds in Escrow', style: TextStyle(color: Colors.orange.shade900, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('৳ 4,500,000', style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Active Escrows: 342', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Disputed Escrows: 12', style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Text('Active Escrow Contracts', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
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
                DataColumn(label: Text('Locked Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _mockEscrowOrders.map((order) {
                return DataRow(
                  cells: [
                    DataCell(Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(order.buyerId)),
                    DataCell(Text(order.farmerId)),
                    DataCell(Text('৳ ${order.finalPrice}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))),
                    DataCell(const StatusBadge(label: 'LOCKED', variant: BadgeVariant.warning)),
                    DataCell(
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                            label: const Text('Force Release', style: TextStyle(color: Colors.green)),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.refresh, size: 16, color: Colors.red),
                            label: const Text('Force Refund', style: TextStyle(color: Colors.red)),
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
