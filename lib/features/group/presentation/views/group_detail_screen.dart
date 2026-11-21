import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../data/models/join_group_request_model.dart';
import '../state/group_provider.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        context.read<GroupProvider>().fetchGroupMessages(widget.groupId, page: 1, limit: 50);
      }
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupDetails();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupDetails() async {
    try {
      await Future.wait([
        context.read<GroupProvider>().fetchGroupDetails(widget.groupId),
        context.read<GroupProvider>().fetchGroupMessages(widget.groupId, page: 1, limit: 50),
      ]);
    } catch (e) {
      debugPrint('⚠️ [GROUP_DETAIL] Error fetching group details/messages: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(BuyingGroup group, AppUser? user) async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<GroupProvider>().sendGroupMessage(group.id, text);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showJoinDialog(BuildContext context, BuyingGroup group) {
    double qty = 150;
    final remaining = (group.targetQuantity - group.filledQuantity).clamp(0.0, double.infinity);
    final formKey = GlobalKey<FormState>();
    final qtyController = TextEditingController(text: '150');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final isJoining = context.watch<GroupProvider>().isJoiningGroup;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.group_add_rounded, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Join "${group.name}"',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF2E7D32), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${remaining.toInt()} KG remaining in pool at ৳${group.pricePerKg.toInt()}/KG',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Preset Chip: 150 KG from cURL
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        qtyController.text = '150';
                        qty = 150;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFF2E7D32)),
                          SizedBox(width: 4),
                          Text(
                            '⚡ Fill 150 KG (cURL Sample)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Your Quantity (KG)',
                      suffixText: 'KG',
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final parsed = double.tryParse(v);
                      if (parsed == null || parsed <= 0) return 'Invalid quantity';
                      if (remaining > 0 && parsed > remaining) return 'Max ${remaining.toInt()} KG available';
                      return null;
                    },
                    onChanged: (v) {
                      setDialogState(() {
                        qty = double.tryParse(v) ?? 0;
                      });
                    },
                  ),
                  if (qty > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Commitment:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(
                            '৳${(qty * group.pricePerKg).toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isJoining ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isJoining
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final request = JoinGroupRequestModel(quantity: qty);
                            await context.read<GroupProvider>().joinGroup(group.id, request);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Joined "${group.name}"! Committed ${qty.toInt()} KG via cURL API.'),
                                backgroundColor: const Color(0xFF2E7D32),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to join group: $e'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                child: isJoining
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Confirm Join (cURL POST)'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmLeaveGroup(BuildContext context, BuyingGroup group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text('Leave Buying Group', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to leave "${group.name}"? Your committed quantity will be released back to the pool via DELETE /api/v1/groups/${group.id}/leave.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay in Group'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                await context.read<GroupProvider>().leaveGroup(group.id);
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('You have successfully left the group.'),
                    backgroundColor: Colors.black87,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to leave group: $e'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Confirm Leave (cURL DELETE)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final group = groupProvider.getGroupById(widget.groupId);
    final user = context.watch<AuthProvider>().currentUser;
    final isBangla = context.watch<AppStateProvider>().isBangla;

    if (_isInitialLoading && group == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Group Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF2E7D32)),
              SizedBox(height: 16),
              Text('Fetching group details via cURL API...'),
            ],
          ),
        ),
      );
    }

    if (group == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Group Not Found', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_off_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Group Not Found',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Could not locate group with ID:\n${widget.groupId}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadGroupDetails,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Fetching Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isCreator = group.createdBy == (user?.id ?? '') && (user?.id != null && user!.id.isNotEmpty);
    final isMember = isCreator || group.members.any((m) => m.userId == (user?.id ?? '') && (user?.id != null && user!.id.isNotEmpty));
    final progress = group.targetQuantity > 0 ? (group.filledQuantity / group.targetQuantity).clamp(0.0, 1.0) : 0.0;
    final daysLeft = group.expiryDate.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      resizeToAvoidBottomInset: true,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Refresh Group Details',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadGroupDetails,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _statusBadge(group.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              group.productName,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                group.category.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Progress
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${group.filledQuantity.toInt()} / ${group.targetQuantity.toInt()} KG (${(progress * 100).toInt()}%)',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Row(children: [
                              const Icon(Icons.timer_outlined, color: Colors.white70, size: 13),
                              const SizedBox(width: 4),
                              Text(daysLeft > 0 ? '$daysLeft days left' : 'Ends today', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.amber,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.people_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text('Members (${group.members.length})'),
                  ]),
                ),
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text('Chat (${group.messages.length})'),
                  ]),
                ),
              ],
            ),
          ),
        ],
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMembersTab(group, user, isBangla),
                  _buildChatTab(group, user),
                ],
              ),
            ),
            _buildBottomBar(group, user, isMember),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab(BuyingGroup group, AppUser? user, bool isBangla) {
    final remaining = (group.targetQuantity - group.filledQuantity).clamp(0.0, double.infinity);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('৳${group.pricePerKg.toInt()}', 'per KG'),
              _divider(),
              _statItem('${group.members.length}', 'Members'),
              _divider(),
              _statItem('${remaining.toInt()} KG', 'Remaining'),
              _divider(),
              _statItem(group.deliveryLocation.split(',').first, 'Location'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live Endpoint Indicator Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.terminal_rounded, size: 16, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GET /api/v1/groups/${group.id}',
                  style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF2E7D32)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Members List Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pool Members (${group.members.length})',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (group.members.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No members have joined yet. Be the first to join this pool!',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...group.members.map((member) => _memberTile(member, user?.id ?? '', group)),
      ],
    );
  }

  Widget _memberTile(GroupMember member, String currentUserId, BuyingGroup group) {
    final isMe = member.userId == currentUserId && currentUserId.isNotEmpty;
    final isCreator = member.userId == group.createdBy;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isMe ? const Color(0xFF2E7D32).withValues(alpha: 0.3) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCreator ? Colors.amber.shade100 : const Color(0xFF2E7D32).withValues(alpha: 0.1),
            child: Icon(
              isCreator ? Icons.star_rounded : Icons.person_rounded,
              color: isCreator ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isMe ? '${member.name} (You)' : member.name,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (isCreator) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Admin', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Committed: ${member.contributionQuantity.toInt()} KG  •  ৳${(member.contributionQuantity * group.pricePerKg).toInt()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (member.isPaid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Paid', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
            ),
        ],
      ),
    );
  }

  Widget _buildChatTab(BuyingGroup group, AppUser? user) {
    final groupProvider = context.watch<GroupProvider>();
    final messages = groupProvider.getMessagesForGroup(group.id);
    final isLoading = groupProvider.isLoadingMessages;

    return Column(
      children: [
        // Live Endpoint Indicator Banner for Chat Messages
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.forum_outlined, size: 15, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GET /groups/${group.id}/messages?page=1&limit=50',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B5E20),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () {
                  context.read<GroupProvider>().fetchGroupMessages(group.id, page: 1, limit: 50);
                },
                child: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF2E7D32)),
              ),
            ],
          ),
        ),

        Expanded(
          child: isLoading && messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF2E7D32)),
                      SizedBox(height: 12),
                      Text('Fetching group chat messages...'),
                    ],
                  ),
                )
              : messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Color(0xFF2E7D32)),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No Chat Messages Yet',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Coordinate with other pool members about delivery, timings, and payment.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = (user?.id != null && user!.id.isNotEmpty && msg.senderId == user.id) ||
                            msg.senderName.toLowerCase() == 'you';
                        return _chatBubble(
                          msg.senderName,
                          msg.message,
                          DateFormat('hh:mm a').format(msg.createdAt),
                          isMe,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _chatBubble(String sender, String message, String time, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(sender, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF2E7D32))),
            Text(message, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 13)),
            const SizedBox(height: 2),
            Text(time, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey.shade500, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuyingGroup group, AppUser? user, bool isMember) {
    final isChat = _tabController.index == 1;

    if (isChat) {
      final isSending = context.watch<GroupProvider>().isSendingMessage;

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick preset message chip
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _msgController.text =
                              'Hello everyone! When are we finalizing our bulk order?';
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flash_on_rounded, size: 12, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 4),
                            Text(
                              '⚡ "Hello everyone! When are we finalizing our bulk order?" (cURL Sample)',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: GoogleFonts.outfit(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Type a message to pool members...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: isSending ? null : (_) => _sendMessage(group, user),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isSending ? null : () => _sendMessage(group, user),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSending ? Colors.grey : const Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                    child: isSending
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (isMember) {
      final myMember = group.members.firstWhere(
        (m) => m.userId == (user?.id ?? ''),
        orElse: () => GroupMember(userId: '', name: '', contributionQuantity: 0),
      );

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'You are a pool member',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    myMember.contributionQuantity > 0
                        ? 'Committed: ${myMember.contributionQuantity.toInt()} KG (৳${(myMember.contributionQuantity * group.pricePerKg).toInt()})'
                        : 'Active commitment in this pool',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.exit_to_app_rounded, size: 16),
              label: const Text('Leave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: () => _confirmLeaveGroup(context, group),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: group.status == GroupBuyStatus.open
              ? () => _showJoinDialog(context, group)
              : null,
          icon: const Icon(Icons.group_add_rounded),
          label: Text(
            group.status == GroupBuyStatus.open ? 'Join Buying Group (cURL POST)' : 'Group Full / Closed',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(GroupBuyStatus status) {
    final (label, color) = switch (status) {
      GroupBuyStatus.open => ('OPEN', Colors.green),
      GroupBuyStatus.active => ('ACTIVE', Colors.blue),
      GroupBuyStatus.fulfilled => ('FULFILLED', Colors.purple),
      GroupBuyStatus.cancelled => ('CANCELLED', Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6),
      ),
    );
  }

  Widget _statItem(String value, String label) => Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      );

  Widget _divider() => Container(width: 1, height: 26, color: Colors.grey.shade200);
}
