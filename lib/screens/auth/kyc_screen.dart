import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/demand_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/app_state_provider.dart';

class KYCScreen extends StatefulWidget {
  final String name;
  final String phone;
  final UserRole role;

  const KYCScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.role,
  });

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC Verification')),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(Icons.verified_user_outlined, size: 80, color: Color(0xFF2E7D32)),
            const SizedBox(height: 24),
            Text(
              'Verify Your Identity',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload your NID or Trade License to start trading on ChashiBhai.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _buildUploadCard(
              title: widget.role == UserRole.farmer ? 'Trade License' : 'NID / National ID',
              icon: widget.role == UserRole.farmer ? Icons.assignment : Icons.badge,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitKYC,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Verification'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard({required String title, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Tap to upload document', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  void _submitKYC() async {
    setState(() => _isUploading = true);
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    
    final newUser = AppUser(
      id: 'unew',
      name: widget.name,
      role: widget.role,
      phone: widget.phone,
      rating: 0.0,
      walletBalance: 0.0,
      isVerified: true,
    );

    context.read<AuthProvider>().setCurrentUser(newUser);
    
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created and verified! Welcome.')),
      );
    }
  }
}
