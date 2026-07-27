import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import './registration_screen.dart';
import './otp_screen.dart';
import '../state/auth_provider.dart';
import '../../../buyer/presentation/state/product_provider.dart';
import '../../../group/presentation/state/group_provider.dart';
import '../../../buyer/presentation/state/demand_provider.dart';
import '../../../wallet/presentation/state/order_provider.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../../../../core/models/models.dart';
import '../../../../core/models/mock_data.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2E7D32).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(flex: 2),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.eco, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Welcome to ChashiBhai',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your trusted B2B agri marketplace. Login to continue trading.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'e.g., 017XXXXXXXX',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (_phoneController.text.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OTPScreen(phoneNumber: _phoneController.text),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your phone number')),
                    );
                  }
                },
                child: const Text('Send OTP', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
            
            // Temporary Login Buttons
            const Center(child: Text('--- DEVELOPMENT SHORTCUTS ---', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: () {
                    final user = MockData.currentUser.copyWith(role: UserRole.admin);
                    context.read<AuthProvider>().setCurrentUser(user);
                  },
                  child: const Text('Admin Login'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: () {
                    final user = MockData.currentUser.copyWith(role: UserRole.buyer);
                    context.read<AuthProvider>().setCurrentUser(user);
                  },
                  child: const Text('Buyer Login'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: () {
                    final user = MockData.currentUser.copyWith(role: UserRole.farmer);
                    context.read<AuthProvider>().setCurrentUser(user);
                  },
                  child: const Text('Farmer Login'),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            if (context.watch<AuthProvider>().biometricEnabled) ...[
              const Center(child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 12))),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final authenticated = await context.read<AuthProvider>().authenticateWithBiometrics(context.read<AppStateProvider>().appLocale);
                    if (authenticated) {
                      // Login as dummy user (Buyer)
                      context.read<AuthProvider>().setCurrentUser(MockData.currentUser);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Login successful via biometric!'),
                          backgroundColor: Color(0xFF2E7D32),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Login with Biometric', style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                    );
                  },
                  child: const Text(
                    'Register now',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
