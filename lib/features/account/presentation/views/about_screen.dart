import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'About ChashiBhai',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            _buildAppLogo(),
            const SizedBox(height: 24),
            _buildAppInfo(),
            const SizedBox(height: 48),
            _buildInfoTile('Version', '2.1.0 (Build 302)'),
            _buildInfoTile('Developer', 'ChashiBhai Technologies Ltd.'),
            _buildInfoTile('Privacy Policy', 'View Terms'),
            _buildInfoTile('License', 'Open Source'),
            const SizedBox(height: 60),
            Text(
              'Made with love in Bangladesh 🇧🇩',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.agriculture_rounded, size: 80, color: Color(0xFF2E7D32)),
    );
  }

  Widget _buildAppInfo() {
    return Column(
      children: [
        Text(
          'ChashiBhai',
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
        ),
        const SizedBox(height: 8),
        Text(
          'Connecting Farmers to Businesses',
          style: TextStyle(color: Colors.grey[600], fontSize: 14, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
          Text(value, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }
}
