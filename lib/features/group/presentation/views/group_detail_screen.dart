import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/models.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../buyer/presentation/state/product_provider.dart';
import '../state/group_provider.dart';
import '../../../buyer/presentation/state/demand_provider.dart';
import '../../../wallet/presentation/state/order_provider.dart';
import '../../../account/presentation/state/app_state_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _sendMessage(BuyingGroup group, AppUser? user) {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final newMsg = GroupMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      groupId: group.id,
      senderId: user?.id ?? 'u1',
      senderName: user?.name ?? 'You',
      message: text,
      createdAt: DateTime.now(),
    );

    final groups = context.read<GroupProvider>().groups;
    final updated = groups.map((g) {
      if (g.id == group.id) return g.copyWith(messages: [...g.messages, newMsg]);
      return g;
    }).toList();
    context.read<GroupProvider>().setGroups(updated);

    _msgController.clear();
    _scrollToBottom();
  }

  void _showJoinDialog(BuildContext context, BuyingGroup group) {
    double qty = 0;
    final remaining = group.targetQuantity - group.filledQuantity;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Join "${group.name}"', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF2E7D32), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${remaining.toInt()} KG slots remaining at ৳${group.pricePerKg}/KG',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Your Quantity (KG)',
                  suffixText: 'KG',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed <= 0) return 'Invalid quantity';
                  if (parsed > remaining) return 'Max ${remaining.toInt()} KG available';
                  return null;
                },
                onChanged: (v) => qty = double.tryParse(v) ?? 0,
              ),
              if (qty > 0) ...[
                const SizedBox(height: 12),
                Text(
                  'Total commitment: ৳${(qty * group.pricePerKg).toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final user = context.read<AuthProvider>().currentUser;
                final newMember = GroupMember(
                  userId: user?.id ?? 'u_new',
                  name: user?.name ?? 'You',
                  contributionQuantity: qty,
                  phone: user?.phone ?? '',
                );

                final groups = context.read<GroupProvider>().groups;
                final updated = groups.map((g) {
                  if (g.id == group.id) {
                    final welcome = GroupMessage(
                      id: 'msg_join_${DateTime.now().millisecondsSinceEpoch}',
                      groupId: g.id,
                      senderId: 'system',
                      senderName: 'System',
                      message: '${user?.name ?? "A new member"} joined the group and committed ${qty.toInt()} KG! 🎉',
                      createdAt: DateTime.now(),
                    );
                    return g.copyWith(
                      members: [...g.members, newMember],
                      filledQuantity: g.filledQuantity + qty,
                      messages: [...g.messages, welcome],
                    );
                  }
                  return g;
                }).toList();

                context.read<GroupProvider>().setGroups(updated);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Joined! You committed ${qty.toInt()} KG.'),
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                );
              }
            },
            child: const Text('Confirm Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = context.watch<GroupProvider>().getGroupById(widget.groupId);
    final user = context.watch<AuthProvider>().currentUser;

    if (group == null) {
      return const Scaffold(body: Center(child: Text('Group not found')));
    }

    final isMember = group.members.any((m) => m.userId == (user?.id ?? ''));
    final progress = group.filledQuantity / group.targetQuantity;
    final daysLeft = group.expiryDate.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      resizeToAvoidBottomInset: true,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
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
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _statusBadge(group.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group.productName,
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        // Progress
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${group.filledQuantity.toInt()}/${group.targetQuantity.toInt()} KG',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Row(children: [
                              const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text('$daysLeft days left', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: Colors.white.withOpacity(0.2),
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
                    const Icon(Icons.people, size: 16),
                    const SizedBox(width: 6),
                    Text('Members (${group.members.length})'),
                  ]),
                ),
                Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.chat_bubble_outline, size: 16),
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
                  _buildMembersTab(group, user),
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

  Widget _buildMembersTab(BuyingGroup group, AppUser? user) {
    final isCreator = group.createdBy == (user?.id ?? '');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('৳${group.pricePerKg.toInt()}', 'per KG'),
              _divider(),
              _statItem('${group.members.length}', 'Members'),
              _divider(),
              _statItem('${(group.targetQuantity - group.filledQuantity).toInt()} KG', 'Remaining'),
              _divider(),
              _statItem(group.deliveryLocation.split(',').first, 'Location'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Members', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold)),
            if (isCreator)
              TextButton.icon(
                onPressed: () => _showAddMemberDialog(context, group),
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF2E7D32)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ...group.members.map((m) => _memberTile(m, user?.id ?? '', group, isCreator)),
      ],
    );
  }

  Widget _memberTile(GroupMember member, String currentUserId, BuyingGroup group, bool isCreator) {
    final isYou = member.userId == currentUserId;
    final canRemove = isCreator && !isYou;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isYou ? Border.all(color: const Color(0xFF2E7D32).withOpacity(0.4)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF2E7D32).withOpacity(0.12),
            child: Text(
              member.name[0].toUpperCase(),
              style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(member.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                  if (isYou) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Text('You', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  if (member.userId == group.createdBy) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Text('Admin', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text('${member.contributionQuantity.toInt()} KG committed', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: member.isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  member.isPaid ? '✓ Paid' : 'Pending',
                  style: TextStyle(
                    color: member.isPaid ? Colors.green[700] : Colors.orange[700],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (canRemove) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _confirmRemoveMember(context, group, member),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_remove_outlined, size: 11, color: Colors.red),
                        SizedBox(width: 3),
                        Text('Remove', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(BuildContext context, BuyingGroup group, GroupMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Remove Member'),
        content: Text('Remove "${member.name}" from the group? Their committed quantity will be freed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final groups = context.read<GroupProvider>().groups;
              final updated = groups.map((g) {
                if (g.id == group.id) {
                  final newMembers = g.members.where((m) => m.userId != member.userId).toList();
                  final leaveMsg = GroupMessage(
                    id: 'msg_leave_${DateTime.now().millisecondsSinceEpoch}',
                    groupId: g.id,
                    senderId: 'system',
                    senderName: 'System',
                    message: '${member.name} was removed from the group.',
                    createdAt: DateTime.now(),
                  );
                  return g.copyWith(
                    members: newMembers,
                    filledQuantity: g.filledQuantity - member.contributionQuantity,
                    messages: [...g.messages, leaveMsg],
                  );
                }
                return g;
              }).toList();
              context.read<GroupProvider>().setGroups(updated);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${member.name} removed.'), backgroundColor: Colors.red[700]),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, BuyingGroup group) {
    // Buyers not already in the group
    final allBuyers = [
      {'id': 'u2', 'name': 'Karim (Wholesaler)', 'phone': '01711111111'},
      {'id': 'u3', 'name': 'Rahim (Retailer)', 'phone': '01722222222'},
      {'id': 'u4', 'name': 'Salam (Distributor)', 'phone': '01733333333'},
      {'id': 'u5', 'name': 'Jalal (Buyer)', 'phone': '01744444444'},
    ];
    final existingIds = group.members.map((m) => m.userId).toSet();
    final available = allBuyers.where((b) => !existingIds.contains(b['id'])).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more buyers to add.')),
      );
      return;
    }

    String? selectedId;
    double qty = 0;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Add Participant', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Choose a buyer to invite to this group', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedId,
                  decoration: InputDecoration(
                    labelText: 'Select Buyer',
                    prefixIcon: const Icon(Icons.person_search_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: available.map((b) => DropdownMenuItem(value: b['id'], child: Text(b['name']!))).toList(),
                  validator: (v) => v == null ? 'Please select a buyer' : null,
                  onChanged: (v) => setSheet(() => selectedId = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity to Commit (KG)',
                    suffixText: 'KG',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final p = double.tryParse(v);
                    if (p == null || p <= 0) return 'Invalid';
                    final rem = group.targetQuantity - group.filledQuantity;
                    if (p > rem) return 'Max ${rem.toInt()} KG available';
                    return null;
                  },
                  onChanged: (v) => qty = double.tryParse(v) ?? 0,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add to Group'),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final buyer = available.firstWhere((b) => b['id'] == selectedId);
                        final newMember = GroupMember(
                          userId: buyer['id']!,
                          name: buyer['name']!,
                          contributionQuantity: qty,
                          phone: buyer['phone']!,
                        );
                        final joinMsg = GroupMessage(
                          id: 'msg_add_${DateTime.now().millisecondsSinceEpoch}',
                          groupId: group.id,
                          senderId: 'system',
                          senderName: 'System',
                          message: '${buyer['name']} was added to the group and committed ${qty.toInt()} KG! 👋',
                          createdAt: DateTime.now(),
                        );
                        final groups = context.read<GroupProvider>().groups;
                        final updated = groups.map((g) {
                          if (g.id == group.id) {
                            return g.copyWith(
                              members: [...g.members, newMember],
                              filledQuantity: g.filledQuantity + qty,
                              messages: [...g.messages, joinMsg],
                            );
                          }
                          return g;
                        }).toList();
                        context.read<GroupProvider>().setGroups(updated);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${buyer['name']} added to group!'),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatTab(BuyingGroup group, AppUser? user) {
    _scrollToBottom();
    return group.messages.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('No messages yet', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                const SizedBox(height: 6),
                Text('Start the conversation!', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ],
            ),
          )
        : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: group.messages.length,
            itemBuilder: (context, index) {
              final msg = group.messages[index];
              final isMe = msg.senderId == (user?.id ?? '');
              final isSystem = msg.senderId == 'system';

              if (isSystem) return _systemMessage(msg.message);

              return _chatBubble(
                message: msg.message,
                sender: msg.senderName,
                time: DateFormat('hh:mm a').format(msg.createdAt),
                isMe: isMe,
              );
            },
          );
  }

  Widget _chatBubble({required String message, required String sender, required String time, required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(sender, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF2E7D32) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(message, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(time, style: TextStyle(color: isMe ? Colors.white60 : Colors.grey[400], fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _systemMessage(String text) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.brown), textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildBottomBar(BuyingGroup group, AppUser? user, bool isMember) {
    final isChat = _tabController.index == 1;

    if (isChat) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(group, user),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _sendMessage(group, user),
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      );
    }

    if (isMember) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
            const SizedBox(width: 10),
            Text('You are a member of this group', style: GoogleFonts.outfit(color: const Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: group.status == GroupBuyStatus.open
              ? () => _showJoinDialog(context, group)
              : null,
          icon: const Icon(Icons.group_add),
          label: Text(
            group.status == GroupBuyStatus.open ? 'Join This Group' : 'Group Full / Closed',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(GroupBuyStatus status) {
    final (label, color) = switch (status) {
      GroupBuyStatus.open => ('OPEN', Colors.green[300]!),
      GroupBuyStatus.active => ('ACTIVE', Colors.blue[300]!),
      GroupBuyStatus.fulfilled => ('DONE', Colors.grey[300]!),
      GroupBuyStatus.cancelled => ('CANCELLED', Colors.red[300]!),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.25), borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
    );
  }

  Widget _statItem(String value, String label) => Column(
        children: [
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      );

  Widget _divider() => Container(width: 1, height: 28, color: Colors.grey[200]);
}
