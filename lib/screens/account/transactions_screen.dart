import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/demand_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../core/models.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<OrderProvider>().transactions;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Transaction History',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions found',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 70, endIndent: 20),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return _buildTransactionItem(tx);
              },
            ),
    );
  }

  Widget _buildTransactionItem(Transaction tx) {
    final isPositive = tx.type == TransactionType.deposit || tx.type == TransactionType.release;
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 2);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _getTypeColor(tx.type).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getTypeIcon(tx.type),
          color: _getTypeColor(tx.type),
          size: 24,
        ),
      ),
      title: Text(
        tx.type.toString().split('.').last.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
      subtitle: Text(
        DateFormat('MMM d, yyyy • hh:mm a').format(tx.createdAt),
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      trailing: Text(
        '${isPositive ? "+" : "-"}${currencyFormat.format(tx.amount)}',
        style: GoogleFonts.outfit(
          color: isPositive ? Colors.green[700] : Colors.red[700],
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: () {
        // Show transaction details
      },
    );
  }

  IconData _getTypeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return Icons.add_circle_outline_rounded;
      case TransactionType.escrow:
        return Icons.lock_outline_rounded;
      case TransactionType.release:
        return Icons.lock_open_rounded;
      case TransactionType.withdrawal:
        return Icons.remove_circle_outline_rounded;
    }
  }

  Color _getTypeColor(TransactionType type) {
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
}
