import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/transaction_card.dart';
import '../../../../core/presentation/widgets/empty_state_widget.dart';
import '../state/order_provider.dart';
import '../../../auth/presentation/state/auth_provider.dart';

class EscrowScreen extends StatelessWidget {
  const EscrowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<OrderProvider>().transactions;
    final currentUser = context.watch<AuthProvider>().currentUser;
    
    // Filter escrow transactions for current user
    final escrowTxs = transactions.where((tx) => tx.userId == currentUser?.id && tx.type == TransactionType.escrow).toList();
    
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 2);
    
    // Calculate total escrow
    final totalEscrow = escrowTxs.fold(0.0, (sum, tx) => sum + tx.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text('Escrow Vault', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.lock, color: Colors.orange.shade700, size: 32),
                const SizedBox(height: 12),
                Text('Total Locked Funds', style: TextStyle(color: Colors.orange.shade900)),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(totalEscrow),
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                ),
                const SizedBox(height: 8),
                Text(
                  'These funds are held safely until order delivery is confirmed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: escrowTxs.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.shield_outlined,
                    title: 'No Escrow Funds',
                    subtitle: 'You currently do not have any funds locked in escrow.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: escrowTxs.length,
                    itemBuilder: (context, index) {
                      final tx = escrowTxs[index];
                      return TransactionCard(
                        transaction: tx,
                        description: 'Order Escrow #${tx.id.substring(0, 6)}',
                        currencyFormat: currencyFormat,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
