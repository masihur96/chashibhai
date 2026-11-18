import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/models.dart';
import '../../../../core/utils/bangla_text_renderer.dart';
import '../../../../core/utils/localization.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../state/app_state_provider.dart';
import './edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      if (token != null && token.isNotEmpty) {
        authProvider.fetchCurrentUser(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppStateProvider>().appLocale;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    String roleName = 'buyer'.tr(languageCode);
    IconData roleIcon = Icons.storefront_rounded;
    if (user?.role == UserRole.farmer) {
      roleName = 'farmer'.tr(languageCode);
      roleIcon = Icons.agriculture_rounded;
    } else if (user?.role == UserRole.admin) {
      roleName = 'Admin';
      roleIcon = Icons.admin_panel_settings_rounded;
    }

    final String displayName = user?.name.isNotEmpty == true
        ? user!.name
        : (languageCode == 'bn' ? 'ব্যবহারকারী' : 'User');
    final String displayPhone = user?.phone.isNotEmpty == true
        ? (languageCode == 'bn' ? BanglaTextRenderer.toBanglaNumber(user!.phone) : user!.phone)
        : 'N/A';
    final String displayId = user?.id.isNotEmpty == true ? user!.id : 'N/A';

    final String displayBalance = languageCode == 'bn'
        ? BanglaTextRenderer.formatTaka(user?.walletBalance ?? 0.0)
        : '৳${user?.walletBalance.toStringAsFixed(2) ?? "0.00"}';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'profile'.tr(languageCode),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Refresh profile from /auth/me if token exists
          if (authProvider.token != null && authProvider.token!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: () async {
                final token = authProvider.token!;
                await authProvider.fetchCurrentUser(token);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(languageCode == 'bn' ? 'প্রোফাইল আপডেট হয়েছে' : 'Profile refreshed'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  );
                }
              },
            ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguageToggleButton(
              compact: true,
              activeColor: Colors.white,
              backgroundColor: Colors.white24,
              inactiveColor: Colors.white70,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final token = authProvider.token;
          if (token != null && token.isNotEmpty) {
            await authProvider.fetchCurrentUser(token);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header with Avatar and User Name
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: Colors.white,
                        backgroundImage: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                            ? Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User Name
                    Text(
                      displayName,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),

                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(roleIcon, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            roleName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Profile Info Details List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    _buildProfileTile(
                      icon: Icons.phone_outlined,
                      label: 'phone_number'.tr(languageCode),
                      value: displayPhone,
                    ),
                    if (user?.email != null && user!.email!.isNotEmpty)
                      _buildProfileTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email!,
                      ),
                    _buildProfileTile(
                      icon: Icons.badge_outlined,
                      label: 'user_id'.tr(languageCode),
                      value: displayId,
                    ),
                    _buildProfileTile(
                      icon: Icons.work_outline_rounded,
                      label: 'account_role'.tr(languageCode),
                      value: roleName,
                    ),
                    _buildProfileTile(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'wallet_balance'.tr(languageCode),
                      value: displayBalance,
                    ),
                    _buildProfileTile(
                      icon: Icons.verified_user_outlined,
                      label: 'account_status'.tr(languageCode),
                      value: user?.isVerified == true
                          ? 'verified'.tr(languageCode)
                          : 'unverified'.tr(languageCode),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: user?.isVerified == true ? Colors.green.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: user?.isVerified == true ? Colors.green.shade300 : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              user?.isVerified == true ? Icons.check_circle : Icons.help_outline,
                              size: 14,
                              color: user?.isVerified == true ? Colors.green.shade700 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user?.isVerified == true
                                  ? 'verified'.tr(languageCode)
                                  : 'unverified'.tr(languageCode),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: user?.isVerified == true ? Colors.green.shade800 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildProfileTile(
                      icon: Icons.star_outline_rounded,
                      label: 'user_rating'.tr(languageCode),
                      value: languageCode == 'bn'
                          ? '${BanglaTextRenderer.toBanglaNumber((user?.rating ?? 0.0).toStringAsFixed(1))} / ৫.০'
                          : '${(user?.rating ?? 0.0).toStringAsFixed(1)} / 5.0',
                    ),
                    const SizedBox(height: 24),

                    // Edit Profile Button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(
                        'edit_profile'.tr(languageCode),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Logout Button
                    OutlinedButton.icon(
                      onPressed: () async {
                        await authProvider.logout();
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      label: Text(
                        'logout'.tr(languageCode),
                        style: const TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
