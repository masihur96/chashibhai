import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/state/auth_provider.dart';
import '../state/product_provider.dart';
import '../../../group/presentation/state/group_provider.dart';
import '../state/demand_provider.dart';
import '../../../wallet/presentation/state/order_provider.dart';
import '../../../account/presentation/state/app_state_provider.dart';
import '../../../../core/models/models.dart';
import '../../../group/presentation/views/groups_list_screen.dart';


class PostDemandScreen extends StatefulWidget {
  const PostDemandScreen({super.key});

  @override
  State<PostDemandScreen> createState() => _PostDemandScreenState();
}

class _PostDemandScreenState extends State<PostDemandScreen> {
  final _formKey = GlobalKey<FormState>();
  String _productName = '';
  double _quantity = 0;
  double _callingPrice = 0;
  String _location = '';
  List<String> _selectedBuyerIds = [];
  bool _isInit = false;
  late DateTime _expiryDate;
  TradeType _tradeType = TradeType.negotiation;

  // Group buying state
  bool _isGroupDemand = false;
  BuyingGroup? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _expiryDate = DateTime.now().add(const Duration(days: 3));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final myGroups = context.watch<GroupProvider>().getMyGroups(context.watch<AuthProvider>().currentUser?.id);
    final allGroups = context.watch<GroupProvider>().groups;
    final openGroups = allGroups.where((g) => g.status == GroupBuyStatus.open).toList();

    if (!_isInit) {
      _selectedBuyerIds = [user?.id ?? 'u1'];
      _isInit = true;
    }

