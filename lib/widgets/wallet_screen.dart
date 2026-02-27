import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../core/models.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletBalanceProvider);
    final transactions = ref.watch(transactionsProvider);
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
      ),
      body: Column(
        children: [
          _buildBalanceCard(balance, currencyFormat),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction History',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Filter'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: _getTransactionColor(tx.type).withOpacity(0.1),
                    child: Icon(_getTransactionIcon(tx.type), color: _getTransactionColor(tx.type)),
                  ),
                  title: Text(
                    tx.type.name.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(DateFormat('dd MMM, yyyy').format(tx.createdAt)),
                  trailing: Text(
                    '${tx.type == TransactionType.deposit || tx.type == TransactionType.release ? '+' : '-'} ${currencyFormat.format(tx.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tx.type == TransactionType.deposit || tx.type == TransactionType.release
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(double balance, NumberFormat currencyFormat) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Current Balance',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(Icons.add, 'Deposit'),
              _buildActionButton(Icons.arrow_upward, 'Withdraw'),
              _buildActionButton(Icons.lock_outline, 'Escrow'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return Colors.green;
      case TransactionType.escrow:
        return Colors.orange;
      case TransactionType.release:
        return Colors.blue;
      case TransactionType.withdrawal:
        return Colors.red;
    }
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return Icons.add_circle_outline;
      case TransactionType.escrow:
        return Icons.lock_outline;
      case TransactionType.release:
        return Icons.check_circle_outline;
      case TransactionType.withdrawal:
        return Icons.remove_circle_outline;
    }
  }
}
