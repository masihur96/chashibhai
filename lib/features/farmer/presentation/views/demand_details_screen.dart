import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/models.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../account/presentation/state/review_provider.dart';
import '../../../../core/presentation/widgets/reviews_list_sheet.dart';
import '../../../order/presentation/views/rating_dialog.dart';

class DemandDetailsScreen extends StatelessWidget {
  final DemandPost demand;

  const DemandDetailsScreen({super.key, required this.demand});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);
    final currentUser = context.watch<AuthProvider>().currentUser;
    final reviewProvider = context.watch<ReviewProvider>();

    final buyerId = demand.buyerId;
    final averageRating = reviewProvider.getAverageRating(buyerId);
    final reviewsCount = reviewProvider.getReviewsForUser(buyerId).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Demand Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDemandHeader(context, currencyFormat),
            const SizedBox(height: 24),
            _buildBuyerInfo(context, buyerId, averageRating, reviewsCount),
            const SizedBox(height: 24),
            _buildDemandDetails(context),
            const SizedBox(height: 40),
            if (currentUser?.role == UserRole.farmer) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Offer submitted successfully!')),
                    );
                  },
                  child: const Text('Offer to Supply'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                      builder: (context) => RatingDialog(
                        reviewerId: currentUser!.id,
                        revieweeId: buyerId,
                        orderId: null, // Allow rating without an order ID
                      ),
                    );
                  },
                  icon: const Icon(Icons.star_rate_rounded),
                  label: const Text('Rate Buyer'),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDemandHeader(BuildContext context, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                demand.productName,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: demand.status == DemandStatus.active
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                demand.status.name.toUpperCase(),
                style: TextStyle(
                  color: demand.status == DemandStatus.active
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Target Price: ${currencyFormat.format(demand.callingPrice)} per unit',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }

  Widget _buildBuyerInfo(BuildContext context, String buyerId, double averageRating, int reviewsCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Posted By', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card.outlined(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (context) => ReviewsListSheet(userId: buyerId),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buyer ${buyerId.substring(0, 2).toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, color: Theme.of(context).colorScheme.secondary, size: 16),
                            const SizedBox(width: 4),
                            Text('${averageRating.toStringAsFixed(1)} ($reviewsCount reviews)', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemandDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Requirements', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildDetailRow(Icons.inventory_2_outlined, 'Quantity Required', '${demand.quantity} KG'),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
              _buildDetailRow(Icons.location_on_outlined, 'Delivery Location', demand.deliveryLocation),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
              _buildDetailRow(Icons.access_time, 'Expires On', DateFormat.yMMMd().format(demand.expiryTime)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
