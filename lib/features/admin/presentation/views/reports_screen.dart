import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Reports', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Generate and download platform data reports for accounting and compliance.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _buildReportCard(
                context,
                'Monthly Sales Summary',
                'Aggregated GMV, commission collected, and total order volume for the current month.',
                Icons.insert_chart_outlined,
              ),
              _buildReportCard(
                context,
                'Tax & Compliance Ledger',
                'Detailed transaction history for tax filing and audit compliance.',
                Icons.account_balance_outlined,
              ),
              _buildReportCard(
                context,
                'User Onboarding Metrics',
                'Breakdown of new KYC verifications and user growth across regions.',
                Icons.group_add_outlined,
              ),
              _buildReportCard(
                context,
                'Dispute Resolution Log',
                'History of all forced escrow releases and refunds processed by admins.',
                Icons.gavel_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, String description, IconData icon) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 16),
          Text(description, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('CSV'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
