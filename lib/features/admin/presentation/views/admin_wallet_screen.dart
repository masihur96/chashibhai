import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/transaction_card.dart';

class AdminWalletScreen extends StatefulWidget {
  const AdminWalletScreen({super.key});

  @override
  State<AdminWalletScreen> createState() => _AdminWalletScreenState();
}

class _AdminWalletScreenState extends State<AdminWalletScreen> {
  final List<Transaction> _mockRevenue = [
    Transaction(
      id: 'TX9001',
      userId: 'SYSTEM',
      type: TransactionType.deposit,
      amount: 450,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Transaction(
      id: 'TX9002',
      userId: 'SYSTEM',
      type: TransactionType.deposit,
      amount: 1200,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Transaction(
      id: 'TX9003',
      userId: 'SYSTEM',
      type: TransactionType.deposit,
      amount: 85,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Transaction(
      id: 'TX9004',
      userId: 'SYSTEM',
      type: TransactionType.withdrawal,
      amount: 5000,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ), // Payout to bank
  ];

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total Liquidity',
                        '৳ 4.5M',
                        Colors.blue.shade700,
                        Icons.account_balance_wallet_rounded,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total Revenue',
                        '৳ 254K',
                        Colors.green.shade700,
                        Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Available Payout',
                        '৳ 12,450',
                        Colors.orange.shade700,
                        Icons.payments_rounded,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildStatCard(
                      context,
                      'Total Liquidity',
                      '৳ 4.5M',
                      Colors.blue.shade700,
                      Icons.account_balance_wallet_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      context,
                      'Total Revenue',
                      '৳ 254K',
                      Colors.green.shade700,
                      Icons.trending_up_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      context,
                      'Available Payout',
                      '৳ 12,450',
                      Colors.orange.shade700,
                      Icons.payments_rounded,
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Transaction Ledger',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Export CSV'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
                description: tx.type == TransactionType.deposit
                    ? 'Commission Collected'
                    : 'Admin Bank Payout',
                currencyFormat: currencyFormat,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
