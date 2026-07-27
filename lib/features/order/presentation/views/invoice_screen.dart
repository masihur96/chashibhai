import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/custom_buttons.dart';

class InvoiceScreen extends StatelessWidget {
  final Order order;
  final Product product;

  const InvoiceScreen({
    super.key,
    required this.order,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 2);
    final invoiceNumber = 'INV-${Random().nextInt(999999).toString().padLeft(6, '0')}';
    final date = DateFormat('dd MMM, yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Invoice', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ChashiBhai', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(height: 4),
                      Text('Official Receipt', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(date, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(thickness: 2)),
              
              // Bill To / From
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Billed To', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text('Buyer ID:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(order.buyerId.substring(0, 8), style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Supplied By', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text('Farmer ID:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(order.farmerId.substring(0, 8), style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Item details
              Text('Items', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade50,
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                    Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                    Expanded(flex: 2, child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(flex: 3, child: Text(product.productName)),
                  Expanded(flex: 1, child: Text('${order.quantity}', textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text(currencyFormat.format(order.finalPrice), textAlign: TextAlign.right)),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
              
              // Totals
              _buildTotalRow('Subtotal', currencyFormat.format(order.finalPrice)),
              const SizedBox(height: 8),
              _buildTotalRow('Platform Fee', currencyFormat.format(order.commission)),
              const SizedBox(height: 8),
              _buildTotalRow('Escrow Fee', currencyFormat.format(order.finalPrice * 0.01)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: _buildTotalRow('Total Paid', currencyFormat.format(order.finalPrice + order.commission + (order.finalPrice * 0.01)), isBold: true, isTotal: true),
              ),
              const SizedBox(height: 48),

              // Action
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Download PDF',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice downloaded (Mocked)')));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? Colors.black87 : Colors.grey.shade600, fontSize: isTotal ? 16 : 14)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 18 : 14)),
      ],
    );
  }
}
