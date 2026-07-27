import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/transaction_card.dart';
import 'package:intl/intl.dart';

class AdminWalletScreen extends StatefulWidget {
  const AdminWalletScreen({super.key});

  @override
  State<AdminWalletScreen> createState() => _AdminWalletScreenState();
}

class _AdminWalletScreenState extends State<AdminWalletScreen> {
  final List<Transaction> _mockRevenue = [
    Transaction(id: 'TX9001', userId: 'SYSTEM', type: TransactionType.deposit, amount: 450, createdAt: DateTime.now().subtract(const Duration(hours: 1))),
    Transaction(id: 'TX9002', userId: 'SYSTEM', type: TransactionType.deposit, amount: 1200, createdAt: DateTime.now().subtract(const Duration(hours: 5))),
    Transaction(id: 'TX9003', userId: 'SYSTEM', type: TransactionType.deposit, amount: 85, createdAt: DateTime.now().subtract(const Duration(days: 1))),
    Transaction(id: 'TX9004', userId: 'SYSTEM', type: TransactionType.withdrawal, amount: 5000, createdAt: DateTime.now().subtract(const Duration(days: 2))), // Payout to bank
  ];

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Revenue Wallet', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Track collected commissions and escrow fees.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _buildWalletCard(context, 'Total Platform Liquidity', '৳ 4,500,000', Colors.blue)),
              const SizedBox(width: 24),
              Expanded(child: _buildWalletCard(context, 'Total Revenue (All Time)', '৳ 254,000', Colors.green)),
              const SizedBox(width: 24),
              Expanded(child: _buildWalletCard(context, 'Available for Payout', '৳ 12,450', Colors.orange)),
            ],
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Revenue Transaction Ledger', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text('Export CSV'),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mockRevenue.length,
            itemBuilder: (context, index) {
              final tx = _mockRevenue[index];
              return TransactionCard(
                transaction: tx,
                description: tx.type == TransactionType.deposit ? 'Commission Collected' : 'Admin Bank Payout',
                currencyFormat: currencyFormat,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
