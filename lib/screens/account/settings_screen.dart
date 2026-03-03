import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          _buildSectionHeader('General'),
          _buildSwitchTile(
            Icons.notifications_active_outlined,
            'Push Notifications',
            'Receive alerts about your orders',
            _notificationsEnabled,
            (v) => setState(() => _notificationsEnabled = v),
          ),
          _buildLanguageTile(),
          
          const Divider(height: 40),
          _buildSectionHeader('Security'),
          _buildSwitchTile(
            Icons.fingerprint_rounded,
            'Biometric Login',
            'Use fingerprint or face recognition',
            _biometricEnabled,
            (v) => setState(() => _biometricEnabled = v),
          ),
          _buildActionTile(Icons.lock_outline_rounded, 'Change Password', 'Update your account password'),
          
          const Divider(height: 40),
          _buildSectionHeader('Other'),
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
        title.toUpperCase(),
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

  Widget _buildLanguageTile() {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: const Icon(Icons.language_rounded, color: Color(0xFF2E7D32)),
        title: const Text('App Language', style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(_selectedLanguage, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {
          // Show language picker
        },
      ),
    );
  }
}
