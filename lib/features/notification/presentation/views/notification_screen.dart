import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/api_path.dart';
import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/empty_state_widget.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../state/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    final provider = context.read<NotificationProvider>();
    final list = await provider.fetchNotifications();
    if (mounted) {
      try {
        context.read<AppStateProvider>().setNotifications(list);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;
    final isLoading = provider.isLoading;
    final isBangla = context.watch<AppStateProvider>().isBangla;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBangla ? 'বিজ্ঞপ্তি' : 'Notifications',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              provider.unreadCount > 0
                  ? (isBangla
                      ? '${provider.unreadCount}টি অপঠিত বিজ্ঞপ্তি'
                      : '${provider.unreadCount} unread notification(s)')
                  : (isBangla ? 'সব হালনাগাদ' : 'All caught up'),
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton.icon(
              onPressed: provider.isMarkingRead
                  ? null
                  : () async {
                      await provider.markAllAsRead();
                      if (context.mounted) {
                        try {
                          context
                              .read<AppStateProvider>()
                              .setNotifications(provider.notifications);
                        } catch (_) {}
                      }
                    },
              icon: provider.isMarkingRead
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.done_all_rounded, size: 16, color: Colors.white),
              label: Text(
                isBangla ? 'সব পঠিত' : 'Mark all read',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadNotifications,
          ),
        ],
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ─── Live cURL Endpoint Indicator Banner ──────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded, size: 16, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GET ${ApiPath.serverOrigin}${provider.currentCurlQueryString}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B5E20),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: _loadNotifications,
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.sync_rounded, size: 16, color: Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
          ),

          // ─── Read Status Tabs (Matching cURL isRead=true) ──────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildStatusTab(
                  label: isBangla ? 'পঠিত (cURL)' : 'Read (cURL)',
                  isSelected: provider.filterIsRead == true,
                  onTap: () => provider.setFilterIsRead(true),
                ),
                const SizedBox(width: 8),
                _buildStatusTab(
                  label: isBangla ? 'অপঠিত' : 'Unread',
                  isSelected: provider.filterIsRead == false,
                  onTap: () => provider.setFilterIsRead(false),
                ),
                const SizedBox(width: 8),
                _buildStatusTab(
                  label: isBangla ? 'সকল' : 'All Statuses',
                  isSelected: provider.filterIsRead == null,
                  onTap: () => provider.setFilterIsRead(null),
                ),
              ],
            ),
          ),

          // ─── Type Filter Chips (Matching cURL type=all) ────────────────────
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                _buildTypeChip('all', isBangla ? 'সব ধরণ' : 'All Types', provider),
                _buildTypeChip('order', isBangla ? 'অর্ডার' : 'Orders', provider),
                _buildTypeChip('bid', isBangla ? 'বিড ও দর' : 'Bids & Offers', provider),
                _buildTypeChip('demand', isBangla ? 'ডিমান্ড' : 'Demands', provider),
                _buildTypeChip('payment', isBangla ? 'পেমেন্ট' : 'Payments', provider),
                _buildTypeChip('group', isBangla ? 'বাইয়িং গ্রুপ' : 'Group Buys', provider),
                _buildTypeChip('alert', isBangla ? 'সতর্কতা' : 'Alerts', provider),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ─── Notifications List ───────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF2E7D32),
              onRefresh: _loadNotifications,
              child: isLoading && notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF2E7D32)),
                          SizedBox(height: 12),
                          Text('Fetching notifications from server...'),
                        ],
                      ),
                    )
                  : notifications.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                EmptyStateWidget(
                                  icon: Icons.notifications_off_outlined,
                                  title: isBangla
                                      ? 'কোন বিজ্ঞপ্তি পাওয়া যায়নি'
                                      : 'No Notifications Found',
                                  subtitle: isBangla
                                      ? 'বর্তমান ফিল্টারের অধীনে কোন বিজ্ঞপ্তি নেই। নতুন অর্ডার, বিড এবং ডিমান্ডের আপডেট এখানে প্রদর্শিত হবে।'
                                      : 'No notifications found matching "${provider.currentCurlQueryString}". Real-time updates regarding orders, bids, demand offers, and price alerts will appear here.',
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    provider.resetFilters();
                                  },
                                  icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                                  label: Text(isBangla ? 'ফিল্টার রিসেট করুন' : 'Reset Filters (cURL Default)'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2E7D32),
                                    side: const BorderSide(color: Color(0xFF2E7D32)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: notifications.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            return _buildNotificationCard(notification, provider, isBangla);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String typeKey, String label, NotificationProvider provider) {
    final isSelected = provider.filterType == typeKey;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          provider.setFilterType(typeKey);
        },
        selectedColor: const Color(0xFF2E7D32).withValues(alpha: 0.15),
        checkmarkColor: const Color(0xFF2E7D32),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
        ),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
    );
  }

  Widget _buildNotificationCard(
    AppNotification notification,
    NotificationProvider provider,
    bool isBangla,
  ) {
    final color = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);
    final isRead = notification.isRead;

    return InkWell(
      onTap: () {
        if (!isRead) {
          provider.markAsRead(notification.id);
        }
        _showNotificationDetailSheet(notification);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead ? Colors.grey.shade200 : const Color(0xFF2E7D32).withValues(alpha: 0.4),
            width: isRead ? 1 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isRead ? 0.02 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.outfit(
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 14,
                            color: isRead ? Colors.black87 : const Color(0xFF1B5E20),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: isRead ? Colors.grey.shade700 : Colors.black87,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Bottom Tags Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          notification.type.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: color,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!isRead)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 6, color: Color(0xFF2E7D32)),
                              SizedBox(width: 4),
                              Text(
                                'UNREAD',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.done_rounded, size: 13, color: Colors.grey.shade400),
                            const SizedBox(width: 2),
                            Text(
                              'READ',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDetailSheet(AppNotification notification) {
    final color = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(notification.createdAt),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  notification.message,
                  style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.shopping_bag_outlined;
      case NotificationType.payment:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.bid:
        return Icons.gavel_rounded;
      case NotificationType.demand:
        return Icons.campaign_rounded;
      case NotificationType.group:
        return Icons.group_work_rounded;
      case NotificationType.promo:
        return Icons.local_offer_outlined;
      case NotificationType.system:
        return Icons.settings_suggest_rounded;
      case NotificationType.alert:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return const Color(0xFF1565C0);
      case NotificationType.payment:
        return const Color(0xFF2E7D32);
      case NotificationType.bid:
        return const Color(0xFF00897B);
      case NotificationType.demand:
        return const Color(0xFFE65100);
      case NotificationType.group:
        return const Color(0xFF6A1B9A);
      case NotificationType.promo:
        return const Color(0xFF8E24AA);
      case NotificationType.system:
        return Colors.blueGrey;
      case NotificationType.alert:
        return Colors.amber.shade900;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return DateFormat('dd MMM').format(date);
  }
}
