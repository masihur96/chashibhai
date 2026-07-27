import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/models.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final String description;
  final NumberFormat currencyFormat;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.description,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCredit = transaction.type == TransactionType.deposit || transaction.type == TransactionType.release;
    final bool isEscrow = transaction.type == TransactionType.escrow;

    Color iconColor;
    IconData iconData;
    Color bgColor;

    if (isCredit) {
      iconColor = Colors.green.shade700;
      iconData = Icons.arrow_downward;
      bgColor = Colors.green.shade50;
    } else if (isEscrow) {
      iconColor = Colors.orange.shade700;
      iconData = Icons.lock_outline;
      bgColor = Colors.orange.shade50;
    } else {
      iconColor = Colors.red.shade700;
      iconData = Icons.arrow_upward;
      bgColor = Colors.red.shade50;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        title: Text(
          description,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.createdAt),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+' : '-'} ${currencyFormat.format(transaction.amount)}',
              style: GoogleFonts.outfit(
                color: isCredit ? Colors.green.shade700 : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (isEscrow)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('IN ESCROW', style: TextStyle(fontSize: 9, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
