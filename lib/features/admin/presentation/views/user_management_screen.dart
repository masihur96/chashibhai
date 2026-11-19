import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bangla_text_renderer.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/admin_user_model.dart';
import '../providers/admin_user_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<AdminUserProvider>().fetchUsers(token: auth.token);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              '$label copied to clipboard',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showVerifyDialog(BuildContext context, AdminUserModel user, bool isBangla) {
    final targetState = !user.isVerified;
    final reasonController = TextEditingController(
      text: targetState
          ? (isBangla ? 'জাতীয় পরিচয়পত্র যাচাই ও নিশ্চিত করা হয়েছে।' : 'Valid NID provided and matched.')
          : (isBangla ? 'প্রশাসনিক পর্যালোচনা দ্বারা যাচাইকরণ প্রত্যাহার করা হয়েছে।' : 'Verification revoked upon administrative review.'),
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: targetState ? const Color(0xFFE8F5E9) : Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                targetState ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
                color: targetState ? const Color(0xFF2E7D32) : Colors.amber.shade800,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                targetState
                    ? (isBangla ? 'কেওয়াইসি যাচাই ও অনুমোদন' : 'Verify User Identity (KYC)')
                    : (isBangla ? 'যাচাইকরণ প্রত্যাহার' : 'Revoke Verification'),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                targetState
                    ? (isBangla
                        ? 'আপনি কি "${user.name}" এর জন্য কেওয়াইসি স্ট্যাটাস অনুমোদন করতে চান?'
                        : 'Confirm KYC verification for "${user.name}" (${user.role.toUpperCase()})?')
                    : (isBangla
                        ? 'আপনি কি "${user.name}" এর ভেরিফাইড স্ট্যাটাস প্রত্যাহার করতে চান?'
                        : 'Revoke verified status for "${user.name}"?'),
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
              ),
              const SizedBox(height: 18),
              Text(
                isBangla ? 'যাচাইকরণের কারণ / অডিট নোট:' : 'Verification Reason / Audit Note:',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: isBangla ? 'কারণ লিখুন...' : 'Enter reason...',
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(isBangla ? 'বাতিল' : 'Cancel', style: GoogleFonts.outfit(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: targetState ? const Color(0xFF2E7D32) : Colors.amber.shade800,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              Navigator.pop(dialogCtx);
              final token = context.read<AuthProvider>().token;
              await context.read<AdminUserProvider>().verifyUser(
                userId: user.id,
                isVerified: targetState,
                reason: reason,
                token: token,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            targetState
                                ? (isBangla ? '${user.name} এর কেওয়াইসি অনুমোদিত হয়েছে ($reason)' : '${user.name} verified: "$reason"')
                                : (isBangla ? '${user.name} এর যাচাইকরণ প্রত্যাহার করা হয়েছে' : '${user.name} unverified: "$reason"'),
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                          ),
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
              targetState ? (isBangla ? 'অনুমোদন নিশ্চিত করুন' : 'Confirm Verify') : (isBangla ? 'প্রত্যাহার করুন' : 'Revoke Status'),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showBanDialog(BuildContext context, AdminUserModel user, bool isBangla) {
    final targetState = !user.isBanned;
    final reasonController = TextEditingController(
      text: targetState
          ? (isBangla ? 'সন্দেহজনক কার্যকলাপ ও শর্তাবলী লঙ্ঘন।' : 'Suspicious activities / terms violation.')
          : (isBangla ? 'প্রশাসক কর্তৃক অ্যাকাউন্ট পুনঃসক্রিয় করা হয়েছে।' : 'Account reinstated by administrator.'),
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: targetState ? Colors.red.shade50 : const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                targetState ? Icons.block_rounded : Icons.lock_open_rounded,
                color: targetState ? Colors.red.shade700 : const Color(0xFF2E7D32),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                targetState
                    ? (isBangla ? 'অ্যাকাউন্ট স্থগিত / ব্যান' : 'Suspend / Ban User Account')
                    : (isBangla ? 'স্থগিতাদেশ প্রত্যাহার' : 'Reactivate User Account'),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (targetState)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isBangla
                              ? 'স্থগিত করা হলে ব্যবহারকারী অ্যাপে লগইন, নিলাম বা পণ্য ক্রয় করতে পারবেন না।'
                              : 'Banning this user will immediately block access to bidding, selling, and orders.',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                targetState
                    ? (isBangla
                        ? 'আপনি কি নিশ্চিত যে "${user.name}" এর অ্যাকাউন্ট স্থগিত করতে চান?'
                        : 'Are you sure you want to suspend access for "${user.name}"?')
                    : (isBangla
                        ? 'আপনি কি "${user.name}" এর অ্যাকাউন্ট পুনরায় সক্রিয় করতে চান?'
                        : 'Reactivate platform access for "${user.name}"?'),
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
              ),
              const SizedBox(height: 18),
              Text(
                isBangla ? 'স্থগিতের কারণ / অডিট নোট:' : 'Suspension Reason / Audit Note:',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: isBangla ? 'কারণ লিখুন...' : 'Enter reason...',
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: targetState ? Colors.red.shade700 : const Color(0xFF2E7D32), width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(isBangla ? 'বাতিল' : 'Cancel', style: GoogleFonts.outfit(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: targetState ? Colors.red.shade700 : const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              Navigator.pop(dialogCtx);
              final token = context.read<AuthProvider>().token;
              await context.read<AdminUserProvider>().banUser(
                userId: user.id,
                isBanned: targetState,
                reason: reason,
                token: token,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(targetState ? Icons.block_rounded : Icons.check_circle_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            targetState
                                ? (isBangla ? '${user.name} এর অ্যাকাউন্ট স্থগিত করা হয়েছে ($reason)' : '${user.name} suspended: "$reason"')
                                : (isBangla ? '${user.name} এর স্থগিতাদেশ প্রত্যাহার করা হয়েছে ($reason)' : '${user.name} unsuspended: "$reason"'),
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: targetState ? Colors.red.shade700 : const Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              targetState ? (isBangla ? 'স্থগিত নিশ্চিত করুন' : 'Confirm Suspension') : (isBangla ? 'সক্রিয় করুন' : 'Confirm Reactivation'),
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetailsDialog(BuildContext context, AdminUserModel user, bool isBangla) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        title: Row(
          children: [
            _buildAvatar(user, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${user.id}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(dialogCtx),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                _buildModalDetailRow(Icons.phone_android_rounded, isBangla ? 'ফোন নম্বর' : 'Phone', user.phone, onCopy: () => _copyToClipboard(user.phone, 'Phone')),
                if (user.email != null && user.email!.isNotEmpty)
                  _buildModalDetailRow(Icons.email_outlined, isBangla ? 'ইমেইল' : 'Email', user.email!, onCopy: () => _copyToClipboard(user.email!, 'Email')),
                if (user.district != null && user.district!.isNotEmpty)
                  _buildModalDetailRow(Icons.location_on_outlined, isBangla ? 'জেলা' : 'District', user.district!),
                if (user.nid != null && user.nid!.isNotEmpty)
                  _buildModalDetailRow(Icons.badge_outlined, isBangla ? 'এনআইডি নম্বর' : 'National ID', user.nid!),
                _buildModalDetailRow(
                  Icons.account_balance_wallet_outlined,
                  isBangla ? 'ব্যালেন্স' : 'Wallet Balance',
                  isBangla ? BanglaTextRenderer.formatTaka(user.walletBalance) : '৳${user.walletBalance.toStringAsFixed(2)}',
                ),
                _buildModalDetailRow(
                  Icons.star_rounded,
                  isBangla ? 'রেটিং' : 'Rating',
                  '${user.rating.toStringAsFixed(1)} / 5.0',
                ),
                _buildModalDetailRow(
                  Icons.calendar_today_rounded,
                  isBangla ? 'যোগদানের তারিখ' : 'Member Since',
                  user.createdAt != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(user.createdAt!)
                      : 'N/A',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildRoleBadge(user.role, isBangla),
                    const SizedBox(width: 8),
                    _buildVerificationBadge(user.isVerified, isBangla),
                    const SizedBox(width: 8),
                    _buildBanBadge(user.isBanned, isBangla),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _showVerifyDialog(context, user, isBangla);
            },
            icon: Icon(user.isVerified ? Icons.pending_actions_rounded : Icons.check_circle_outline, size: 18),
            label: Text(
              user.isVerified
                  ? (isBangla ? 'যাচাইকরণ প্রত্যাহার' : 'Revoke Verification')
                  : (isBangla ? 'কেওয়াইসি অনুমোদন করুন' : 'Approve KYC'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isVerified ? Colors.amber.shade800 : const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _showBanDialog(context, user, isBangla);
            },
            icon: Icon(user.isBanned ? Icons.lock_open_rounded : Icons.block_rounded, size: 18),
            label: Text(
              user.isBanned
                  ? (isBangla ? 'স্থগিতাদেশ প্রত্যাহার' : 'Unban Account')
                  : (isBangla ? 'অ্যাকাউন্ট স্থগিত করুন' : 'Suspend Account'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: user.isBanned ? const Color(0xFF2E7D32) : Colors.red.shade700,
              side: BorderSide(color: user.isBanned ? const Color(0xFF2E7D32) : Colors.red.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalDetailRow(IconData icon, String label, String value, {VoidCallback? onCopy}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: Icon(Icons.copy_rounded, size: 16, color: Colors.grey.shade600),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.watch<AppStateProvider>().appLocale;
    final isBangla = languageCode == 'bn';
    final userProvider = context.watch<AdminUserProvider>();
    final authProvider = context.watch<AuthProvider>();
    final users = userProvider.users;
    final isLoading = userProvider.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        color: const Color(0xFF2E7D32),
        onRefresh: () => userProvider.fetchUsers(token: authProvider.token, isRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Screen Header ──
                  _buildHeader(context, userProvider, isBangla),
                  const SizedBox(height: 20),

                  // ── Search & Filter Controls ──
                  _buildFilterBar(context, userProvider, isBangla),
                  const SizedBox(height: 16),

                  // ── Active Filters Bar ──
                  if (userProvider.hasActiveFilters) ...[
                    _buildActiveFiltersPills(userProvider, isBangla),
                    const SizedBox(height: 16),
                  ],

                  // ── Results Summary Bar ──
                  _buildResultsCounter(userProvider, isBangla),
                  const SizedBox(height: 16),

                  // ── User Cards List ──
                  if (isLoading)
                    _buildLoadingSkeleton()
                  else if (users.isEmpty)
                    _buildEmptyState(userProvider, isBangla)
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _buildUserCard(context, user, userProvider, isBangla);
                      },
                    ),

                  const SizedBox(height: 24),

                  // ── Pagination Footer ──
                  if (userProvider.totalPages > 1)
                    _buildPaginationControls(userProvider, isBangla),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AdminUserProvider provider, bool isBangla) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBangla ? 'ব্যবহারকারী ডিরেক্টরি ও ব্যবস্থাপনা' : 'User Directory & Management',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isBangla
                    ? 'কৃষক, ক্রেতা ও অ্যাডমিন অ্যাকাউন্ট ফিল্টারিং, যাচাইকরণ ও নিয়ন্ত্রণ'
                    : 'Search, filter, audit, verify KYC, and manage platform participants',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        // Quick preset matching curl
        OutlinedButton.icon(
          onPressed: () {
            _searchController.text = 'Rafiq';
            provider.applyFarmerVerifiedCurlFilter();
          },
          icon: const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFF2E7D32)),
          label: Text(
            isBangla ? 'কৃষক ফিল্টার (Curl)' : 'Preset: Rafiq (Farmer)',
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2E7D32)),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF81C784)),
            backgroundColor: const Color(0xFFE8F5E9),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // ─── Filter Bar ─────────────────────────────────────────────────────────────

  Widget _buildFilterBar(BuildContext context, AdminUserProvider provider, bool isBangla) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: isBangla ? 'নাম, ফোন বা জেলা দিয়ে অনুসন্ধান করুন...' : 'Search by name, phone, email, or district...',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2E7D32), size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (val) => provider.setSearch(val),
                  onChanged: (val) {
                    if (val.isEmpty) provider.setSearch('');
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => provider.setSearch(_searchController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isBangla ? 'খুঁজুন' : 'Search',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Role Filter
                _buildFilterDropdown<String?>(
                  label: isBangla ? 'ভূমিকা' : 'Role',
                  value: provider.role,
                  items: [
                    DropdownMenuItem(value: null, child: Text(isBangla ? 'সকল ভূমিকা' : 'All Roles')),
                    DropdownMenuItem(value: 'farmer', child: Text(isBangla ? 'কৃষক (Farmer)' : 'Farmers Only')),
                    DropdownMenuItem(value: 'buyer', child: Text(isBangla ? 'ক্রেতা (Buyer)' : 'Buyers Only')),
                    DropdownMenuItem(value: 'admin', child: Text(isBangla ? 'অ্যাডমিন (Admin)' : 'Admins Only')),
                  ],
                  onChanged: (v) => provider.setRole(v),
                ),
                const SizedBox(width: 10),

                // Verification Filter
                _buildFilterDropdown<bool?>(
                  label: isBangla ? 'কেওয়াইসি' : 'Verification',
                  value: provider.isVerified,
                  items: [
                    DropdownMenuItem(value: null, child: Text(isBangla ? 'সকল কেওয়াইসি' : 'All Verification')),
                    DropdownMenuItem(value: true, child: Text(isBangla ? 'যাচাইকৃত (Verified)' : 'Verified Only')),
                    DropdownMenuItem(value: false, child: Text(isBangla ? 'অপেক্ষমাণ (Pending)' : 'Pending KYC')),
                  ],
                  onChanged: (v) => provider.setVerified(v),
                ),
                const SizedBox(width: 10),

                // Status Filter
                _buildFilterDropdown<bool?>(
                  label: isBangla ? 'স্ট্যাটাস' : 'Status',
                  value: provider.isBanned,
                  items: [
                    DropdownMenuItem(value: null, child: Text(isBangla ? 'সকল স্ট্যাটাস' : 'All Status')),
                    DropdownMenuItem(value: false, child: Text(isBangla ? 'সক্রিয় (Active)' : 'Active Only')),
                    DropdownMenuItem(value: true, child: Text(isBangla ? 'স্থগিত (Banned)' : 'Suspended Only')),
                  ],
                  onChanged: (v) => provider.setBanned(v),
                ),
                const SizedBox(width: 10),

                // Sort Dropdown
                _buildFilterDropdown<String>(
                  label: isBangla ? 'সাজান' : 'Sort',
                  value: '${provider.sortBy}_${provider.sortOrder}',
                  items: [
                    DropdownMenuItem(value: 'created_at_desc', child: Text(isBangla ? 'নতুনতম প্রথমে' : 'Newest First')),
                    DropdownMenuItem(value: 'created_at_asc', child: Text(isBangla ? 'পুরাতনতম প্রথমে' : 'Oldest First')),
                    DropdownMenuItem(value: 'name_asc', child: Text(isBangla ? 'নাম (A to Z)' : 'Name (A to Z)')),
                    DropdownMenuItem(value: 'rating_desc', child: Text(isBangla ? 'সর্বোচ্চ রেটিং' : 'Highest Rating')),
                    DropdownMenuItem(value: 'walletBalance_desc', child: Text(isBangla ? 'সর্বোচ্চ ব্যালেন্স' : 'Highest Balance')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      final parts = v.split('_');
                      final order = parts.last;
                      final field = v.substring(0, v.length - order.length - 1);
                      provider.setSort(field, order);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2E7D32)),
          style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w500),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ─── Active Filter Pills ────────────────────────────────────────────────────

  Widget _buildActiveFiltersPills(AdminUserProvider provider, bool isBangla) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          isBangla ? 'প্রয়োগকৃত ফিল্টার:' : 'Active Filters:',
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
        ),
        if (provider.search.isNotEmpty)
          _buildPill('Search: "${provider.search}"', () {
            _searchController.clear();
            provider.setSearch('');
          }),
        if (provider.role != null)
          _buildPill('Role: ${provider.role!.toUpperCase()}', () => provider.setRole(null)),
        if (provider.isVerified != null)
          _buildPill(provider.isVerified! ? 'Verified Only' : 'Pending KYC', () => provider.setVerified(null)),
        if (provider.isBanned != null)
          _buildPill(provider.isBanned! ? 'Suspended' : 'Active Only', () => provider.setBanned(null)),
        TextButton(
          onPressed: () {
            _searchController.clear();
            provider.resetFilters();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          ),
          child: Text(
            isBangla ? 'সমস্ত ফিল্টার সাফ করুন' : 'Clear All Filters',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPill(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF81C784)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF2E7D32)),
          ),
        ],
      ),
    );
  }

  // ─── Results Counter ────────────────────────────────────────────────────────

  Widget _buildResultsCounter(AdminUserProvider provider, bool isBangla) {
    final count = provider.total;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isBangla
              ? '${BanglaTextRenderer.toBanglaNumber(count)} জন ব্যবহারকারী পাওয়া গেছে'
              : 'Found $count users',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          isBangla
              ? 'পৃষ্ঠা: ${BanglaTextRenderer.toBanglaNumber(provider.page)} / ${BanglaTextRenderer.toBanglaNumber(provider.totalPages)}'
              : 'Page ${provider.page} of ${provider.totalPages}',
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ─── User Card ──────────────────────────────────────────────────────────────

  Widget _buildUserCard(
    BuildContext context,
    AdminUserModel user,
    AdminUserProvider provider,
    bool isBangla,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showUserDetailsDialog(context, user, isBangla),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 680;

              final avatarAndInfo = Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(user, size: 54),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              user.name,
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            _buildRoleBadge(user.role, isBangla),
                            _buildVerificationBadge(user.isVerified, isBangla),
                            if (user.isBanned) _buildBanBadge(user.isBanned, isBangla),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          children: [
                            _buildDetailChip(Icons.phone_outlined, user.phone, onCopy: () => _copyToClipboard(user.phone, 'Phone')),
                            if (user.district != null && user.district!.isNotEmpty)
                              _buildDetailChip(Icons.location_on_outlined, user.district!),
                            _buildDetailChip(Icons.star_rounded, '${user.rating.toStringAsFixed(1)} ★', color: const Color(0xFFD97706)),
                            _buildDetailChip(
                              Icons.account_balance_wallet_outlined,
                              isBangla ? BanglaTextRenderer.formatTaka(user.walletBalance) : '৳${user.walletBalance.toStringAsFixed(2)}',
                              color: const Color(0xFF2E7D32),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actionButtons = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!user.isVerified)
                    OutlinedButton.icon(
                      onPressed: () => _showVerifyDialog(context, user, isBangla),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(
                        isBangla ? 'অনুমোদন' : 'Verify KYC',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onSelected: (val) {
                      switch (val) {
                        case 'view':
                          _showUserDetailsDialog(context, user, isBangla);
                          break;
                        case 'verify':
                          _showVerifyDialog(context, user, isBangla);
                          break;
                        case 'toggle_ban':
                          _showBanDialog(context, user, isBangla);
                          break;
                        case 'copy_id':
                          _copyToClipboard(user.id, 'User ID');
                          break;
                        case 'copy_phone':
                          _copyToClipboard(user.phone, 'Phone');
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            const Icon(Icons.visibility_outlined, size: 18),
                            const SizedBox(width: 10),
                            Text(isBangla ? 'সম্পূর্ণ প্রোফাইল দেখুন' : 'View Full Details'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'verify',
                        child: Row(
                          children: [
                            Icon(
                              user.isVerified ? Icons.pending_actions_rounded : Icons.verified_rounded,
                              size: 18,
                              color: const Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              user.isVerified
                                  ? (isBangla ? 'যাচাইকরণ প্রত্যাহার' : 'Revoke Verification')
                                  : (isBangla ? 'কেওয়াইসি অনুমোদন করুন' : 'Approve KYC'),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_ban',
                        child: Row(
                          children: [
                            Icon(
                              user.isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
                              size: 18,
                              color: user.isBanned ? const Color(0xFF2E7D32) : Colors.red,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              user.isBanned
                                  ? (isBangla ? 'স্থগিতাদেশ প্রত্যাহার' : 'Unsuspend Account')
                                  : (isBangla ? 'অ্যাকাউন্ট স্থগিত করুন' : 'Suspend User'),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'copy_id',
                        child: Row(
                          children: [
                            const Icon(Icons.tag_rounded, size: 18),
                            const SizedBox(width: 10),
                            Text(isBangla ? 'ইউজার আইডি কপি করুন' : 'Copy User ID'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'copy_phone',
                        child: Row(
                          children: [
                            const Icon(Icons.copy_rounded, size: 18),
                            const SizedBox(width: 10),
                            Text(isBangla ? 'ফোন নম্বর কপি করুন' : 'Copy Phone Number'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: avatarAndInfo),
                    const SizedBox(width: 16),
                    actionButtons,
                  ],
                );
              } else {
                return Column(
                  children: [
                    avatarAndInfo,
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [actionButtons],
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(AdminUserModel user, {double size = 50}) {
    Color bg = const Color(0xFFDCFCE7);
    Color fg = const Color(0xFF16A34A);

    if (user.role == 'buyer') {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0284C7);
    } else if (user.role == 'admin') {
      bg = const Color(0xFFF3E8FF);
      fg = const Color(0xFF9333EA);
    }

    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            border: Border.all(color: fg.withOpacity(0.3), width: 1.5),
          ),
          child: ClipOval(
            child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                ? Image.network(
                    user.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: size * 0.45, color: fg),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: size * 0.45, color: fg),
                    ),
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              color: user.isBanned ? Colors.red : const Color(0xFF16A34A),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role, bool isBangla) {
    Color bg = const Color(0xFFDCFCE7);
    Color fg = const Color(0xFF16A34A);
    String label = isBangla ? 'কৃষক' : 'FARMER';

    if (role.toLowerCase() == 'buyer') {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0284C7);
      label = isBangla ? 'ক্রেতা' : 'BUYER';
    } else if (role.toLowerCase() == 'admin') {
      bg = const Color(0xFFF3E8FF);
      fg = const Color(0xFF9333EA);
      label = isBangla ? 'অ্যাডমিন' : 'ADMIN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildVerificationBadge(bool isVerified, bool isBangla) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isVerified ? const Color(0xFFE8F5E9) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 12,
            color: isVerified ? const Color(0xFF2E7D32) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 4),
          Text(
            isVerified
                ? (isBangla ? 'ভেরিফাইড' : 'VERIFIED')
                : (isBangla ? 'অপেক্ষমাণ' : 'PENDING KYC'),
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isVerified ? const Color(0xFF2E7D32) : const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanBadge(bool isBanned, bool isBangla) {
    if (!isBanned) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isBangla ? 'স্থগিত' : 'BANNED',
        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFE11D48)),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, {Color? color, VoidCallback? onCopy}) {
    final effectiveColor = color ?? Colors.grey.shade600;
    return InkWell(
      onTap: onCopy,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.outfit(fontSize: 12, color: effectiveColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ─── Pagination ─────────────────────────────────────────────────────────────

  Widget _buildPaginationControls(AdminUserProvider provider, bool isBangla) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: provider.page > 1 ? () => provider.setPage(provider.page - 1) : null,
        ),
        const SizedBox(width: 8),
        for (int p = 1; p <= provider.totalPages; p++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => provider.setPage(p),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: provider.page == p ? const Color(0xFF2E7D32) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: provider.page == p ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  isBangla ? BanglaTextRenderer.toBanglaNumber(p) : '$p',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: provider.page == p ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: provider.page < provider.totalPages ? () => provider.setPage(provider.page + 1) : null,
        ),
      ],
    );
  }

  // ─── Empty & Loading States ─────────────────────────────────────────────────

  Widget _buildEmptyState(AdminUserProvider provider, bool isBangla) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 54, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            isBangla ? 'কোনো ব্যবহারকারী পাওয়া যায়নি' : 'No users match your criteria',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            isBangla
                ? 'আপনার ফিল্টার বা অনুসন্ধান শব্দ পরিবর্তন করে আবার চেষ্টা করুন'
                : 'Try adjusting your search query, role filter, or verification status',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              provider.resetFilters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isBangla ? 'সকল ফিল্টার রিসেট করুন' : 'Reset All Filters',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 140, height: 16, color: Colors.grey.shade100),
                    const SizedBox(height: 8),
                    Container(width: 220, height: 12, color: Colors.grey.shade100),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
