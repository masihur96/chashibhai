import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Profile', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildProfileHeader(context),
            const SizedBox(height: 32),
            _buildSectionHeader('Security Settings'),
            const SizedBox(height: 16),
            _buildSettingsCard([
              _buildSettingsTile(Icons.lock_outline, 'Change Password', 'Update your account password', () {}),
              _buildSettingsTile(
                Icons.security_outlined, 
                'Two-Factor Authentication', 
                'Enhance account security', 
                () {}, 
                trailing: Switch(
                  value: true, 
                  onChanged: (v){}, 
                  activeColor: const Color(0xFF2E7D32),
                ),
              ),
              _buildSettingsTile(Icons.history, 'Login History', 'View recent account activity', () {}),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('Preferences'),
            const SizedBox(height: 16),
            _buildSettingsCard([
              _buildSettingsTile(Icons.notifications_none, 'Notifications', 'Manage alert preferences', () {}),
              _buildSettingsTile(Icons.language, 'Language', 'English (US)', () {}),
              _buildSettingsTile(Icons.dark_mode_outlined, 'Theme', 'System Default', () {}),
            ]),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    final avatar = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.2), width: 2),
      ),
      child: const Icon(Icons.admin_panel_settings, size: 40, color: Color(0xFF2E7D32)),
    );

    final info = Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          'Super Admin',
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'admin@chashibhai.com',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'System Administrator',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ],
    );

    final actionButton = OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2E7D32),
        side: const BorderSide(color: Color(0xFF2E7D32)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Edit Profile'),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: isDesktop
          ? Row(
              children: [
                avatar,
                const SizedBox(width: 24),
                Expanded(child: info),
                actionButton,
              ],
            )
          : Column(
              children: [
                avatar,
                const SizedBox(height: 16),
                info,
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: actionButton),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final isLast = entry.key == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast) Divider(height: 1, indent: 64, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, VoidCallback onTap, {Widget? trailing}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.grey.shade700),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: trailing == null ? onTap : null,
    );
  }
}
