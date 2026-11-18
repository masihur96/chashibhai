import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/mock_data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/localization.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../state/auth_provider.dart';
import './otp_screen.dart';
import './register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppStateProvider>().appLocale;

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
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Language Toggle
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: const LanguageToggleButton(compact: false),
                ),
              ),

              const Spacer(flex: 1),
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
              const SizedBox(height: 30),
              Text(
                'welcome_back'.tr(languageCode),
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'login_subtitle'.tr(languageCode),
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'phone_number'.tr(languageCode),
                  hintText: 'phone_hint'.tr(languageCode),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 24),
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
                        SnackBar(content: Text('enter_phone_error'.tr(languageCode))),
                      );
                    }
                  },
                  child: Text('send_otp'.tr(languageCode), style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 16),

              // Temporary Login Buttons
              const Center(
                child: Text(
                  '--- DEVELOPMENT SHORTCUTS ---',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () {
                      final user = MockData.currentUser.copyWith(role: UserRole.admin);
                      context.read<AuthProvider>().setCurrentUser(user);
                    },
                    child: const Text('Admin'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () {
                      final user = MockData.currentUser.copyWith(role: UserRole.buyer);
                      context.read<AuthProvider>().setCurrentUser(user);
                    },
                    child: const Text('Buyer'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () {
                      final user = MockData.currentUser.copyWith(role: UserRole.farmer);
                      context.read<AuthProvider>().setCurrentUser(user);
                    },
                    child: const Text('Farmer'),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              if (context.watch<AuthProvider>().biometricEnabled) ...[
                Center(
                  child: Text(
                    'or'.tr(languageCode),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final authenticated = await context
                          .read<AuthProvider>()
                          .authenticateWithBiometrics(languageCode);
                      if (authenticated) {
                        context.read<AuthProvider>().setCurrentUser(MockData.currentUser);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('login_success_biometric'.tr(languageCode)),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: Text(
                      'login_biometric'.tr(languageCode),
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${'dont_have_account'.tr(languageCode)} '),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      'register_now'.tr(languageCode),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
