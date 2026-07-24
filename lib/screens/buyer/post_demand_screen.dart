import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/app_providers.dart';

class PostDemandScreen extends ConsumerStatefulWidget {
  const PostDemandScreen({super.key});

  @override
  ConsumerState<PostDemandScreen> createState() => _PostDemandScreenState();
}

class _PostDemandScreenState extends ConsumerState<PostDemandScreen> {
  final _formKey = GlobalKey<FormState>();
  String _productName = '';
  double _quantity = 0;
  double _callingPrice = 0;
  String _location = '';
  List<String> _selectedBuyerIds = [];
  bool _isInit = false;
  late DateTime _expiryDate;

  @override
  void initState() {
    super.initState();
    _expiryDate = DateTime.now().add(const Duration(days: 3));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    
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
                'Demand Specifications',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _showMultiSelectDialog(context, buyers),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Select Buyers',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.group_add_outlined),
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
                            onDeleted: () {
                              setState(() {
                                _selectedBuyerIds.remove(id);
                              });
                            },
                          );
                        }).toList(),
                      ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'What product do you need?',
                  hintText: 'e.g., Winter Potatoes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) => _productName = v,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Quantity Needed',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixText: 'KG',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _quantity = double.tryParse(v) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Calling Price',
                        prefixText: '৳ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _callingPrice = double.tryParse(v) ?? 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Delivery Location',
                  hintText: 'e.g., Kawran Bazar, Dhaka',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                onChanged: (v) => _location = v,
              ),
              const SizedBox(height: 24),
              Text(
                'Timeline',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF2E7D32),
                ),
                title: const Text('Demand Expiry'),
                subtitle: Text(
                  'Expires on ${DateFormat('MMM dd, yyyy').format(_expiryDate)}',
                ),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (selectedDate != null) {
                    setState(() {
                      _expiryDate = selectedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Demand posted! Farmers will now see your request.',
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Publish Demand',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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

  void _showMultiSelectDialog(BuildContext context, List<Map<String, String>> buyers) {
    List<String> tempSelected = List.from(_selectedBuyerIds);
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final filteredBuyers = buyers.where((b) => 
                b['name']!.toLowerCase().contains(searchQuery.toLowerCase())).toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          searchQuery = val;
                        });
                      },
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
                        setState(() {
                          _selectedBuyerIds = tempSelected;
                        });
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
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Specify your price and quantity. Verified farmers will compete to fulfill your demand.',
              style: TextStyle(fontSize: 13, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
