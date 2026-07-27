import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../buyer/presentation/state/product_provider.dart';
import '../../../group/presentation/state/group_provider.dart';
import '../../../buyer/presentation/state/demand_provider.dart';
import '../../../wallet/presentation/state/order_provider.dart';
import '../state/app_state_provider.dart';
import '../../../../core/utils/localization.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppStateProvider>().appLocale;
    final biometricEnabled = context.watch<AuthProvider>().biometricEnabled;
    final isBangla = languageCode == 'bn';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'settings'.tr(languageCode),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          _buildSectionHeader('General'.toUpperCase()),
          _buildSwitchTile(
            Icons.notifications_active_outlined,
            'push_notifications'.tr(languageCode),
            'Receive alerts about your orders',
            _notificationsEnabled,
            (v) => setState(() => _notificationsEnabled = v),
          ),
          _buildLanguageTile(languageCode),
          
          const Divider(height: 40),
          _buildSectionHeader('Security'.toUpperCase()),
          _buildSwitchTile(
            Icons.fingerprint_rounded,
            'biometric'.tr(languageCode),
            'Use fingerprint or face recognition',
            biometricEnabled,
            (v) async {
              if (v) {
                // Verify biometric before enabling
                final authenticated = await context.read<AuthProvider>().authenticateWithBiometrics(languageCode);
                if (authenticated) {
                  context.read<AuthProvider>().setBiometricEnabled(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isBangla ? 'বায়োমেট্রিক যাচাইকরণ ব্যর্থ হয়েছে' : 'Biometric verification failed'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } else {
                context.read<AuthProvider>().setBiometricEnabled(false);
              }
            },
          ),
          _buildActionTile(Icons.lock_outline_rounded, 'Change Password', 'Update your account password'),
          
          const Divider(height: 40),
          _buildSectionHeader('Other'.toUpperCase()),
          _buildActionTile(Icons.privacy_tip_outlined, 'Privacy Policy', 'Review our privacy terms'),
          _buildActionTile(Icons.description_outlined, 'Terms of Service', 'Read our user agreement'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      color: Colors.white,
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFF2E7D32)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2E7D32),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2E7D32)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {},
      ),
    );
  }

  Widget _buildLanguageTile(String languageCode) {
    final languageName = languageCode == 'en' ? 'English' : 'বাংলা (Bangla)';

    return Container(
      color: Colors.white,
      child: ListTile(
        leading: const Icon(Icons.language_rounded, color: Color(0xFF2E7D32)),
        title: Text('language'.tr(languageCode), style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(languageName, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () => _showLanguagePicker(context, languageCode),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, String currentLocale) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Language',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildLanguageOption(context, 'English', 'en', currentLocale == 'en'),
              _buildLanguageOption(context, 'বাংলা (Bangla)', 'bn', currentLocale == 'bn'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String name, String code, bool isSelected) {
    return ListTile(
      title: Text(name),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32)) : null,
      onTap: () {
        context.read<AppStateProvider>().setAppLocale(code);
        Navigator.pop(context);
      },
    );
  }
}
