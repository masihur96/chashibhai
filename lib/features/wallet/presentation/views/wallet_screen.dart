import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../buyer/presentation/state/product_provider.dart';
import '../../../group/presentation/state/group_provider.dart';
import '../../../buyer/presentation/state/demand_provider.dart';
import '../state/order_provider.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../../../../core/models/models.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/widgets/wallet_card.dart';
import '../../../../core/presentation/widgets/transaction_card.dart';
import './deposit_screen.dart';
import './withdraw_screen.dart';
import './escrow_screen.dart';
import './transactions_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<AuthProvider>().walletBalance;
    final transactions = context.watch<OrderProvider>().transactions;
    final currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: WalletCard(
              balance: balance,
              currencyFormat: currencyFormat,
              onAddFunds: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DepositScreen()));
              },
              onWithdraw: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WithdrawScreen()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.orange.shade200),
              ),
              color: Colors.orange.shade50,
              child: ListTile(
                leading: Icon(Icons.lock_outline, color: Colors.orange.shade700),
                title: const Text('Escrow Vault', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Manage locked funds and deliveries'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EscrowScreen()));
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionsScreen()));
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: transactions.length > 5 ? 5 : transactions.length, // Show up to 5 recent
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return TransactionCard(
                  transaction: tx,
                  description: 'Transaction #${tx.id.substring(0, 6)}',
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
