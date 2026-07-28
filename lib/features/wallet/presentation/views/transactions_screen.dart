import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../buyer/presentation/state/product_provider.dart';
import '../../../group/presentation/state/group_provider.dart';
import '../../../buyer/presentation/state/demand_provider.dart';
import '../state/order_provider.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../../../../core/models/models.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/widgets/transaction_card.dart';
import '../../../../core/presentation/widgets/empty_state_widget.dart';

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
          ? const EmptyStateWidget(
              icon: Icons.history_toggle_off_rounded,
              title: 'No transactions found',
              subtitle: 'Your transaction history is empty.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 2);
                final shortId = tx.id.length > 6 ? tx.id.substring(0, 6) : tx.id;
                return TransactionCard(
                  transaction: tx,
                  description: 'Transaction #$shortId',
                  currencyFormat: currencyFormat,
                );
              },
            ),
    );
  }

  // _buildTransactionItem, _getTypeIcon, _getTypeColor replaced by TransactionCard component
}
