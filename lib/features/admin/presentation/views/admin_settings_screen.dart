import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/widgets/custom_buttons.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Settings', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Configure global variables and external API integrations.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Financial Configuration', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(height: 32),
                _buildConfigRow('Global Commission Rate (%)', '1.0'),
                const SizedBox(height: 16),
                _buildConfigRow('Escrow Fee Rate (%)', '1.0'),
                const SizedBox(height: 16),
                _buildConfigRow('Minimum Withdrawal (৳)', '500'),
                
                const SizedBox(height: 48),
                Text('External Integrations', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(height: 32),
                _buildConfigRow('bKash API Base URL', 'https://api.bkash.com/v1.2.0-beta'),
                const SizedBox(height: 16),
                _buildConfigRow('SMS Gateway API Key', '••••••••••••••••••••••••'),
                
                const SizedBox(height: 48),
                Align(
                  alignment: Alignment.centerRight,
                  child: PrimaryButton(
                    text: 'Save Configurations',
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
        Expanded(
          flex: 3,
          child: TextField(
            controller: TextEditingController(text: value),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