    final List<Map<String, String>> buyers = [
      if (user != null)
        {'id': user.id, 'name': '${user.name} (You)'}
      else
        {'id': 'u1', 'name': 'Guest User'},
      {'id': 'u2', 'name': 'Karim (Wholesaler)'},
      {'id': 'u3', 'name': 'Rahim (Retailer)'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Post Buying Demand')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuidanceCard(),
              const SizedBox(height: 24),
              Text(
                'Demand Type',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildDemandTypeToggle(),
              const SizedBox(height: 20),

              // Conditional: Individual buyer selection or Group picker
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isGroupDemand
                    ? _buildGroupSelector(context, openGroups, myGroups)
                    : _buildBuyerSelector(context, buyers),
              ),

              const SizedBox(height: 20),
              Text(
                'Demand Specifications',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'What product do you need?',
                  hintText: 'e.g., Winter Potatoes',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => _productName = v,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Quantity Needed',
                        suffixText: 'KG',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _quantity = double.tryParse(v) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Calling Price',
                        prefixText: '৳ ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _callingPrice = double.tryParse(v) ?? 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Delivery Location',
                  hintText: 'e.g., Kawran Bazar, Dhaka',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                onChanged: (v) => _location = v,
              ),
              const SizedBox(height: 24),
              Text(
                'Trade Configuration',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TradeType>(
                value: _tradeType,
                decoration: const InputDecoration(
                  labelText: 'Trade Type',
                  prefixIcon: Icon(Icons.handshake_outlined),
                ),
                items: TradeType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _tradeType = val);
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image selection mocked for demo.')));
                },
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Upload Product Image (Optional)', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Timeline',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                leading: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                title: const Text('Demand Expiry'),
                subtitle: Text('Expires on ${DateFormat('MMM dd, yyyy').format(_expiryDate)}'),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (selectedDate != null) setState(() => _expiryDate = selectedDate);
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (_isGroupDemand && _selectedGroup == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a buying group first.'), backgroundColor: Colors.orange),
                        );
                        return;
                      }
                      final suffix = _isGroupDemand && _selectedGroup != null
                          ? ' via group "${_selectedGroup!.name}"'
                          : '';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Demand posted$suffix! Farmers will now see your request.'),
                          backgroundColor: const Color(0xFF2E7D32),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Publish Demand', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Note: Full amount will be locked in escrow once you accept a farmer\'s offer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemandTypeToggle() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: false,
            label: Text('Individual'),
            icon: Icon(Icons.person_outline),
          ),
          ButtonSegment(
            value: true,
            label: Text('Group Buy'),
            icon: Icon(Icons.groups_outlined),
          ),
        ],
        selected: {_isGroupDemand},
        onSelectionChanged: (Set<bool> newSelection) {
          setState(() => _isGroupDemand = newSelection.first);
        },
      ),
    );
  }

  // _toggleOption removed in favor of SegmentedButton

  Widget _buildBuyerSelector(BuildContext context, List<Map<String, String>> buyers) {
    return Column(
      key: const ValueKey('individual'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Co-Buyers (Optional)', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showMultiSelectDialog(context, buyers),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Select Buyers',
              prefixIcon: Icon(Icons.group_add_outlined),
            ),
            isEmpty: _selectedBuyerIds.isEmpty,
            child: _selectedBuyerIds.isEmpty
                ? const Text('Tap to select buyers...', style: TextStyle(color: Colors.grey, fontSize: 16))
                : Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _selectedBuyerIds.map((id) {
                      final b = buyers.firstWhere((b) => b['id'] == id, orElse: () => {'name': 'Unknown'});
                      return Chip(
                        label: Text(b['name']!, style: const TextStyle(fontSize: 12)),
                        backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _selectedBuyerIds.remove(id)),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupSelector(BuildContext context, List<BuyingGroup> openGroups, List<BuyingGroup> myGroups) {
    return Column(
      key: const ValueKey('group'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Buying Group', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        // Info chip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer, 
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Group buying lets multiple buyers pool orders for bulk price discounts from farmers.', 
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimaryContainer)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // Selected group display
        if (_selectedGroup != null)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.groups, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedGroup!.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      Text(
                        '${_selectedGroup!.members.length} members • ${_selectedGroup!.filledQuantity.toInt()}/${_selectedGroup!.targetQuantity.toInt()} KG filled',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedGroup = null),
                  child: const Icon(Icons.close, color: Colors.grey, size: 18),
                ),
              ],
            ),
          ),
        // Group picker button
        OutlinedButton.icon(
          onPressed: () => _showGroupPickerSheet(context, openGroups, myGroups),
          icon: Icon(Icons.group_add_outlined, color: Theme.of(context).colorScheme.primary),
          label: Text(_selectedGroup == null ? 'Choose or Create a Group' : 'Change Group'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  void _showGroupPickerSheet(BuildContext context, List<BuyingGroup> openGroups, List<BuyingGroup> myGroups) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text('Select a Group', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsListScreen()));
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Create New'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: openGroups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_off_outlined, size: 56, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('No open groups available', style: TextStyle(color: Colors.grey[500])),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsListScreen()));
                              },
                              child: const Text('Browse & Create Groups'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.all(16),
                        itemCount: openGroups.length,
                        itemBuilder: (context, index) {
                          final g = openGroups[index];
                          final isSelected = _selectedGroup?.id == g.id;
                          final progress = g.filledQuantity / g.targetQuantity;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedGroup = g);
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF2E7D32).withOpacity(0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[200]!,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.groups, color: isSelected ? const Color(0xFF2E7D32) : Colors.grey),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(g.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                                            Text('${g.productName} • ${g.members.length} members', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${g.filledQuantity.toInt()}/${g.targetQuantity.toInt()} KG', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('৳${g.pricePerKg}/KG', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12, color: const Color(0xFF2E7D32))),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress.clamp(0.0, 1.0),
                                      minHeight: 5,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMultiSelectDialog(BuildContext context, List<Map<String, String>> buyers) {
    List<String> tempSelected = List.from(_selectedBuyerIds);
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final filteredBuyers = buyers.where((b) => b['name']!.toLowerCase().contains(searchQuery.toLowerCase())).toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Buyers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search buyers...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                      onChanged: (val) => setModalState(() => searchQuery = val),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredBuyers.length,
                        itemBuilder: (context, index) {
                          final buyer = filteredBuyers[index];
                          final isSelected = tempSelected.contains(buyer['id']);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(buyer['name']!),
                            value: isSelected,
                            activeColor: const Color(0xFF2E7D32),
                            onChanged: (bool? value) {
                              setModalState(() {
                                if (value == true) {
                                  tempSelected.add(buyer['id']!);
                                } else {
                                  tempSelected.remove(buyer['id']);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedBuyerIds = tempSelected);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGuidanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Specify your price and quantity. Verified farmers will compete to fulfill your demand.',
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
