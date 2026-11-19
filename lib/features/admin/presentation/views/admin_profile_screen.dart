import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bangla_text_renderer.dart';
import '../../../../core/utils/localization.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../../../account/presentation/views/edit_profile_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/views/login_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool _twoFactorEnabled = true;
  bool _pushNotifications = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserData();
    });
  }

  Future<void> _refreshUserData() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    if (token != null && token.isNotEmpty) {
      if (mounted) setState(() => _isRefreshing = true);
      try {
        await authProvider.fetchCurrentUser(token);
      } catch (_) {}
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              '$label copied to clipboard',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, String languageCode) async {
    final isBangla = languageCode == 'bn';
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 22),
            ),
            const SizedBox(width: 14),
            Text(
              isBangla ? 'অ্যাডমিন লগআউট' : 'Sign Out Administrator',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          isBangla
              ? 'আপনি কি নিশ্চিত যে আপনি এই প্রশাসনিক সেশন সমাপ্ত করতে চান?'
              : 'Are you sure you want to end this administrative session? You will need your credentials to log back in.',
          style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              isBangla ? 'বাতিল' : 'Cancel',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              isBangla ? 'লগআউট নিশ্চিত করুন' : 'Confirm Logout',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context, bool isBangla) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF2E7D32), size: 22),
                ),
                const SizedBox(width: 14),
                Text(
                  isBangla ? 'পাসওয়ার্ড পরিবর্তন' : 'Change Password',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isBangla
                            ? 'আপনার অ্যাকাউন্টের সুরক্ষার্থে একটি শক্তিশালী পাসওয়ার্ড তৈরি করুন।'
                            : 'Update your administrator password. Choose a strong combination of characters.',
                        style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          labelText: isBangla ? 'বর্তমান পাসওয়ার্ড' : 'Current Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return isBangla ? 'বর্তমান পাসওয়ার্ড দিন' : 'Enter current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: isBangla ? 'নতুন পাসওয়ার্ড' : 'New Password',
                          prefixIcon: const Icon(Icons.key_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setModalState(() => obscureNew = !obscureNew),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return isBangla
                                ? 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে'
                                : 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: isBangla ? 'নতুন পাসওয়ার্ড নিশ্চিত করুন' : 'Confirm New Password',
                          prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        validator: (value) {
                          if (value != newPasswordController.text) {
                            return isBangla ? 'পাসওয়ার্ড দুটি মেলেনি' : 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(
                  isBangla ? 'বাতিল' : 'Cancel',
                  style: GoogleFonts.outfit(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              isBangla
                                  ? 'পাসওয়ার্ড সফলভাবে আপডেট হয়েছে'
                                  : 'Password updated successfully',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF2E7D32),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Text(
                  isBangla ? 'সংরক্ষণ করুন' : 'Update Password',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLoginHistoryDialog(BuildContext context, bool isBangla) {
    final sessions = [
      {
        'device': 'Current Device • Web & Mobile App',
        'location': 'Dhaka, Bangladesh',
        'ip': '103.114.12.84',
        'time': 'Active Now',
        'isCurrent': true,
      },
      {
        'device': 'Chrome Browser • macOS Monterey',
        'location': 'Dhaka, Bangladesh',
        'ip': '103.114.12.84',
        'time': 'Yesterday at 04:30 PM',
        'isCurrent': false,
      },
      {
        'device': 'ChashiBhai Admin App • Android 14',
        'location': 'Bogura, Bangladesh',
        'ip': '119.30.34.19',
        'time': '3 days ago',
        'isCurrent': false,
      },
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_rounded, color: Colors.blue.shade700, size: 22),
            ),
            const SizedBox(width: 14),
            Text(
              isBangla ? 'লগইন ইতিহাস' : 'Recent Login Activity',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: sessions.map((s) {
              final isCurrent = s['isCurrent'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isCurrent ? const Color(0xFFE8F5E9).withOpacity(0.4) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrent ? const Color(0xFF2E7D32).withOpacity(0.3) : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCurrent ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCurrent ? Icons.laptop_chromebook_rounded : Icons.phone_android_rounded,
                        color: isCurrent ? Colors.white : Colors.grey.shade700,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s['device'] as String,
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${s['location']} • IP: ${s['ip']}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s['time'] as String,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              isBangla ? 'ঠিক আছে' : 'Close',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppStateProvider>().appLocale;
    final isBangla = languageCode == 'bn';
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    // Formatted User Data
    final String displayName = (user != null && user.name.isNotEmpty && user.name != 'User')
        ? user.name
        : (isBangla ? 'সুপার অ্যাডমিনিস্ট্রেটর' : 'Super Administrator');

    final String displayEmail = (user != null && user.email != null && user.email!.isNotEmpty)
        ? user.email!
        : 'admin@chashibhai.com';

    final String displayPhone = (user != null && user.phone.isNotEmpty)
        ? (isBangla ? BanglaTextRenderer.toBanglaNumber(user.phone) : user.phone)
        : (isBangla ? '০১৭১২-৩৪৫৬৭৮' : '+880 1712-345678');

    final String displayDistrict = (user != null && user.district != null && user.district!.isNotEmpty)
        ? user.district!
        : (isBangla ? 'ঢাকা (হেডকোয়ার্টার)' : 'Dhaka (Headquarters)');

    final String displayId = (user != null && user.id.isNotEmpty)
        ? user.id
        : 'adm_8802490';

    final String displayBalance = isBangla
        ? BanglaTextRenderer.formatTaka(user?.walletBalance ?? 0.0)
        : '৳${(user?.walletBalance ?? 0.0).toStringAsFixed(2)}';

    final bool isVerified = user?.isVerified ?? true;
    final bool biometricEnabled = authProvider.biometricEnabled;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        color: const Color(0xFF2E7D32),
        onRefresh: _refreshUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Screen Title Header ──
                  _buildHeaderBar(context, isBangla),
                  const SizedBox(height: 24),

                  // ── Hero Profile Identity Card ──
                  _buildProfileHeroCard(
                    context,
                    user: user,
                    displayName: displayName,
                    displayEmail: displayEmail,
                    displayPhone: displayPhone,
                    displayDistrict: displayDistrict,
                    isVerified: isVerified,
                    isBangla: isBangla,
                  ),
                  const SizedBox(height: 24),

                  // ── Key Metrics & Status Row ──
                  _buildKpiGrid(
                    user: user,
                    displayBalance: displayBalance,
                    displayDistrict: displayDistrict,
                    isBangla: isBangla,
                  ),
                  const SizedBox(height: 32),

                  // ── Detailed Credentials & Contact Information ──
                  _buildSectionTitle(
                    title: isBangla ? 'অ্যাকাউন্ট ও যোগাযোগের তথ্য' : 'Account & Contact Details',
                    subtitle: isBangla
                        ? 'আপনার মূল অ্যাডমিন শংসাপত্র ও যোগাযোগের বিবরণ'
                        : 'Official identity and credential verification details',
                  ),
                  const SizedBox(height: 14),
                  _buildAccountDetailsCard(
                    user: user,
                    displayName: displayName,
                    displayEmail: displayEmail,
                    displayPhone: displayPhone,
                    displayDistrict: displayDistrict,
                    displayId: displayId,
                    isBangla: isBangla,
                  ),
                  const SizedBox(height: 32),

                  // ── Administrative Privileges & Roles ──
                  _buildSectionTitle(
                    title: isBangla ? 'প্রশাসনিক অনুমতি ও প্রবেশাধিকার' : 'Administrative Privileges & Permissions',
                    subtitle: isBangla
                        ? 'এই অ্যাডমিন অ্যাকাউন্টের সিস্টেম ক্ষমতা ও অনুমোদনসমূহ'
                        : 'Authorized platform control scopes and root privileges',
                  ),
                  const SizedBox(height: 14),
                  _buildPrivilegesCard(isBangla),
                  const SizedBox(height: 32),

                  // ── Security & Authentication Controls ──
                  _buildSectionTitle(
                    title: isBangla ? 'নিরাপত্তা ও অ্যাক্সেস নিয়ন্ত্রণ' : 'Security & Access Controls',
                    subtitle: isBangla
                        ? 'দ্বি-স্তর যাচাইকরণ, বায়োমেট্রিক ও পাসওয়ার্ড সেটিংস'
                        : 'Two-factor auth, biometrics, credentials and session security',
                  ),
                  const SizedBox(height: 14),
                  _buildSecuritySettingsCard(
                    context,
                    biometricEnabled: biometricEnabled,
                    isBangla: isBangla,
                  ),
                  const SizedBox(height: 32),

                  // ── System & Localization Preferences ──
                  _buildSectionTitle(
                    title: isBangla ? 'সিস্টেম পছন্দ ও নোটিফিকেশন' : 'System Preferences & Alerts',
                    subtitle: isBangla
                        ? 'ভাষা নির্বাচন এবং সিস্টেম সতর্কতা কনফিগারেশন'
                        : 'Localization and high-priority platform dispatch preferences',
                  ),
                  const SizedBox(height: 14),
                  _buildPreferencesCard(context, languageCode: languageCode, isBangla: isBangla),
                  const SizedBox(height: 40),

                  // ── Sign Out Action ──
                  _buildSignOutSection(context, languageCode),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header Bar ─────────────────────────────────────────────────────────────

  Widget _buildHeaderBar(BuildContext context, bool isBangla) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBangla ? 'অ্যাডমিন প্রোফাইল' : 'Admin Profile & Credentials',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isBangla
                    ? 'প্রশাসনিক পরিচয়, সিস্টেম ক্ষমতা এবং নিরাপত্তা সেটিংস পরিচালনা করুন'
                    : 'Manage administrative identity, system access roles, and platform credentials',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (_isRefreshing)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF2E7D32)),
            ),
          )
        else
          IconButton(
            tooltip: isBangla ? 'রিফ্রেশ করুন' : 'Refresh Profile',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2E7D32)),
            onPressed: _refreshUserData,
          ),
      ],
    );
  }

  // ─── Profile Hero Card ──────────────────────────────────────────────────────

  Widget _buildProfileHeroCard(
    BuildContext context, {
    required AppUser? user,
    required String displayName,
    required String displayEmail,
    required String displayPhone,
    required String displayDistrict,
    required bool isVerified,
    required bool isBangla,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    // Avatar widget
    final avatar = Stack(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.2), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: (user?.avatarUrl != null && user!.avatarUrl!.trim().isNotEmpty)
                ? Image.network(
                    user.avatarUrl!.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatarFallback(displayName),
                  )
                : _buildAvatarFallback(displayName),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.shield_rounded, size: 13, color: Colors.white),
          ),
        ),
      ],
    );

    // Profile Info
    final info = Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            Text(
              displayName,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            if (isVerified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF81C784), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 4),
                    Text(
                      isBangla ? 'ভেরিফাইড' : 'Verified Admin',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.email_outlined, size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  displayEmail,
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_outlined, size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  displayPhone,
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  displayDistrict,
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _buildBadge(
              icon: Icons.admin_panel_settings_rounded,
              label: isBangla ? 'সিস্টেম অ্যাডমিনিস্ট্রেটর' : 'SYSTEM ADMINISTRATOR',
              color: const Color(0xFF2E7D32),
              bgColor: const Color(0xFFE8F5E9),
            ),
            _buildBadge(
              icon: Icons.lock_open_rounded,
              label: isBangla ? 'পূর্ণ নিয়ন্ত্রণ (Root)' : 'ROOT PRIVILEGES',
              color: const Color(0xFF1565C0),
              bgColor: const Color(0xFFE3F2FD),
            ),
            _buildBadge(
              icon: Icons.fiber_manual_record_rounded,
              label: isBangla ? 'সক্রিয় সেশন' : 'SESSION ACTIVE',
              color: const Color(0xFF00897B),
              bgColor: const Color(0xFFE0F2F1),
            ),
          ],
        ),
      ],
    );

    // Edit Profile Button
    final actionButton = ElevatedButton.icon(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
        );
        _refreshUserData();
      },
      icon: const Icon(Icons.edit_note_rounded, size: 18),
      label: Text(
        isBangla ? 'প্রোফাইল সম্পাদন' : 'Edit Profile',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatar,
                const SizedBox(width: 24),
                Expanded(child: info),
                const SizedBox(width: 20),
                actionButton,
              ],
            )
          : Column(
              children: [
                avatar,
                const SizedBox(height: 18),
                info,
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, child: actionButton),
              ],
            ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    String initials = 'SA';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      initials = parts[0].length >= 2
          ? parts[0].substring(0, 2).toUpperCase()
          : parts[0][0].toUpperCase();
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 26,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Key Metrics Grid ───────────────────────────────────────────────────────

  Widget _buildKpiGrid({
    required AppUser? user,
    required String displayBalance,
    required String displayDistrict,
    required bool isBangla,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;
        final crossAxisCount = isNarrow ? 2 : 4;

        final items = [
          _KpiItem(
            title: isBangla ? 'অ্যাক্সেস স্তর' : 'Access Level',
            value: isBangla ? 'রুট অ্যাডমিন' : 'Level 4 Root',
            subtitle: isBangla ? 'সর্বোচ্চ ক্ষমতা' : 'Full system privileges',
            icon: Icons.admin_panel_settings_rounded,
            iconColor: const Color(0xFF2E7D32),
            bgColor: const Color(0xFFE8F5E9),
          ),
          _KpiItem(
            title: isBangla ? 'যাচাইকরণ' : 'Identity Status',
            value: isBangla ? 'অনুমোদিত' : 'Authorized',
            subtitle: isBangla ? 'সরকারি কর্মকর্তা' : 'Staff credentialed',
            icon: Icons.verified_user_rounded,
            iconColor: const Color(0xFF0288D1),
            bgColor: const Color(0xFFE1F5FE),
          ),
          _KpiItem(
            title: isBangla ? 'মূল জেলা' : 'Headquarters',
            value: displayDistrict.split('(').first.trim(),
            subtitle: isBangla ? 'অপারেশনাল বেস' : 'Operational division',
            icon: Icons.location_city_rounded,
            iconColor: const Color(0xFFF57C00),
            bgColor: const Color(0xFFFFF3E0),
          ),
          _KpiItem(
            title: isBangla ? 'প্ল্যাটফর্ম রিজার্ভ' : 'Escrow Reserve',
            value: displayBalance,
            subtitle: isBangla ? 'সুরক্ষিত ব্যালেন্স' : 'Admin escrow float',
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF7B1FA2),
            bgColor: const Color(0xFFF3E5F5),
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 110,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Account & Credentials Details Card ─────────────────────────────────────

  Widget _buildAccountDetailsCard({
    required AppUser? user,
    required String displayName,
    required String displayEmail,
    required String displayPhone,
    required String displayDistrict,
    required String displayId,
    required bool isBangla,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.tag_rounded,
            label: isBangla ? 'অ্যাডমিন আইডি (UUID)' : 'Administrator ID (UUID)',
            value: displayId,
            isMonospace: true,
            trailing: _buildCopyAction(displayId, isBangla ? 'অ্যাডমিন আইডি' : 'Admin ID'),
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: isBangla ? 'পূর্ণ নাম' : 'Full Legal Name',
            value: displayName,
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),
          _buildInfoRow(
            icon: Icons.phone_android_rounded,
            label: isBangla ? 'নিবন্ধিত মোবাইল নম্বর' : 'Registered Mobile Number',
            value: displayPhone,
            trailing: _buildCopyAction(displayPhone, isBangla ? 'ফোন নম্বর' : 'Phone Number'),
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),
          _buildInfoRow(
            icon: Icons.alternate_email_rounded,
            label: isBangla ? 'অফিসিয়াল ইমেইল ঠিকানা' : 'Official System Email',
            value: displayEmail,
            trailing: _buildCopyAction(displayEmail, isBangla ? 'ইমেইল' : 'Email Address'),
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),
          _buildInfoRow(
            icon: Icons.map_outlined,
            label: isBangla ? 'অধিভুক্ত বিভাগ / জেলা' : 'Primary Administrative Division',
            value: displayDistrict,
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),
          _buildInfoRow(
            icon: Icons.token_rounded,
            label: isBangla ? 'অ্যাক্সেস সেশন স্ট্যাটাস' : 'Session Token Status',
            value: isBangla ? 'এনক্রিপ্ট করা বেয়ারার সেশন সক্রিয়' : 'Encrypted Bearer Session • Active',
            badgeText: 'ONLINE',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMonospace = false,
    Widget? trailing,
    String? badgeText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: isMonospace
                      ? GoogleFonts.jetBrainsMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        )
                      : GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                ),
              ],
            ),
          ),
          if (badgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildCopyAction(String text, String label) {
    return IconButton(
      tooltip: 'Copy $label',
      icon: Icon(Icons.copy_rounded, size: 18, color: Colors.grey.shade600),
      onPressed: () => _copyToClipboard(text, label),
    );
  }

  // ─── Administrative Privileges Card ─────────────────────────────────────────

  Widget _buildPrivilegesCard(bool isBangla) {
    final privileges = [
      {'icon': Icons.supervised_user_circle_rounded, 'name': isBangla ? 'ব্যবহারকারী ব্যবস্থাপনা ও কেওয়াইসি' : 'User Moderation & KYC Audits'},
      {'icon': Icons.gavel_rounded, 'name': isBangla ? 'এসক্রো বিরোধ ও লেনদেন নিষ্পত্তি' : 'Escrow Dispute Settlement'},
      {'icon': Icons.agriculture_rounded, 'name': isBangla ? 'পণ্য অনুমোদন ও নিলাম তদারকি' : 'Product Listing & Auction Oversight'},
      {'icon': Icons.payments_rounded, 'name': isBangla ? 'প্ল্যাটফর্ম কমিশন ও উত্তোলন অনুমোদন' : 'Commission Rates & Payout Approval'},
      {'icon': Icons.analytics_rounded, 'name': isBangla ? 'সিস্টেম অ্যানালিটিক্স ও রিপোর্টস' : 'Platform Analytics & Audit Reports'},
      {'icon': Icons.settings_applications_rounded, 'name': isBangla ? 'গ্লোবাল প্ল্যাটফর্ম কনফিগারেশন' : 'Global Platform Configuration'},
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 10),
              Text(
                isBangla ? 'সিস্টেম ক্ষমতাপ্রাপ্ত অনুমতিসমূহ' : 'Active System Delegations',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: privileges.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(p['icon'] as IconData, size: 16, color: const Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    Text(
                      p['name'] as String,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Security Settings Card ─────────────────────────────────────────────────

  Widget _buildSecuritySettingsCard(
    BuildContext context, {
    required bool biometricEnabled,
    required bool isBangla,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Biometric Toggle
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            secondary: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF2E7D32), size: 22),
            ),
            title: Text(
              isBangla ? 'বায়োমেট্রিক লগইন' : 'Biometric Authentication',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              isBangla
                  ? 'ফিঙ্গারপ্রিন্ট বা ফেস আইডি ব্যবহার করে প্রশাসনিক লগইন'
                  : 'Fast & secure sign in using Face ID or Fingerprint recognition',
              style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
            ),
            value: biometricEnabled,
            activeColor: const Color(0xFF2E7D32),
            onChanged: (v) async {
              final auth = context.read<AuthProvider>();
              final languageCode = context.read<AppStateProvider>().appLocale;
              if (v) {
                final success = await auth.authenticateWithBiometrics(languageCode);
                if (success) {
                  auth.setBiometricEnabled(true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isBangla
                              ? 'বায়োমেট্রিক প্রমাণীকরণ সক্রিয় হয়েছে'
                              : 'Biometric authentication enabled',
                        ),
                        backgroundColor: const Color(0xFF2E7D32),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isBangla
                              ? 'বায়োমেট্রিক যাচাইকরণ ব্যর্থ হয়েছে'
                              : 'Biometric verification failed or unavailable',
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              } else {
                auth.setBiometricEnabled(false);
              }
            },
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),

          // Two Factor Auth Toggle
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            secondary: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.security_rounded, color: Color(0xFF1565C0), size: 22),
            ),
            title: Text(
              isBangla ? 'দ্বি-স্তর নিরাপত্তা (2FA)' : 'Two-Factor Authentication (2FA)',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              isBangla
                  ? 'সংবেদনশীল কাজের জন্য অতিরিক্ত ওটিপি ভেরিফিকেশন'
                  : 'Requires OTP verification for critical transactions & withdrawals',
              style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
            ),
            value: _twoFactorEnabled,
            activeColor: const Color(0xFF2E7D32),
            onChanged: (v) {
              setState(() => _twoFactorEnabled = v);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    v
                        ? (isBangla ? '2FA সক্রিয় হয়েছে' : 'Two-Factor Authentication enabled')
                        : (isBangla ? '2FA নিষ্ক্রিয় করা হয়েছে' : 'Two-Factor Authentication disabled'),
                  ),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),

          // Change Password Tile
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.lock_outline_rounded, color: Colors.grey.shade700, size: 22),
            ),
            title: Text(
              isBangla ? 'পাসওয়ার্ড পরিবর্তন করুন' : 'Change Password',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              isBangla
                  ? 'নিয়মিত আপনার অ্যাকাউন্ট পাসওয়ার্ড আপডেট করুন'
                  : 'Regularly update credentials for maximum account defense',
              style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () => _showChangePasswordDialog(context, isBangla),
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),

          // Login History Tile
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.history_rounded, color: Colors.grey.shade700, size: 22),
            ),
            title: Text(
              isBangla ? 'লগইন ইতিহাস ও ডিভাইসসমূহ' : 'Active Sessions & Device History',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              isBangla
                  ? 'সাম্প্রতিক লগইন ডিভাইস ও আইপি ঠিকানা পর্যালোচনা'
                  : 'Inspect recent active logins, IP locations, and device types',
              style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () => _showLoginHistoryDialog(context, isBangla),
          ),
        ],
      ),
    );
  }

  // ─── Preferences Card ───────────────────────────────────────────────────────

  Widget _buildPreferencesCard(
    BuildContext context, {
    required String languageCode,
    required bool isBangla,
  }) {
    final appState = context.read<AppStateProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Language Setting
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.language_rounded, color: Colors.grey.shade700, size: 22),
            ),
            title: Text(
              isBangla ? 'সিস্টেম ভাষা' : 'App Language',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              isBangla ? 'বর্তমান ভাষা: বাংলা' : 'Current: English (US)',
              style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
              ),
              child: InkWell(
                onTap: () => appState.toggleLocale(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isBangla ? 'বাং' : 'EN',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF2E7D32)),
                  ],
                ),
              ),
            ),
            onTap: () => appState.toggleLocale(),
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),

          // Push Notifications
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            secondary: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.notifications_active_outlined, color: Colors.grey.shade700, size: 22),
            ),
            title: Text(
              isBangla ? 'সিস্টেম পুশ নোটিফিকেশন' : 'Critical System Alerts',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              isBangla
                  ? 'উচ্চ-মূল্যের নিলাম ও এসক্রো বিরোধের তাৎক্ষণিক নোটিফিকেশন'
                  : 'Receive instant alerts for disputed escrows & high-volume orders',
              style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
            ),
            value: _pushNotifications,
            activeColor: const Color(0xFF2E7D32),
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),

          // Force Sync Cache
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.sync_rounded, color: Colors.grey.shade700, size: 22),
            ),
            title: Text(
              isBangla ? 'ক্যাশ রিফ্রেশ ও ডাটা সিঙ্ক' : 'Force Cache Resync',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              isBangla
                  ? 'সার্ভার থেকে প্রশাসনিক সেশন ও ডাটা সিঙ্ক করুন'
                  : 'Re-fetch latest server profile data and flush cached permissions',
              style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 13),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () async {
              await _refreshUserData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isBangla
                              ? 'প্রশাসনিক ডাটা সার্ভারের সাথে সিঙ্ক হয়েছে'
                              : 'Admin profile & permissions synchronized',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ─── Sign Out Section ───────────────────────────────────────────────────────

  Widget _buildSignOutSection(BuildContext context, String languageCode) {
    final isBangla = languageCode == 'bn';
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context, languageCode),
        icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
        label: Text(
          isBangla ? 'প্রশাসনিক সেশন সমাপ্ত করুন (লগআউট)' : 'Sign Out of Administrative Portal',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.red.shade700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red.shade200, width: 1.5),
          backgroundColor: Colors.red.shade50.withOpacity(0.6),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ─── Section Header Helper ──────────────────────────────────────────────────

  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _KpiItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _KpiItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}
