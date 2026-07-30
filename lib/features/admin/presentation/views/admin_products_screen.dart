import 'package:flutter/material.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/status_badge.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final List<Product> _mockProducts = [
    Product(
      id: 'PRD101',
      farmerId: 'U1001',
      productName: 'Premium Rice',
      imageUrl: '',
      quantity: 5000,
      minimumPrice: 45,
      tradeType: TradeType.both,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(days: 10)),
      category: 'Grains',
      status: 'active',
    ),
    Product(
      id: 'PRD102',
      farmerId: 'U1003',
      productName: 'Fresh Potatoes',
      imageUrl: '',
      quantity: 2000,
      minimumPrice: 20,
      tradeType: TradeType.negotiation,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(days: 5)),
      category: 'Vegetables',
      status: 'active',
    ),
    Product(
      id: 'PRD103',
      farmerId: 'U1005',
      productName: 'Green Apples',
      imageUrl: '',
      quantity: 500,
      minimumPrice: 120,
      tradeType: TradeType.auction,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(days: 2)),
      category: 'Fruits',
      status: 'suspended',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mockProducts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final product = _mockProducts[index];
              final isActive = product.status == 'active';

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
                                      product.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    StatusBadge(
                                      label: product.status.toUpperCase(),
                                      variant: isActive
                                          ? BadgeVariant.success
                                          : BadgeVariant.error,
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
                                          Icons.category_outlined,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          product.category,
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
                                          Icons.scale_outlined,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${product.quantity} KG',
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
                                          'Farmer: ${product.farmerId}',
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
                                          Icons.fingerprint,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ID: ${product.id}',
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
                              if (value == 'unpublish') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Product Unpublished (Mocked)',
                                    ),
                                  ),
                                );
                              } else if (value == 'restore') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Product Restored (Mocked)'),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              if (isActive)
                                PopupMenuItem(
                                  value: 'unpublish',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.gavel,
                                        color: Colors.red.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Unpublish'),
                                    ],
                                  ),
                                )
                              else
                                PopupMenuItem(
                                  value: 'restore',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.restore,
                                        color: Colors.green.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Restore'),
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
                                  'Minimum Price',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '৳ ${product.minimumPrice} / kg',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Trade Type',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.tradeType
                                      .toString()
                                      .split('.')
                                      .last
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
