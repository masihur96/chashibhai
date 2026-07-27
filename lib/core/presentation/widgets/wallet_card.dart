import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class WalletCard extends StatelessWidget {
  final double balance;
  final NumberFormat currencyFormat;
  final VoidCallback onAddFunds;
  final VoidCallback onWithdraw;

  const WalletCard({
    super.key,
    required this.balance,
    required this.currencyFormat,
    required this.onAddFunds,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Balance',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8), fontSize: 16),
              ),
              Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(balance),
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAddFunds,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Funds'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.onPrimary,
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onWithdraw,
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  label: const Text('Withdraw'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    side: BorderSide(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
