import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/status_badge.dart';

class AdminEscrowScreen extends StatefulWidget {
  const AdminEscrowScreen({super.key});

  @override
  State<AdminEscrowScreen> createState() => _AdminEscrowScreenState();
}

class _AdminEscrowScreenState extends State<AdminEscrowScreen> {
  final List<Order> _mockEscrowOrders = [
    Order(
      id: 'ORD1001',
      supplyId: 'PRD101',
      buyerId: 'U1002',
      farmerId: 'U1001',
      finalPrice: 45000,
      quantity: 1000,
      commission: 450,
      status: OrderStatus.pending,
    ),
    Order(
      id: 'ORD1002',
      supplyId: 'PRD102',
      buyerId: 'U1004',
      farmerId: 'U1005',
      finalPrice: 120000,
      quantity: 5000,
      commission: 1200,
      status: OrderStatus.dispatched,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 24,
              runSpacing: 16,
              children: [
                Icon(Icons.shield, color: Colors.orange.shade700, size: 48),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Funds in Escrow',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '৳ 4,500,000',
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Escrows: 342',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Disputed Escrows: 12',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Active Escrow Contracts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mockEscrowOrders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = _mockEscrowOrders[index];

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.orange.shade50,
                            child: Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.orange.shade700,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      order.id,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const StatusBadge(
                                      label: 'LOCKED',
                                      variant: BadgeVariant.warning,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.store_outlined,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Buyer: ${order.buyerId}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.agriculture_outlined,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Farmer: ${order.farmerId}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'release') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Funds Released (Mocked)'),
                                  ),
                                );
                              } else if (value == 'refund') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Funds Refunded (Mocked)'),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'release',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.green.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Force Release'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'refund',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.refresh,
                                      color: Colors.red.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Force Refund'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Locked Amount',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '৳ ${order.finalPrice}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
