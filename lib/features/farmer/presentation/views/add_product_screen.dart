import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/models.dart';
import '../../../../core/presentation/widgets/product_image_view.dart';
import '../../../../core/utils/storage_service.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../buyer/presentation/state/product_provider.dart';
import '../../data/models/create_product_request_model.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _customCategoryController;

  String _unit = 'KG';
  TradeType _tradeType = TradeType.both;
  String _category = 'rice';
  bool _isCustomCategory = false;

  late DateTime _startTime;
  late DateTime _endTime;

  // Image states
  String _imageUrl = 'https://cdn.example.com/products/rice.jpg';
  Uint8List? _pickedImageBytes;
  String? _pickedFilePath;
  String? _imageBase64;
  String _imageSourceType = 'default'; // 'default', 'camera', 'gallery', 'network'

  bool _isSubmitting = false;

  final List<String> _categoryOptions = [
    'rice',
    'vegetables',
    'fruits',
    'grains',
    'spices',
    'custom',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populate with defaults matching the curl request
    _nameController = TextEditingController(text: 'Boro Rice');
    _quantityController = TextEditingController(text: '500');
    _priceController = TextEditingController(text: '45');
    _customCategoryController = TextEditingController();

    // Default start time: 2026-11-20 08:00 (or current date/time)
    final now = DateTime.now();
    _startTime = DateTime(now.year, now.month, now.day, 8, 0);
    _endTime = _startTime.add(const Duration(days: 5, hours: 12));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime current) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null || !mounted) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (pickedTime == null || !mounted) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  /// Picks an image from Camera or Gallery, compresses it, and encodes to Base64
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64String';

      setState(() {
        _pickedImageBytes = bytes;
        _pickedFilePath = file.path;
        _imageBase64 = dataUri;
        _imageUrl = file.path;
        _imageSourceType = source == ImageSource.camera ? 'camera' : 'gallery';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  source == ImageSource.camera ? Icons.camera_alt : Icons.photo_library,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  source == ImageSource.camera
                      ? 'Photo captured successfully!'
                      : 'Photo selected from gallery!',
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Opens the Bottom Sheet to choose between Camera, Gallery, or Custom URL
  void _showImageSourceSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Product Image',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2E7D32)),
                  ),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Capture photo with camera'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: Colors.blue),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select an image from device photos'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.link, color: Colors.orange),
                  ),
                  title: const Text('Enter Image URL / Presets', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Paste a web URL or choose demo presets'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showImagePickerDialog();
                  },
                ),
                if (_imageSourceType != 'default') ...[
                  const Divider(),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.restart_alt, color: Colors.red),
                    ),
                    title: const Text('Reset to Default', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Reset to original sample CDN image'),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _imageUrl = 'https://cdn.example.com/products/rice.jpg';
                        _pickedImageBytes = null;
                        _pickedFilePath = null;
                        _imageBase64 = null;
                        _imageSourceType = 'default';
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImagePickerDialog() {
    final urlController = TextEditingController(
      text: _imageUrl.startsWith('http') || _imageUrl.startsWith('assets') ? _imageUrl : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Product Photo URL',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quick Presets:',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.grain, size: 16),
                    label: const Text('Boro Rice (CDN)'),
                    onPressed: () {
                      urlController.text = 'https://cdn.example.com/products/rice.jpg';
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.rice_bowl, size: 16),
                    label: const Text('Rice Asset'),
                    onPressed: () {
                      urlController.text = 'assets/images/rice.png';
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.eco, size: 16),
                    label: const Text('Tomato'),
                    onPressed: () {
                      urlController.text = 'assets/images/tomato.png';
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.circle, size: 16),
                    label: const Text('Potato'),
                    onPressed: () {
                      urlController.text = 'assets/images/potato.png';
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.spa, size: 16),
                    label: const Text('Onion'),
                    onPressed: () {
                      urlController.text = 'assets/images/onion.png';
                    },
                  ),
                ],
              ),
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
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                setState(() {
                  _imageUrl = newUrl;
                  _pickedImageBytes = null;
                  _pickedFilePath = null;
                  _imageBase64 = null;
                  _imageSourceType = newUrl.startsWith('http') ? 'network' : 'preset';
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _getTradeTypeString(TradeType type) {
    switch (type) {
      case TradeType.auction:
        return 'auction';
      case TradeType.negotiation:
        return 'negotiation';
      case TradeType.both:
        return 'both';
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endTime.isBefore(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final finalCategory = _isCustomCategory
        ? _customCategoryController.text.trim().toLowerCase()
        : _category.trim().toLowerCase();

    // Prepare payload fields according to user curl
    // If a device image was picked, pass base64 or path to file/image/imageUrl
    final String effectiveImageUrl = _imageUrl.startsWith('http')
        ? _imageUrl
        : (_imageBase64 != null ? _imageBase64! : _imageUrl);

    final String effectiveFile = _imageBase64 != null
        ? _imageBase64!
        : (_pickedFilePath != null ? _pickedFilePath! : 'string');

    final String effectiveImage = _imageBase64 != null
        ? _imageBase64!
        : (_imageUrl.isNotEmpty ? _imageUrl : 'string');

    final request = CreateProductRequestModel(
      productName: _nameController.text.trim(),
      quantity: double.tryParse(_quantityController.text.trim()) ?? 0,
      unit: _unit,
      minimumPrice: double.tryParse(_priceController.text.trim()) ?? 0,
      tradeType: _getTradeTypeString(_tradeType),
      category: finalCategory.isNotEmpty ? finalCategory : 'rice',
      startTime: _startTime,
      endTime: _endTime,
      imageUrl: effectiveImageUrl,
      file: effectiveFile,
      image: effectiveImage,
    );

    final productProvider = context.read<ProductProvider>();
    final authProvider = context.read<AuthProvider>();

    try {
      // Fetch stored token if available
      String? token = authProvider.token;
      if (token == null || token.isEmpty) {
        token = await StorageService().getAccessToken();
      }

      final createdProduct = await productProvider.createProduct(
        request: request,
        token: token,
      );

      if (!mounted) return;

      // If local device image was picked, retain the local path/data for immediate UI display
      if (_pickedFilePath != null || _pickedImageBytes != null) {
        final localProduct = createdProduct.copyWith(
          imageUrl: _pickedFilePath ?? createdProduct.imageUrl,
        );
        // Replace with local copy in provider list so dashboard displays picked image
        final products = productProvider.products;
        final idx = products.indexWhere((p) => p.id == createdProduct.id);
        if (idx != -1) {
          products[idx] = localProduct;
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Product "${createdProduct.productName}" listed successfully!'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final rawError = e.toString().replaceAll('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rawError),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'List Offline',
            textColor: Colors.white,
            onPressed: () {
              final offlineProduct = Product(
                id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                farmerId: context.read<AuthProvider>().currentUser?.id ?? 'f1',
                productName: request.productName,
                imageUrl: _pickedFilePath ?? request.imageUrl,
                quantity: request.quantity,
                unit: request.unit,
                minimumPrice: request.minimumPrice,
                tradeType: _tradeType,
                startTime: request.startTime,
                endTime: request.endTime,
                category: request.category,
                status: 'active',
              );
              context.read<ProductProvider>().addProduct(offlineProduct);
              Navigator.pop(context, true);
            },
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'List New Product',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageHeader(),
              const SizedBox(height: 24),
              Text(
                'Product Details',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'e.g., Boro Rice',
                  prefixIcon: Icon(Icons.shopping_basket_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter product name' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: _categoryOptions.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(
                            cat == 'custom'
                                ? 'Custom...'
                                : '${cat[0].toUpperCase()}${cat.substring(1)}',
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _category = val;
                            _isCustomCategory = val == 'custom';
                          });
                        }
                      },
                    ),
                  ),
                  if (_isCustomCategory) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _customCategoryController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Category',
                          hintText: 'e.g., rice',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        validator: (v) {
                          if (_isCustomCategory && (v == null || v.trim().isEmpty)) {
                            return 'Enter category';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        suffixText: _unit,
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter quantity';
                        final num = double.tryParse(v);
                        if (num == null || num <= 0) return 'Invalid quantity';
                        return null;
                      },
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
                  ButtonSegment(
                    value: TradeType.auction,
                    label: Text('Auction'),
                    icon: Icon(Icons.gavel),
                  ),
                  ButtonSegment(
                    value: TradeType.negotiation,
                    label: Text('Negotiation'),
                    icon: Icon(Icons.handshake),
                  ),
                  ButtonSegment(
                    value: TradeType.both,
                    label: Text('Both'),
                    icon: Icon(Icons.all_inclusive),
                  ),
                ],
                selected: {_tradeType},
                onSelectionChanged: (v) => setState(() => _tradeType = v.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: _tradeType == TradeType.auction
                      ? 'Minimum Bid Price'
                      : 'Minimum Price / Asking Price',
                  prefixText: '৳ ',
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter price';
                  final num = double.tryParse(v);
                  if (num == null || num <= 0) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Schedule Listing',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.play_circle_outline, color: Color(0xFF2E7D32)),
                        title: const Text('Start Time'),
                        subtitle: Text(dateFormat.format(_startTime)),
                        trailing: const Icon(Icons.edit_calendar, size: 20),
                        onTap: () async {
                          final picked = await _pickDateTime(_startTime);
                          if (picked != null) {
                            setState(() => _startTime = picked);
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.stop_circle_outlined, color: Colors.orange),
                        title: const Text('End Time'),
                        subtitle: Text(dateFormat.format(_endTime)),
                        trailing: const Icon(Icons.edit_calendar, size: 20),
                        onTap: () async {
                          final picked = await _pickDateTime(_endTime);
                          if (picked != null) {
                            setState(() => _endTime = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitProduct,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Publish Listing',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    IconData sourceIcon;
    String sourceLabel;

    switch (_imageSourceType) {
      case 'camera':
        sourceIcon = Icons.camera_alt;
        sourceLabel = 'Captured from Camera';
        break;
      case 'gallery':
        sourceIcon = Icons.photo_library;
        sourceLabel = 'Selected from Gallery';
        break;
      case 'network':
        sourceIcon = Icons.cloud;
        sourceLabel = 'Custom Web URL';
        break;
      default:
        sourceIcon = Icons.image;
        sourceLabel = 'Default Sample Image';
    }

    return InkWell(
      onTap: _showImageSourceSelector,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 190,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _pickedImageBytes != null ? const Color(0xFF2E7D32) : Colors.grey.shade300,
            width: _pickedImageBytes != null ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProductImageView(
              imageUrl: _imageUrl,
              imageBytes: _pickedImageBytes,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
            // Top badge: source
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(sourceIcon, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      sourceLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom action row
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_a_photo, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _pickedImageBytes != null ? 'Product photo attached' : 'Upload Product Photo',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Tap to pick from gallery, camera, or URL',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _pickedImageBytes != null ? 'Change' : 'Pick Photo',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
