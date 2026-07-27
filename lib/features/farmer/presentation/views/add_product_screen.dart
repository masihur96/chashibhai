import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/models.dart';
import 'package:google_fonts/google_fonts.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  String _productName = '';
  double _quantity = 0;
  double _minPrice = 0;
  TradeType _tradeType = TradeType.both;
  String _unit = 'KG';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List New Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePlaceholder(),
              const SizedBox(height: 24),
              Text(
                'Product Details',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'e.g., Fresh Red Tomatoes',
                  prefixIcon: Icon(Icons.shopping_basket_outlined),
                ),
                onChanged: (v) => _productName = v,
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        suffixText: _unit,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _quantity = double.tryParse(v) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownMenu<String>(
                    initialSelection: _unit,
                    width: 110,
                    onSelected: (String? value) {
                      if (value != null) {
                        setState(() => _unit = value);
                      }
                    },
                    dropdownMenuEntries: ['KG', 'Tons', 'Monds', 'Bag']
                        .map<DropdownMenuEntry<String>>((String value) {
                      return DropdownMenuEntry<String>(
                        value: value,
                        label: value,
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Trade Configuration',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SegmentedButton<TradeType>(
                segments: const [
                  ButtonSegment(value: TradeType.auction, label: Text('Auction'), icon: Icon(Icons.gavel)),
                  ButtonSegment(value: TradeType.negotiation, label: Text('Negotiation'), icon: Icon(Icons.handshake)),
                  ButtonSegment(value: TradeType.both, label: Text('Both'), icon: Icon(Icons.all_inclusive)),
                ],
                selected: {_tradeType},
                onSelectionChanged: (v) => setState(() => _tradeType = v.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: _tradeType == TradeType.auction ? 'Minimum Bid Price' : 'Asking Price',
                  prefixText: '৳ ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => _minPrice = double.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product listed successfully!')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Publish Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text('Upload Product Photos', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
