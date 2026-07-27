import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/custom_buttons.dart';
import '../../../buyer/presentation/state/product_provider.dart';
import './invoice_screen.dart';
import './rating_dialog.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    final product = products.firstWhere(
      (p) => p.id == order.supplyId,
      orElse: () => Product(
        id: '', farmerId: '', productName: 'Unknown Product',
        imageUrl: '', quantity: 0, minimumPrice: 0,
        tradeType: TradeType.negotiation, startTime: DateTime.now(),
        endTime: DateTime.now(), category: '',
      ),
    );

    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id.substring(0, 8)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'View Invoice',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => InvoiceScreen(order: order, product: product)));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductSummary(context, product, currencyFormat),
            const SizedBox(height: 32),
            Text('Order Timeline', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildOrderTimeline(context),
            const SizedBox(height: 32),
            Text('Payment Summary', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPaymentSummary(context, currencyFormat),
            const SizedBox(height: 32),
            if (order.status == OrderStatus.delivered)
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Rate your Experience',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                      builder: (context) => const RatingDialog(),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSummary(BuildContext context, Product product, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.productName, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${order.quantity} KG', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(format.format(order.finalPrice), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline(BuildContext context) {
    final steps = [
      {'title': 'Order Placed', 'status': OrderStatus.pending},
      {'title': 'Dispatched', 'status': OrderStatus.dispatched},
      {'title': 'Delivered', 'status': OrderStatus.delivered},
    ];

    int currentIndex = steps.indexWhere((s) => s['status'] == order.status);
    if (currentIndex == -1 && order.status == OrderStatus.cancelled) {
      currentIndex = 0; // Show cancelled state separately or just stop at placed
    }

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = order.status != OrderStatus.cancelled && index <= currentIndex;
        final isCurrent = order.status != OrderStatus.cancelled && index == currentIndex;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted && !isCurrent ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['title'] as String,
                      style: TextStyle(
                        fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted ? Colors.black87 : Colors.grey.shade500,
                      ),
                    ),
                    if (isCurrent)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          order.status == OrderStatus.pending ? 'Waiting for farmer to dispatch.' : 
                          order.status == OrderStatus.dispatched ? 'On the way to delivery location.' : 
                          'Successfully delivered.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPaymentSummary(BuildContext context, NumberFormat format) {
    return Column(
      children: [
        _buildSummaryRow('Subtotal', format.format(order.finalPrice)),
        const SizedBox(height: 8),
        _buildSummaryRow('Platform Commission', format.format(order.commission)),
        const SizedBox(height: 8),
        _buildSummaryRow('Escrow Fee', format.format(order.finalPrice * 0.01)),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
        _buildSummaryRow('Total Paid', format.format(order.finalPrice + order.commission + (order.finalPrice * 0.01)), isBold: true),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? Colors.black87 : Colors.grey.shade600)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
      ],
    );
  }
}
