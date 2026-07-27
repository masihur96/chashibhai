import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/models.dart';
import './status_badge.dart';

class DemandCard extends StatelessWidget {
  final DemandPost demand;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const DemandCard({
    super.key,
    required this.demand,
    required this.currencyFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                  StatusBadge(
                    label: demand.status.toString().split('.').last.toUpperCase(),
                    variant: demand.status == DemandStatus.active ? BadgeVariant.success : BadgeVariant.neutral,
                  ),
                  Text(
                    'Expires ${DateFormat('MMM dd, yyyy').format(demand.expiryTime)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      demand.productName,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${demand.quantity} KG',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Calling Price', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      Text(
                        currencyFormat.format(demand.callingPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Delivery To', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            demand.deliveryLocation,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
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
