import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bangla_text_renderer.dart';
import '../../../../core/utils/localization.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/views/login_screen.dart';
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

  void _openDrawer() {
    ScaffoldState? scaffold = Scaffold.maybeOf(context);
    if (scaffold == null || !scaffold.hasDrawer) {
      scaffold = context.findRootAncestorStateOfType<ScaffoldState>();
    }
    scaffold?.openDrawer();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label copied to clipboard', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, String languageCode) async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'logout'.tr(languageCode),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          languageCode == 'bn'
              ? 'আপনি কি নিশ্চিত যে আপনি আপনার চাষীভাই অ্যাকাউন্ট থেকে লগআউট করতে চান?'
              : 'Are you sure you want to log out of your ChashiBhai account?',
          style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              languageCode == 'bn' ? 'বাতিল' : 'Cancel',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              'logout'.tr(languageCode),
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
    final String displayDistrict = user?.district?.isNotEmpty == true
        ? user!.district!
        : (languageCode == 'bn' ? 'বগুড়া' : 'Bogura');

    final String displayBalance = languageCode == 'bn'
        ? BanglaTextRenderer.formatTaka(user?.walletBalance ?? 0.0)
        : '৳${(user?.walletBalance ?? 0.0).toStringAsFixed(2)}';

    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: RefreshIndicator(
        color: AppColors.primary,
        displacement: 60,
        onRefresh: () async {
          final token = authProvider.token;
          if (token != null && token.isNotEmpty) {
            await authProvider.fetchCurrentUser(token);
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Hero SliverAppBar (Consistent with FarmerDashboard) ───────
            _heroAppBar(
              context,
              user: user,
              displayName: displayName,
              displayDistrict: displayDistrict,
              displayBalance: displayBalance,
              roleName: roleName,
              roleIcon: roleIcon,
              languageCode: languageCode,
              authProvider: authProvider,
              canPop: canPop,
            ),

            // ── Main Profile Body Content ─────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    // 1. KPI Metric Summary Cards (Wallet, Rating, Verification)
                    _buildKpiSummaryRow(user, displayBalance, languageCode),
                    const SizedBox(height: 18),

                    // 2. Personal & Account Details Card
                    _buildAccountDetailsCard(
                      user: user,
                      displayName: displayName,
                      displayPhone: displayPhone,
                      displayId: displayId,
                      displayDistrict: displayDistrict,
                      roleName: roleName,
                      roleIcon: roleIcon,
                      languageCode: languageCode,
                    ),
                    const SizedBox(height: 18),

                    // 3. Settings & Preferences Card
                    _buildSettingsCard(languageCode),
                    const SizedBox(height: 24),

                    // 4. Action Buttons (Edit Profile + Logout)
                    _buildActionButtons(context, languageCode),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hero SliverAppBar ────────────────────────────────────────────────────────
  // Matches FarmerDashboard hero design with gradient and pinned collapse.

  Widget _heroAppBar(
    BuildContext context, {
    required AppUser? user,
    required String displayName,
    required String displayDistrict,
    required String displayBalance,
    required String roleName,
    required IconData roleIcon,
    required String languageCode,
    required AuthProvider authProvider,
    required bool canPop,
  }) {
    return SliverAppBar(
      key: const ValueKey('profile-hero-appbar'),
      pinned: true,
      snap: false,
      floating: false,
      expandedHeight: 180,
      collapsedHeight: kToolbarHeight,
      backgroundColor: const Color(0xFF1B5E20),
      surfaceTintColor: Colors.transparent,
      forceElevated: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black38,
      leading: canPop
          ? const BackButton(color: Colors.white)
          : IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              tooltip: 'Menu',
              onPressed: _openDrawer,
            ),
      title: Text(
        'profile'.tr(languageCode),
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.4,
        ),
      ),
      actions: [
        // Refresh profile button
        if (authProvider.token != null && authProvider.token!.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            tooltip: 'Refresh Profile',
            onPressed: () async {
              final token = authProvider.token!;
              await authProvider.fetchCurrentUser(token);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          languageCode == 'bn' ? 'প্রোফাইল আপডেট হয়েছে' : 'Profile refreshed successfully',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 1),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _headerBg(
          user: user,
          displayName: displayName,
          displayDistrict: displayDistrict,
          displayBalance: displayBalance,
          roleName: roleName,
          roleIcon: roleIcon,
          languageCode: languageCode,
        ),
      ),
    );
  }

  Widget _headerBg({
    required AppUser? user,
    required String displayName,
    required String displayDistrict,
    required String displayBalance,
    required String roleName,
    required IconData roleIcon,
    required String languageCode,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar (matching _avatar in FarmerDashboard)
            _avatar(user, displayName),
            const SizedBox(width: 14),
            // User Name + Role + District
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(roleIcon, size: 12, color: Colors.white.withValues(alpha: 0.85)),
                      const SizedBox(width: 4),
                      Text(
                        roleName,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (user?.isVerified == true) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_rounded, color: Colors.white, size: 9),
                              const SizedBox(width: 2),
                              Text(
                                languageCode == 'bn' ? 'ভেরিফাইড' : 'Verified',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        displayDistrict,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Trailing Pill (matching _earningsPill in FarmerDashboard)
            _profilePill(displayBalance, languageCode),
          ],
        ),
      ),
    );
  }

  Widget _avatar(AppUser? user, String displayName) {
    final hasAvatar = user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
        ),
        color: Colors.white.withValues(alpha: 0.15),
      ),
      child: ClipOval(
        child: hasAvatar
            ? Image.network(
                user.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAvatarFallback(displayName),
              )
            : _buildAvatarFallback(displayName),
      ),
    );
  }

  Widget _buildAvatarFallback(String displayName) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    return Container(
      color: Colors.white.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _profilePill(String displayBalance, String languageCode) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_rounded, color: Colors.white70, size: 10),
                const SizedBox(width: 3),
                Text(
                  'edit_profile'.tr(languageCode),
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              displayBalance,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── KPI Metrics Summary Row ─────────────────────────────────────────────────

  Widget _buildKpiSummaryRow(AppUser? user, String displayBalance, String languageCode) {
    final ratingValue = (user?.rating ?? 0.0);
    final ratingStr = languageCode == 'bn'
        ? '${BanglaTextRenderer.toBanglaNumber(ratingValue.toStringAsFixed(1))} / ৫.০'
        : '${ratingValue.toStringAsFixed(1)} / 5.0';

    final isVerified = user?.isVerified ?? false;

    return Row(
      children: [
        // 1. Wallet Balance Card
        Expanded(
          child: _buildKpiCard(
            title: 'wallet_balance'.tr(languageCode),
            value: displayBalance,
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF2E7D32),
            iconBg: const Color(0xFFE8F5E9),
          ),
        ),
        const SizedBox(width: 10),

        // 2. User Rating Card
        Expanded(
          child: _buildKpiCard(
            title: 'user_rating'.tr(languageCode),
            value: ratingStr,
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFFEF3C7),
          ),
        ),
        const SizedBox(width: 10),

        // 3. Status Card
        Expanded(
          child: _buildKpiCard(
            title: 'account_status'.tr(languageCode),
            value: isVerified ? 'verified'.tr(languageCode) : 'unverified'.tr(languageCode),
            icon: isVerified ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
            iconColor: isVerified ? const Color(0xFF10B981) : const Color(0xFF6B7280),
            iconBg: isVerified ? const Color(0xFFD1FAE5) : const Color(0xFFF3F4F6),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Personal & Account Details Card ──────────────────────────────────────────

  Widget _buildAccountDetailsCard({
    required AppUser? user,
    required String displayName,
    required String displayPhone,
    required String displayId,
    required String displayDistrict,
    required String roleName,
    required IconData roleIcon,
    required String languageCode,
  }) {
    final email = user?.email?.isNotEmpty == true
        ? user!.email!
        : (languageCode == 'bn' ? 'সংযুক্ত করা হয়নি' : 'Not linked');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  languageCode == 'bn' ? 'অ্যাকাউন্ট বিবরণ' : 'Account Details',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // 1. Phone (Login ID) with copy button
          _buildDetailTile(
            icon: Icons.phone_android_rounded,
            title: 'phone_number'.tr(languageCode),
            value: displayPhone,
            action: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 17, color: AppColors.primary),
              tooltip: 'Copy Phone',
              onPressed: () => _copyToClipboard(user?.phone ?? '', 'phone_number'.tr(languageCode)),
            ),
          ),
          _buildTileDivider(),

          // 2. Email Address
          _buildDetailTile(
            icon: Icons.alternate_email_rounded,
            title: 'Email Address',
            value: email,
          ),
          _buildTileDivider(),

          // 3. User ID with copy button
          _buildDetailTile(
            icon: Icons.fingerprint_rounded,
            title: 'user_id'.tr(languageCode),
            value: displayId.length > 18 ? '${displayId.substring(0, 8)}...${displayId.substring(displayId.length - 6)}' : displayId,
            action: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 17, color: AppColors.primary),
              tooltip: 'Copy User ID',
              onPressed: () => _copyToClipboard(displayId, 'user_id'.tr(languageCode)),
            ),
          ),
          _buildTileDivider(),

          // 4. District / Location
          _buildDetailTile(
            icon: Icons.location_city_rounded,
            title: languageCode == 'bn' ? 'জেলা / অঞ্চল' : 'District / Region',
            value: displayDistrict,
          ),
          _buildTileDivider(),

          // 5. Account Role
          _buildDetailTile(
            icon: roleIcon,
            title: 'account_role'.tr(languageCode),
            value: roleName,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String title,
    required String value,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _buildTileDivider() {
    return const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F3F5));
  }

  // ─── Settings & Preferences Card ─────────────────────────────────────────────

  Widget _buildSettingsCard(String languageCode) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.settings_outlined, color: Color(0xFF0284C7), size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'settings'.tr(languageCode),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Language Selector Tile
          ListTile(
            dense: true,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.language_rounded, color: AppColors.textSecondary, size: 18),
            ),
            title: Text(
              'language'.tr(languageCode),
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            subtitle: Text(
              languageCode == 'bn' ? 'বাংলা (Bangla)' : 'English',
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: const LanguageToggleButton(compact: true),
          ),
          _buildTileDivider(),

          // Help & Support
          ListTile(
            dense: true,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.help_outline_rounded, color: AppColors.textSecondary, size: 18),
            ),
            title: Text(
              'help_support'.tr(languageCode),
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            subtitle: Text(
              languageCode == 'bn' ? 'সহায়তা ও সেবা কেন্দ্র' : 'FAQs, hotline & assistance',
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    languageCode == 'bn' ? 'সহায়তা হটলাইন: ১৬১২৩' : 'Support Hotline: 16123',
                    style: GoogleFonts.outfit(),
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Action Buttons (Edit Profile + Logout) ───────────────────────────────────

  Widget _buildActionButtons(BuildContext context, String languageCode) {
    return Column(
      children: [
        // Primary: Edit Profile
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(
              'edit_profile'.tr(languageCode),
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary: Logout with Confirmation
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, languageCode),
            icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
            label: Text(
              'logout'.tr(languageCode),
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red.shade300, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
