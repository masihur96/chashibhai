import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/models.dart';
import './status_badge.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final String productName;
  final DateTime createdAt;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.productName,
    required this.createdAt,
    required this.currencyFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  StatusBadge(
                    label: order.status.toString().split('.').last.toUpperCase(),
                    variant: variant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      productName,
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    currencyFormat.format(order.finalPrice),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.scale, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('${order.quantity} KG', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd, yyyy').format(createdAt),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
